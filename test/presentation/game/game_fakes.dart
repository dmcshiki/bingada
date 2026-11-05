import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/services.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';

const me = AppUser(
  uid: UserId('u-player'),
  email: 'ana@suaempresa.com.br',
  displayName: 'Ana Souza',
);

const hostUid = UserId('u-host');

Game runningGame({int draws = 23, List<Winner> winners = const []}) {
  final t = CardTemplate.classic75();
  return Game(
    id: const GameId('g1'),
    roomCode: const RoomCode('K7QP'),
    hostUid: hostUid,
    eventName: 'Happy hour de sexta',
    status: GameStatus.running,
    access: const AccessPolicy.public(),
    template: t,
    prizes: const [
      Prize(
        id: PrizeId('p1'),
        label: 'Caneca',
        pattern: PatternKind.horizontal,
        order: 1,
      ),
      Prize(
        id: PrizeId('p2'),
        label: 'Vale-café',
        pattern: PatternKind.vertical,
        order: 2,
      ),
    ],
    salt: 'aa',
    drawCommit: 'bb',
    cardsHash: 'cc',
    playerCount: 42,
    draws: [for (final p in t.pool.take(draws)) p.id],
    winners: winners,
    createdAt: DateTime.utc(2026),
  );
}

class FakeAuth implements AuthRepository {
  FakeAuth(this.currentUser);

  @override
  AppUser? currentUser;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(currentUser);

  @override
  Future<AppUser> signInWithGoogle({String? hostedDomain}) async => me;

  @override
  Future<void> signOut() async {}
}

class FakeRepo implements GameRepository {
  FakeRepo(Game g) : game = g;

  Game game;
  final games = StreamController<Game>.broadcast();
  final claimsCtl = StreamController<List<Claim>>.broadcast();
  List<Claim> claims = [];
  final updated = <Claim>[];

  void emitClaims(List<Claim> c) {
    claims = c;
    claimsCtl.add(c);
  }

  @override
  Future<Game?> findByRoomCode(RoomCode code) async => game;

  @override
  Future<Game?> getGame(GameId id) async => game;

  @override
  Stream<Game> watchGame(GameId id) async* {
    yield game;
    yield* games.stream;
  }

  @override
  Stream<List<Player>> watchPlayers(GameId id) => Stream.value([
    Player(
      uid: me.uid,
      displayName: me.displayName,
      joinedAt: DateTime.utc(2026),
    ),
    Player(
      uid: hostUid,
      displayName: 'Daniel Moura',
      joinedAt: DateTime.utc(2026),
    ),
  ]);

  @override
  Stream<List<Claim>> watchClaims(GameId id) async* {
    yield claims;
    yield* claimsCtl.stream;
  }

  @override
  Future<BingoCard?> getCard(GameId id, UserId uid) async =>
      const CardGenerator().generate(
        uid: uid,
        gameId: id,
        salt: game.salt,
        template: game.template,
      );

  @override
  Future<List<BingoCard>> getCards(GameId id) async => [
    (await getCard(id, me.uid))!,
  ];

  @override
  Future<ClaimId> createClaim(GameId id, Claim claim) async {
    final c = claim.copyWith(id: ClaimId('c${claims.length + 1}'));
    emitClaims([...claims, c]);
    return c.id;
  }

  @override
  Future<void> updateClaim(GameId id, Claim claim) async => updated.add(claim);

  @override
  Future<void> appendDraw(GameId id, ItemId item) async {}

  @override
  Future<void> confirmPrize(GameId id, {required List<Winner> winners}) async {}

  @override
  Future<void> awardPrize(GameId id, {required List<Winner> winners}) async {}

  @override
  Future<void> setWinners(GameId id, List<Winner> winners) async {}

  @override
  Future<void> setRaffle(GameId id, Raffle? raffle) async {
    game = game.copyWith(raffle: raffle);
  }

  @override
  Future<void> chooseClaim(
    GameId id,
    ClaimId claimId,
    ClaimChoice? choice, {
    PrizeId? releasePrizeId,
  }) async {}

  @override
  Future<void> abandonIdle(GameId id) async {}

  @override
  Future<Game> createGame(Game draft) async => draft;

  @override
  Future<void> finish(
    GameId id, {
    required GameStatus status,
    required String drawSeed,
    required List<Winner> endOfGameWinners,
  }) async {}

  @override
  Future<void> join(
    GameId id, {
    required Player player,
    required String email,
    required BingoCard card,
  }) async {}

  @override
  Future<void> start(GameId id, {required String cardsHash}) async {}
}

class FakeMarks implements MarksStore {
  Set<int> saved = {};

  @override
  Future<Set<int>> load(GameId id, UserId uid) async => saved;

  @override
  Future<void> save(GameId id, UserId uid, Set<int> marked) async =>
      saved = marked;
}

class FakeSecrets implements HostSecretStore {
  @override
  Future<String?> loadDrawSeed(GameId id) async => 'seed';

  @override
  Future<void> saveDrawSeed(GameId id, String seedHex) async {}
}

class FakePresence implements PresenceRepository {
  FakePresence({this.online = true});

  final bool online;

  @override
  Future<void> announceHost(GameId id) async {}

  @override
  Stream<bool> watchHostOnline(GameId id) => Stream.value(online);
}

FakeRepo registerGameFakes({
  Game? game,
  AppUser? user = me,
  bool hostOnline = true,
}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  final repo = FakeRepo(game ?? runningGame());
  final secrets = FakeSecrets();
  const seq = DrawSequence();
  final end = EndGame(
    repo,
    secrets,
    seq,
    const UnderdogCalculator(),
    const TieBreaker(),
  );
  sl
    ..reset(dispose: false)
    ..registerSingleton<AuthRepository>(FakeAuth(user))
    ..registerSingleton<GameRepository>(repo)
    ..registerSingleton<MarksStore>(FakeMarks())
    ..registerSingleton<PresenceRepository>(FakePresence(online: hostOnline))
    ..registerSingleton<HostSecretStore>(secrets)
    ..registerFactory<CallBingo>(() => CallBingo(repo))
    ..registerFactory<DrawNext>(() => DrawNext(repo, secrets, seq))
    ..registerFactory<VerifyClaim>(
      () => VerifyClaim(repo, const BingoVerifier(), const CardGenerator()),
    )
    ..registerFactory<ResolveClaim>(() => ResolveClaim(repo))
    ..registerFactory<ResolveTie>(
      () => ResolveTie(secrets, seq, const TieBreaker()),
    )
    ..registerFactory<EndGame>(() => end)
    ..registerFactory<ConfirmPrize>(() => ConfirmPrize(repo, end));
  return repo;
}

Widget wrapGame(Widget page, {Size size = const Size(1440, 900)}) => MediaQuery(
  data: MediaQueryData(size: size, disableAnimations: true),
  child: MaterialApp(theme: AppTheme.light(), home: page),
);
