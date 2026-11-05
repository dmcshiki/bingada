import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/data/access_checker.dart';
import 'package:tokingo/features/game/data/dto/game_mapper.dart';
import 'package:tokingo/features/game/data/local/key_value_store.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';

/// DEMO MODE [GameRepository]: whole state in a [KeyValueStore]
/// (localStorage on web, so host / streamer / players can live in separate
/// tabs). Enforces in code the same invariants as `firestore.rules`.
///
/// `currentUid` (optional) enables the host-only checks.
final class LocalGameRepository implements GameRepository {
  LocalGameRepository(
    this._kv, {
    UserId? Function()? currentUid,
    Random? random,
    DateTime Function()? clock,
    // The field is private and nullable-callable; keep the named param.
    // ignore: prefer_initializing_formals
  }) : _currentUid = currentUid,
       _random = random ?? Random(),
       _clock = clock ?? DateTime.now;

  final KeyValueStore _kv;
  final UserId? Function()? _currentUid;
  final Random _random;
  final DateTime Function() _clock;
  static const _map = GameMapper();
  static const _p = 'tokingo.demo';

  // ------------------------------------------------------------ storage

  String _roomKey(RoomCode c) => '$_p.room.${c.value}';
  String _gameKey(GameId id) => '$_p.game.${id.value}';
  String _playersKey(GameId id) => '$_p.players.${id.value}';
  String _cardsKey(GameId id) => '$_p.cards.${id.value}';
  String _claimsKey(GameId id) => '$_p.claims.${id.value}';

