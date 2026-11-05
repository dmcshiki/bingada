import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/features/auth/domain/auth_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

const testUser = AppUser(
  uid: UserId('u-daniel'),
  email: 'daniel@suaempresa.com.br',
  displayName: 'Daniel Moura',
);

Game sampleGame({GameStatus status = GameStatus.lobby}) => Game(
  id: const GameId('g1'),
  roomCode: const RoomCode('K7QP'),
  hostUid: testUser.uid,
  eventName: 'Happy hour de sexta',
  status: status,
  access: const AccessPolicy.domain(domains: ['suaempresa.com.br']),
  template: CardTemplate.classic75(),
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
  endOfGamePrizes: const [
    Prize(
      id: PrizeId('u1'),
      label: 'Prêmio azarão',
      pattern: PatternKind.underdog,
    ),
  ],
  salt: 'aa',
  drawCommit: 'bb',
  playerCount: 37,
  createdAt: DateTime.utc(2026),
);

class FakeAuth implements AuthRepository {
  FakeAuth([this.user = testUser]);

  AppUser? user;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(user);

  @override
  Future<AppUser> signInWithGoogle({String? hostedDomain}) async =>
      user = testUser;

  @override
  Future<void> signOut() async => user = null;
}

class FakeGameRepository implements GameRepository {
  FakeGameRepository([this.game]);

  Game? game;
  final players = <Player>[
    Player(
      uid: testUser.uid,
      displayName: 'Daniel Moura',
      joinedAt: DateTime.utc(2026),
    ),
    Player(
      uid: const UserId('u2'),
      displayName: 'Ana Lima',
      joinedAt: DateTime.utc(2026, 1, 2),
    ),
  ];

  @override
  Future<Game?> findByRoomCode(RoomCode code) async =>
      game?.roomCode == code ? game : null;

  @override
  Stream<Game> watchGame(GameId id) =>
      game == null ? const Stream.empty() : Stream.value(game!);

  @override
  Stream<List<Player>> watchPlayers(GameId id) => Stream.value(players);

  @override
  Future<BingoCard?> getCard(GameId id, UserId uid) async => null;

  @override
  Future<void> abandonIdle(GameId id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void registerFakes({AuthRepository? auth, GameRepository? repo}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  sl
    ..reset(dispose: false)
    ..registerSingleton<AuthRepository>(auth ?? FakeAuth())
    ..registerSingleton<GameRepository>(
      repo ?? FakeGameRepository(sampleGame()),
    )
    ..registerSingleton<CardGenerator>(const CardGenerator());
}

Widget wrap(Widget page, {Size size = const Size(1440, 900)}) => MediaQuery(
  data: MediaQueryData(size: size),
  child: MaterialApp(theme: AppTheme.light(), home: page),
);
