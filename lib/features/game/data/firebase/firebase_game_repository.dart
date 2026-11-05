import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/data/access_checker.dart';
import 'package:tokingo/features/game/data/dto/game_mapper.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';

/// Stores dates as Firestore [Timestamp]s.
final class TimestampDateCodec implements DateCodec {
  const TimestampDateCodec();

  @override
  Object encode(DateTime value) => Timestamp.fromDate(value);

  @override
  DateTime decode(Object value) => switch (value) {
    final Timestamp t => t.toDate().toUtc(),
    _ => const MillisDateCodec().decode(value),
  };
}

/// Firestore implementation of [GameRepository] (layout §7).
final class FirebaseGameRepository implements GameRepository {
  FirebaseGameRepository(this._db, {Random? random})
    : _random = random ?? Random.secure();

  final FirebaseFirestore _db;
  final Random _random;
  static const _map = GameMapper(TimestampDateCodec());

  CollectionReference<Map<String, dynamic>> get _games =>
      _db.collection('games');
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');
  DocumentReference<Map<String, dynamic>> _game(GameId id) =>
      _games.doc(id.value);

  String _code() => String.fromCharCodes([
    for (var i = 0; i < 4; i++)
      kRoomCodeAlphabet.codeUnitAt(_random.nextInt(kRoomCodeAlphabet.length)),
  ]);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on GameFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw GameFailure(switch (e.code) {
        'permission-denied' => GameFailureCode.accessDenied,
        'not-found' => GameFailureCode.roomNotFound,
        'aborted' || 'failed-precondition' => GameFailureCode.conflict,
        _ => GameFailureCode.unknown,
      }, e.message ?? e.code);
    }
  }

  Game _snap(DocumentSnapshot<Map<String, dynamic>> s) {
    final data = s.data();
    if (data == null) throw const GameFailure(GameFailureCode.roomNotFound);
    return _map.gameFromMap(s.id, data);
  }

  @override
  Future<Game> createGame(Game draft) => _guard(() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = RoomCode(_code());
      final gameRef = _games.doc();
      final game = draft.copyWith(
        id: GameId(gameRef.id),
        roomCode: code,
        status: GameStatus.lobby,
        playerCount: 0,
        currentPrizeIndex: 0,
        draws: const [],
        winners: const [],
        drawSeed: null,
      );
      final created = await _db.runTransaction<bool>((tx) async {
        final roomRef = _rooms.doc(code.value);
        final room = await tx.get(roomRef);
        if (room.exists) {
          final current = room.data()?['currentGameId'] as String?;
          if (current != null) {
            final g = await tx.get(_games.doc(current));
            final status = g.data()?['status'];
            if (status == 'lobby' || status == 'running') return false;
          }
        }
        tx
          ..set(roomRef, {
            'hostUid': game.hostUid.value,
            'currentGameId': game.id.value,
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..set(gameRef, _map.gameToMap(game));
        return true;
      });
      if (created) return game;
    }
    throw const GameFailure(GameFailureCode.conflict, 'no free room code');
  });

  @override
  Future<Game?> findByRoomCode(RoomCode code) => _guard(() async {
    final room = await _rooms.doc(code.value).get();
    final id = room.data()?['currentGameId'] as String?;
    return id == null ? null : await getGame(GameId(id));
  });

  @override
  Future<Game?> getGame(GameId id) => _guard(() async {
    final s = await _game(id).get();
    return s.exists ? _snap(s) : null;
  });

  @override
  Stream<Game> watchGame(GameId id) =>
      _game(id).snapshots().where((s) => s.exists).map(_snap);

  @override
  Stream<List<Player>> watchPlayers(GameId id) => _game(id)
      .collection('players')
      .orderBy('joinedAt')
      .snapshots()
      .map((q) => [for (final d in q.docs) _map.playerFromMap(d.id, d.data())]);

  @override
  Future<BingoCard?> getCard(GameId id, UserId uid) => _guard(() async {
    final s = await _game(id).collection('cards').doc(uid.value).get();
    final data = s.data();
    return data == null ? null : _map.cardFromMap(s.id, data);
  });

  @override
  Future<List<BingoCard>> getCards(GameId id) => _guard(() async {
    final q = await _game(id).collection('cards').get();
    return [for (final d in q.docs) _map.cardFromMap(d.id, d.data())];
  });

  @override
  Future<void> join(
    GameId id, {
    required Player player,
    required String email,
    required BingoCard card,
  }) => _guard(() async {
    final gameRef = _game(id);
    final cardRef = gameRef.collection('cards').doc(player.uid.value);
    final playerRef = gameRef.collection('players').doc(player.uid.value);
    await _db.runTransaction<void>((tx) async {
      final existing = await tx.get(cardRef);
      if (existing.exists) return;
      final game = _snap(await tx.get(gameRef));
      switch (game.status) {
        case GameStatus.lobby:
          break;
        case GameStatus.running:
          throw const GameFailure(GameFailureCode.alreadyStarted);
        case GameStatus.finished || GameStatus.abandoned:
          throw const GameFailure(GameFailureCode.finished);
      }
      if (player.uid != game.hostUid && !accessAllows(game.access, email)) {
        throw const GameFailure(GameFailureCode.accessDenied);
      }
      if (game.playerCount >= game.maxPlayers) {
        throw const GameFailure(GameFailureCode.roomFull);
      }
      tx
        ..set(playerRef, _map.playerToMap(player))
        ..set(cardRef, _map.cardToMap(card, player: player))
        ..update(gameRef, {'playerCount': FieldValue.increment(1)});
    });
  });

  @override
  Future<void> start(GameId id, {required String cardsHash}) =>
      _guard(() async {
        await _db.runTransaction<void>((tx) async {
          final game = _snap(await tx.get(_game(id)));
          if (game.status != GameStatus.lobby) {
            throw const GameFailure(GameFailureCode.alreadyStarted);
          }
          tx.update(_game(id), {
            'status': GameStatus.running.name,
            'cardsHash': cardsHash,
            'startedAt': FieldValue.serverTimestamp(),
            'lastActivityAt': FieldValue.serverTimestamp(),
          });
        });
      });

  @override
  Future<void> appendDraw(GameId id, ItemId item) => _guard(() async {
    // Client SDK transactions cannot run queries: check pending claims for
    // the current index first, then make the append conditional on `draws`
    // not having moved in the meantime.
    final before = await getGame(id);
    if (before == null) throw const GameFailure(GameFailureCode.roomNotFound);
    await _ensureNoPending(id, before.draws.length);
    await _db.runTransaction<void>((tx) async {
      final game = _snap(await tx.get(_game(id)));
      if (game.status != GameStatus.running) {
        throw const GameFailure(GameFailureCode.finished);
      }
      if (game.raffle case final r? when r.winner == null) {
        throw const GameFailure(
          GameFailureCode.pendingClaims,
          'Faça o sorteio pendente antes da próxima bola.',
        );
      }
      if (game.draws.length != before.draws.length) {
        throw const GameFailure(GameFailureCode.conflict);
      }
      tx.update(_game(id), {
        'draws': [for (final d in game.draws) d.value, item.value],
        'raffle': null,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
    });
  });

  Future<void> _ensureNoPending(GameId id, int drawIndex) async {
    final pending = await _game(id)
        .collection('claims')
        .where('drawIndex', isEqualTo: drawIndex)
        .where('status', isEqualTo: ClaimStatus.pending.name)
        .limit(1)
        .get();
    if (pending.docs.isNotEmpty) {
      throw const GameFailure(GameFailureCode.pendingClaims);
    }
  }

  @override
  Future<ClaimId> createClaim(GameId id, Claim claim) => _guard(() async {
    final ref = _game(id).collection('claims').doc();
    await ref.set(
      _map.claimToMap(
        claim.copyWith(id: ClaimId(ref.id), status: ClaimStatus.pending),
      ),
    );
    // Best effort: rules let any player bump only this field.
    try {
      await _game(id).update({'lastActivityAt': FieldValue.serverTimestamp()});
    } on Object {
      // The claim itself is what matters.
    }
    return ClaimId(ref.id);
  });

  @override
  Stream<List<Claim>> watchClaims(GameId id) => _game(id)
      .collection('claims')
      .orderBy('createdAt')
      .snapshots()
      .map((q) => [for (final d in q.docs) _map.claimFromMap(d.id, d.data())]);

  @override
  Future<void> updateClaim(GameId id, Claim claim) => _guard(() async {
    await _game(id).collection('claims').doc(claim.id.value).update({
      'status': claim.status.name,
      'verdict': claim.verdict?.name,
      'matched': _map.claimToMap(claim)['matched'],
      'offerPrizeId': claim.offerPrizeId?.value,
      'choice': claim.choice?.name,
      'releasePrizeId': claim.releasePrizeId?.value,
      'tieOptIn': claim.tieOptIn,
    });
    await _game(id).update({'lastActivityAt': FieldValue.serverTimestamp()});
  });

  @override
  Future<void> setWinners(GameId id, List<Winner> winners) => _guard(
    () => _game(id).update({
      'winners': [for (final w in winners) _map.winnerToMap(w)],
      'lastActivityAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> setRaffle(GameId id, Raffle? raffle) => _guard(
    () => _game(id).update({
      'raffle': raffle == null ? null : _map.raffleToMap(raffle),
      'lastActivityAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> chooseClaim(
    GameId id,
    ClaimId claimId,
    ClaimChoice? choice, {
    PrizeId? releasePrizeId,
  }) => _guard(
    () => _game(id).collection('claims').doc(claimId.value).update({
      'choice': ?choice?.name,
      'releasePrizeId': ?releasePrizeId?.value,
    }),
  );

  @override
  Future<void> abandonIdle(GameId id) => _guard(
    () => _game(id).update({
      'status': GameStatus.abandoned.name,
      'endedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> confirmPrize(GameId id, {required List<Winner> winners}) =>
      _guard(() async {
        await _db.runTransaction<void>((tx) async {
          final game = _snap(await tx.get(_game(id)));
          tx.update(_game(id), {
            'winners': [
              for (final w in [...game.winners, ...winners])
                _map.winnerToMap(w),
            ],
            'currentPrizeIndex': game.currentPrizeIndex + 1,
            'lastActivityAt': FieldValue.serverTimestamp(),
          });
        });
      });

  @override
  Future<void> awardPrize(GameId id, {required List<Winner> winners}) => _guard(
    () async {
      if (winners.isEmpty) return;
      await _db.runTransaction<void>((tx) async {
        final game = _snap(await tx.get(_game(id)));
        final prizeIds = {for (final w in winners) w.prizeId};
        if (game.winners.any((w) => prizeIds.contains(w.prizeId))) return;
        tx.update(_game(id), {
          'winners': [
            for (final w in [...game.winners, ...winners]) _map.winnerToMap(w),
          ],
          'lastActivityAt': FieldValue.serverTimestamp(),
        });
      });
    },
  );

  @override
  Future<void> finish(
    GameId id, {
    required GameStatus status,
    required String drawSeed,
    required List<Winner> endOfGameWinners,
  }) => _guard(() async {
    if (status != GameStatus.finished && status != GameStatus.abandoned) {
      throw ArgumentError.value(status, 'status');
    }
    await _db.runTransaction<void>((tx) async {
      final game = _snap(await tx.get(_game(id)));
      tx.update(_game(id), {
        'status': status.name,
        'drawSeed': drawSeed,
        'endedAt': FieldValue.serverTimestamp(),
        'winners': [
          for (final w in [...game.winners, ...endOfGameWinners])
            _map.winnerToMap(w),
        ],
      });
    });
  });
}