  Json? _readJson(String key) {
    final raw = _kv.read(key);
    return raw == null
        ? null
        : (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  void _writeJson(String key, Json value) => _kv.write(key, jsonEncode(value));

  Game? _readGame(GameId id) {
    final m = _readJson(_gameKey(id));
    return m == null ? null : _map.gameFromMap(id.value, m);
  }

  Game _requireGame(GameId id) =>
      _readGame(id) ?? (throw const GameFailure(GameFailureCode.roomNotFound));

  void _writeGame(Game g) => _writeJson(_gameKey(g.id), _map.gameToMap(g));

  /// Collections are stored as `{docId: doc}`.
  Map<String, Json> _readColl(String key) => {
    for (final MapEntry(:key, :value) in (_readJson(key) ?? {}).entries)
      key: (value! as Map).cast<String, Object?>(),
  };

  void _requireHost(Game g) {
    final uid = _currentUid?.call();
    if (_currentUid != null && uid != g.hostUid) {
      throw const GameFailure(GameFailureCode.notHost);
    }
  }

  Stream<T> _watch<T>(String key, T? Function() read) {
    late StreamController<T> ctl;
    StreamSubscription<String>? sub;
    ctl = StreamController<T>(
      onListen: () {
        final first = read();
        if (first != null) ctl.add(first);
        sub = _kv.changes.where((k) => k == key).listen((_) {
          final v = read();
          if (v != null) ctl.add(v);
        });
      },
      onCancel: () => sub?.cancel(),
    );
    return ctl.stream;
  }

  String _newId() =>
      [for (var i = 0; i < 20; i++) _random.nextInt(36).toRadixString(36)]
          .join();

  // --------------------------------------------------------------- games

  @override
  Future<Game> createGame(Game draft) async {
    for (var attempt = 0; attempt < 64; attempt++) {
      final code = RoomCode(
        String.fromCharCodes([
          for (var i = 0; i < 4; i++)
            kRoomCodeAlphabet.codeUnitAt(
              _random.nextInt(kRoomCodeAlphabet.length),
            ),
        ]),
      );
      final existing = _kv.read(_roomKey(code));
      if (existing != null) {
        final g = _readGame(GameId(existing));
        if (g != null &&
            (g.status == GameStatus.lobby || g.status == GameStatus.running)) {
          continue;
        }
      }
      final game = draft.copyWith(
        id: GameId(_newId()),
        roomCode: code,
        status: GameStatus.lobby,
        playerCount: 0,
        currentPrizeIndex: 0,
        draws: const [],
        winners: const [],
        drawSeed: null,
      );
      _writeGame(game);
      _kv.write(_roomKey(code), game.id.value);
      return game;
    }
    throw const GameFailure(GameFailureCode.conflict, 'no free room code');
  }

  @override
  Future<Game?> findByRoomCode(RoomCode code) async {
    final id = _kv.read(_roomKey(code));
    return id == null ? null : _readGame(GameId(id));
  }

  @override
  Future<Game?> getGame(GameId id) async => _readGame(id);

  @override
  Stream<Game> watchGame(GameId id) =>
      _watch(_gameKey(id), () => _readGame(id));

  // ------------------------------------------------------- players/cards

  List<Player> _players(GameId id) {
    final list = [
      for (final MapEntry(:key, :value) in _readColl(_playersKey(id)).entries)
        _map.playerFromMap(key, value),
    ]..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return list;
  }

  @override
  Stream<List<Player>> watchPlayers(GameId id) =>
      _watch(_playersKey(id), () => _players(id));

  @override
  Future<BingoCard?> getCard(GameId id, UserId uid) async {
    final m = _readColl(_cardsKey(id))[uid.value];
    return m == null ? null : _map.cardFromMap(uid.value, m);
  }

  @override
  Future<List<BingoCard>> getCards(GameId id) async => [
    for (final MapEntry(:key, :value) in _readColl(_cardsKey(id)).entries)
      _map.cardFromMap(key, value),
  ];

  @override
  Future<void> join(
    GameId id, {
    required Player player,
    required String email,
    required BingoCard card,
  }) async {
    final cards = _readColl(_cardsKey(id));
    if (cards.containsKey(player.uid.value)) return;
    final game = _requireGame(id);
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
    final size = game.template.rows * game.template.cols;
    if (card.cells.length != size || card.owner != player.uid) {
      throw const GameFailure(GameFailureCode.accessDenied, 'invalid card');
    }
    cards[player.uid.value] = _map.cardToMap(card, player: player);
    final players = _readColl(_playersKey(id))
      ..[player.uid.value] = _map.playerToMap(player);
    _writeJson(_cardsKey(id), cards);
    _writeJson(_playersKey(id), players);
    _writeGame(game.copyWith(playerCount: game.playerCount + 1));
  }

  // ---------------------------------------------------------------- play

  @override
  Future<void> start(GameId id, {required String cardsHash}) async {
    final game = _requireGame(id);
    _requireHost(game);
    if (game.status != GameStatus.lobby) {
      throw const GameFailure(GameFailureCode.alreadyStarted);
    }
    _writeGame(
      game.copyWith(
        status: GameStatus.running,
        cardsHash: cardsHash,
        startedAt: _clock().toUtc(),
      ),
    );
  }

  @override
  Future<void> appendDraw(GameId id, ItemId item) async {
    final game = _requireGame(id);
    _requireHost(game);
    if (game.status != GameStatus.running) {
      throw const GameFailure(GameFailureCode.finished);
    }
    if (game.draws.contains(item)) {
      throw const GameFailure(GameFailureCode.conflict, 'already drawn');
    }
    final pending = _claims(id).any(
      (c) =>
          c.drawIndex == game.draws.length && c.status == ClaimStatus.pending,
    );
    if (pending) throw const GameFailure(GameFailureCode.pendingClaims);
    _writeGame(game.copyWith(draws: [...game.draws, item]));
  }

  List<Claim> _claims(GameId id) => [
    for (final MapEntry(:key, :value) in _readColl(_claimsKey(id)).entries)
      _map.claimFromMap(key, value),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<ClaimId> createClaim(GameId id, Claim claim) async {
    final game = _requireGame(id);
    final uid = _currentUid?.call();
    if (_currentUid != null && uid != claim.uid) {
      throw const GameFailure(GameFailureCode.accessDenied);
    }
    if (game.status != GameStatus.running) {
      throw const GameFailure(GameFailureCode.finished);
    }
    if (claim.drawIndex != game.draws.length ||
        !game.openPrizes.any((p) => p.id == claim.prizeId)) {
      throw const GameFailure(GameFailureCode.conflict, 'stale claim');
    }
    final cid = ClaimId(_newId());
    final claims = _readColl(_claimsKey(id))
      ..[cid.value] = _map.claimToMap(
        claim.copyWith(id: cid, status: ClaimStatus.pending),
      );
    _writeJson(_claimsKey(id), claims);
    return cid;
  }

  @override
  Stream<List<Claim>> watchClaims(GameId id) =>
      _watch(_claimsKey(id), () => _claims(id));

  @override
  Future<void> updateClaim(GameId id, Claim claim) async {
    _requireHost(_requireGame(id));
    final claims = _readColl(_claimsKey(id));
    final old = claims[claim.id.value];
    if (old == null) throw const GameFailure(GameFailureCode.conflict);
    final next = _map.claimToMap(claim);
    claims[claim.id.value] = {
      ...old,
      'status': next['status'],
      'verdict': next['verdict'],
      'matched': next['matched'],
      'offerPrizeId': next['offerPrizeId'],
    };
    _writeJson(_claimsKey(id), claims);
  }

  @override
  Future<void> setWinners(GameId id, List<Winner> winners) async {
    final game = _requireGame(id);
    _requireHost(game);
    _writeGame(game.copyWith(winners: winners));
  }

  @override
  Future<void> chooseClaim(
    GameId id,
    ClaimId claimId,
    ClaimChoice choice,
  ) async {
    final claims = _readColl(_claimsKey(id));
    final old = claims[claimId.value];
    if (old == null) throw const GameFailure(GameFailureCode.conflict);
    final uid = _currentUid?.call();
    if (uid != null && old['uid'] != uid.value) {
      throw const GameFailure(GameFailureCode.accessDenied);
    }
    if (old['status'] != ClaimStatus.awaitingChoice.name) {
      throw const GameFailure(GameFailureCode.conflict);
    }
    claims[claimId.value] = {...old, 'choice': choice.name};
    _writeJson(_claimsKey(id), claims);
  }

  @override
  Future<void> confirmPrize(GameId id, {required List<Winner> winners}) async {
    final game = _requireGame(id);
    _requireHost(game);
    _writeGame(
      game.copyWith(
        winners: [...game.winners, ...winners],
        currentPrizeIndex: game.currentPrizeIndex + 1,
      ),
    );
  }

  @override
  Future<void> awardPrize(GameId id, {required List<Winner> winners}) async {
    if (winners.isEmpty) return;
    final game = _requireGame(id);
    _requireHost(game);
    final prizeIds = {for (final w in winners) w.prizeId};
    if (game.winners.any((w) => prizeIds.contains(w.prizeId))) return;
    _writeGame(game.copyWith(winners: [...game.winners, ...winners]));
  }

  @override
  Future<void> finish(
    GameId id, {
    required GameStatus status,
    required String drawSeed,
    required List<Winner> endOfGameWinners,
  }) async {
    if (status != GameStatus.finished && status != GameStatus.abandoned) {
      throw ArgumentError.value(status, 'status');
    }
    final game = _requireGame(id);
    _requireHost(game);
    if (game.status != GameStatus.running) {
      throw const GameFailure(GameFailureCode.finished);
    }
    _writeGame(
      game.copyWith(
        status: status,
        drawSeed: drawSeed,
        endedAt: _clock().toUtc(),
        winners: [...game.winners, ...endOfGameWinners],
      ),
    );
  }
}

/// DEMO presence: host is always online.
final class DemoPresenceRepository implements PresenceRepository {
  const DemoPresenceRepository();

  @override
  Future<void> announceHost(GameId id) async {}

  @override
  Stream<bool> watchHostOnline(GameId id) => Stream.value(true);
}
