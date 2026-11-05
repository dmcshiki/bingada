import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

import 'fixtures.dart';

void main() {
  const v = BingoVerifier();
  final alice = cardOf('alice');
  final row1 = [5, 6, 7, 8, 9];
  final col0 = [0, 5, 10, 15, 20];
  final row1Ids = idsAt(alice, row1);
  final col0Ids = idsAt(alice, col0);

  ClaimResult run(Game g, Claim c, {List<Claim> history = const []}) =>
      v.verify(
        game: g,
        claim: c,
        card: alice,
        expectedCard: alice,
        history: history,
      );

  test('valid horizontal', () {
    final g = makeGame(draws: row1Ids);
    final r = run(g, makeClaim(drawIndex: 5, marked: row1));
    expect(r.verdict, ClaimVerdict.valid);
    expect(r.matched, [
      const PatternMatch(kind: PatternKind.horizontal, index: 1),
    ]);
  });

  test('tampered card', () {
    final fake = alice.copyWith(
      cells: [...alice.cells]..[0] = const ItemId('0:99'),
    );
    final r = v.verify(
      game: makeGame(),
      claim: makeClaim(drawIndex: 0),
      card: fake,
      expectedCard: alice,
      history: const [],
    );
    expect(r.verdict, ClaimVerdict.tampered);
  });

  test(
    'comeu bola: ball drawn only after the claim index still counts as missed',
    () {
      final g = makeGame(draws: row1Ids);
      final r = run(g, makeClaim(drawIndex: 4, marked: row1));
      expect(r.verdict, ClaimVerdict.missed);
      expect(r.notDrawn, [row1Ids.last]);
      expect(r.reason, startsWith('Marcou O '));
      expect(r.reason, endsWith('que ainda não saiu'));
    },
  );

  test('no pattern → missed', () {
    final g = makeGame(draws: row1Ids);
    final r = run(g, makeClaim(drawIndex: 5, marked: row1.take(3).toList()));
    expect(r.verdict, ClaimVerdict.missed);
    expect(r.reason, 'Nenhum padrão completo');
  });

  test('wrong pattern: vertical while horizontal is on', () {
    final g = makeGame(draws: col0Ids);
    final r = run(g, makeClaim(drawIndex: 5, marked: col0));
    expect(r.verdict, ClaimVerdict.wrongPattern);
    expect(r.matched, contains(const PatternMatch(kind: PatternKind.vertical)));
  });

  test('wrong prize id → wrongPattern', () {
    final g = makeGame(draws: row1Ids);
    final r = run(
      g,
      makeClaim(drawIndex: 5, marked: row1, prizeId: const PrizeId('p2')),
    );
    expect(r.verdict, ClaimVerdict.wrongPattern);
  });

  test('free cell counts for column N', () {
    final colN = [2, 7, 12, 17, 22];
    final g = makeGame(draws: idsAt(alice, colN), currentPrizeIndex: 1);
    final r = run(
      g,
      makeClaim(
        drawIndex: 4,
        marked: [2, 7, 17, 22],
        prizeId: const PrizeId('p2'),
      ),
    );
    expect(r.verdict, ClaimVerdict.valid);
  });

  test('a winner may claim again (keep or swap is decided later)', () {
    final g = makeGame(
      draws: col0Ids,
      currentPrizeIndex: 1,
      winners: const [
        Winner(prizeId: PrizeId('p1'), uid: UserId('alice'), drawIndex: 3),
      ],
    );
    final r = run(
      g,
      makeClaim(drawIndex: 5, marked: col0, prizeId: const PrizeId('p2')),
    );
    expect(r.verdict, ClaimVerdict.valid);
  });

  group('penalty', () {
    final missed = makeClaim(
      id: 'c0',
      drawIndex: 3,
      verdict: ClaimVerdict.missed,
    );
    test('none never penalizes', () {
      final r = run(
        makeGame(draws: row1Ids),
        makeClaim(drawIndex: 5, marked: row1),
        history: [missed],
      );
      expect(r.verdict, ClaimVerdict.valid);
    });
    test('skipDraws blocks within window', () {
      final g = makeGame(
        draws: row1Ids,
        penalty: const ClaimPenaltyPolicy.skipDraws(draws: 3),
      );
      final r = run(
        g,
        makeClaim(drawIndex: 5, marked: row1),
        history: [missed],
      );
      expect(r.verdict, ClaimVerdict.penalized);
    });
    test('skipDraws evaluator', () {
      const e = PenaltyEvaluator();
      const p = ClaimPenaltyPolicy.skipDraws(draws: 3);
      final b = e.blockFor(
        uid: const UserId('alice'),
        policy: p,
        history: [missed],
        currentDrawIndex: 4,
      );
      expect(b?.drawsLeft, 2);
      expect(b?.reason, 'Bloqueado por comer bola');
      expect(
        e.blockFor(
          uid: const UserId('alice'),
          policy: p,
          history: [missed],
          currentDrawIndex: 6,
        ),
        isNull,
      );
      expect(
        e.blockFor(
          uid: const UserId('bob'),
          policy: p,
          history: [missed],
          currentDrawIndex: 4,
        ),
        isNull,
      );
      expect(
        e.blockFor(
          uid: const UserId('alice'),
          policy: const ClaimPenaltyPolicy.none(),
          history: [missed],
          currentDrawIndex: 4,
        ),
        isNull,
      );
    });
  });

  group('tiedValidClaims', () {
    test('two valid on same drawIndex tie', () {
      final t = v.tiedValidClaims([
        makeClaim(id: 'a', drawIndex: 10, verdict: ClaimVerdict.valid),
        makeClaim(
          id: 'b',
          uid: 'bob',
          drawIndex: 10,
          verdict: ClaimVerdict.valid,
          status: ClaimStatus.tied,
        ),
        makeClaim(
          id: 'c',
          uid: 'carol',
          drawIndex: 11,
          verdict: ClaimVerdict.valid,
        ),
        makeClaim(
          id: 'd',
          uid: 'dan',
          drawIndex: 9,
          verdict: ClaimVerdict.missed,
        ),
      ]);
      expect(t.map((c) => c.id.value), ['a', 'b']);
    });
    test('single earliest → no tie', () {
      expect(
        v.tiedValidClaims([
          makeClaim(id: 'a', drawIndex: 9, verdict: ClaimVerdict.valid),
          makeClaim(id: 'b', drawIndex: 10, verdict: ClaimVerdict.valid),
        ]),
        isEmpty,
      );
      expect(v.tiedValidClaims(const []), isEmpty);
    });
  });
}
