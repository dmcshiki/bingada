import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/data/local/key_value_store.dart';
import 'package:tokingo/features/game/data/local/local_game_repository.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/services.dart';
import 'package:tokingo/features/game/domain/usecases/usecases.dart';

import 'fixtures.dart';

const _ana = UserId('ana');

Future<(LocalGameRepository, Game)> _room({bool start = true}) async {
  final repo = LocalGameRepository(KeyValueStore.memory());
  final g = await repo.createGame(makeGame());
  final card = const CardGenerator().generate(
    uid: _ana,
    gameId: g.id,
    salt: g.salt,
    template: g.template,
  );
  await repo.join(
    g.id,
    player: Player(uid: _ana, displayName: 'Ana', joinedAt: DateTime.utc(2026)),
    email: 'ana@example.com',
    card: card,
  );
  if (start) {
    await repo.start(g.id, cardsHash: const DrawSequence().cardsHash([card]));
  }
  return (repo, (await repo.getGame(g.id))!);
}

Future<Claim> _only(LocalGameRepository repo, GameId id) async =>
    (await repo.watchClaims(id).first).single;

void main() {
  test('drawIndex comes from the current game when the snapshot is one ball '
      'behind', () async {
    final (repo, g) = await _room();
    final pool = g.template.pool;
    await repo.appendDraw(g.id, pool[0].id);
    final stale = (await repo.getGame(g.id))!;
    await repo.appendDraw(g.id, pool[1].id);

    await CallBingo(repo)(stale, _ana, {});
    final c = await _only(repo, g.id);
    expect(stale.draws.length, 1);
    expect(c.drawIndex, 2);
  });

  test(
    'a prize closed after the snapshot is re-picked to the open one',
    () async {
      final (repo, g) = await _room();
      await repo.appendDraw(g.id, g.template.pool.first.id);
      final stale = (await repo.getGame(g.id))!;
      expect(CallBingo.prizeFor(stale, {}), p1.id);
      await repo.setWinners(g.id, [
        const Winner(prizeId: PrizeId('p1'), uid: UserId('bia'), drawIndex: 1),
      ]);

      await CallBingo(repo)(stale, _ana, {});
      expect((await _only(repo, g.id)).prizeId, p2.id);
    },
  );

  test('prizeFor callback overrides the prize given in the claim', () async {
    final (repo, g) = await _room();
    await repo.createClaim(
      g.id,
      Claim(
        id: const ClaimId(''),
        uid: _ana,
        prizeId: p1.id,
        drawIndex: 99,
        createdAt: DateTime.utc(2026),
      ),
      prizeFor: (_) => p2.id,
    );
    final c = await _only(repo, g.id);
    expect(c.prizeId, p2.id);
    expect(c.drawIndex, 0);
  });

  test('BINGO when the game is not running throws', () async {
    final (repo, g) = await _room(start: false);
    expect(g.status, isNot(GameStatus.running));
    expect(() => CallBingo(repo)(g, _ana, {}), throwsA(isA<GameFailure>()));
    // A stale snapshot that still says "running" is rejected by the repo.
    await expectLater(
      CallBingo(repo)(g.copyWith(status: GameStatus.running), _ana, {}),
      throwsA(isA<GameFailure>()),
    );
  });
}
