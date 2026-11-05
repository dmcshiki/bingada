import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

import 'fixtures.dart';

void main() {
  group('PrizePolicyEvaluator', () {
    const e = PrizePolicyEvaluator();
    const a = UserId('alice');
    const won = [Winner(prizeId: PrizeId('p1'), uid: a, drawIndex: 5)];
    test(
      'no wins → eligible',
      () => expect(
        e.isEligible(
          uid: a,
          target: p1,
          winners: const [],
          policy: const PrizePolicy(),
        ),
        isTrue,
      ),
    );
    test(
      'max reached → not eligible',
      () => expect(
        e.isEligible(
          uid: a,
          target: p2,
          winners: won,
          policy: const PrizePolicy(),
        ),
        isFalse,
      ),
    );
    test('matrix allows / denies', () {
      const pol = PrizePolicy(
        maxPerPlayer: 2,
        allow: {
          PrizeId('p1'): [PrizeId('p2')],
        },
      );
      expect(
        e.isEligible(uid: a, target: p2, winners: won, policy: pol),
        isTrue,
      );
      expect(
        e.isEligible(uid: a, target: p3, winners: won, policy: pol),
        isFalse,
      );
    });
    test('unlimited with no matrix key', () {
      expect(
        e.isEligible(
          uid: a,
          target: p3,
          winners: won,
          policy: const PrizePolicy(maxPerPlayer: null),
        ),
        isTrue,
      );
    });
  });

  group('TieBreaker', () {
    const t = TieBreaker();
    const uids = [UserId('carol'), UserId('alice'), UserId('bob')];
    test('deterministic and order independent', () {
      final w = t.pick(
        finalSeedHex: drawSeed,
        prizeId: const PrizeId('p1'),
        tied: uids,
      );
      expect(uids, contains(w));
      expect(
        t.pick(
          finalSeedHex: drawSeed,
          prizeId: const PrizeId('p1'),
          tied: uids.reversed.toList(),
        ),
        w,
      );
    });
    test('different seeds spread winners', () {
      final picks = {
        for (var i = 0; i < 30; i++)
          t.pick(finalSeedHex: '$i', prizeId: const PrizeId('p1'), tied: uids),
      };
      expect(picks.length, greaterThan(1));
    });
  });

  group('UnderdogCalculator (elimination)', () {
    const calc = UnderdogCalculator();
    final cards = [
      const BingoCard(
        owner: UserId('a'),
        cells: [ItemId('0:1'), null, ItemId('0:2')],
      ),
      const BingoCard(
        owner: UserId('b'),
        cells: [ItemId('0:3'), null, ItemId('0:4')],
      ),
      const BingoCard(
        owner: UserId('c'),
        cells: [ItemId('0:5'), null, ItemId('0:6')],
      ),
    ];
    UnderdogOutcome run(
      List<ItemId> draws, {
      List<Winner> winners = const [],
      bool over = false,
    }) => calc.run(
      cards: cards,
      draws: draws,
      underdogPrize: u1,
      winners: winners,
      policy: const PrizePolicy(),
      freeCellIndex: 1,
      gameOver: over,
    );

    test('undecided while 2+ remain', () {
      final r = run(const [ItemId('0:1')]);
      expect(r.decided, isFalse);
      expect(r.alive, 2);
    });
    test('last one standing wins at that ball, marked or not', () {
      final r = run(const [
        ItemId('0:1'),
        ItemId('0:9'),
        ItemId('0:3'),
        ItemId('0:5'),
      ]);
      expect(r.decided, isTrue);
      expect(r.survivors.map((u) => u.value), ['c']);
      expect(r.decidedAt, 3);
    });
    test('balls after the decision do not change it', () {
      final r = run(const [
        ItemId('0:1'),
        ItemId('0:3'),
        ItemId('0:5'),
        ItemId('0:6'),
      ]);
      expect(r.survivors.map((u) => u.value), ['c']);
      expect(r.decidedAt, 2);
    });
    test('last players out on the same ball tie', () {
      const cards2 = [
        BingoCard(
          owner: UserId('a'),
          cells: [ItemId('0:1'), null, ItemId('0:2')],
        ),
        BingoCard(
          owner: UserId('b'),
          cells: [ItemId('0:1'), null, ItemId('0:4')],
        ),
      ];
      final r = calc.run(
        cards: cards2,
        draws: const [ItemId('0:1')],
        underdogPrize: u1,
        winners: const [],
        policy: const PrizePolicy(),
        freeCellIndex: 1,
      );
      expect(r.decided, isTrue);
      expect(r.tied, isTrue);
      expect(r.survivors.map((u) => u.value), ['a', 'b']);
    });
    test('game over with several standing: they tie', () {
      final r = run(const [ItemId('0:9')], over: true);
      expect(r.survivors.length, 3);
      expect(r.tied, isTrue);
    });
    test('no draws and not over: undecided (no free win)', () {
      expect(run(const []).decided, isFalse);
    });
    test('policy: a prize winner leaves the race from that ball', () {
      final r = run(
        const [ItemId('0:1'), ItemId('0:9')],
        winners: const [
          Winner(prizeId: PrizeId('p1'), uid: UserId('b'), drawIndex: 2),
        ],
      );
      expect(r.survivors.map((u) => u.value), ['c']);
      expect(r.decidedAt, 2);
    });
    test('empty', () {
      expect(
        calc
            .run(
              cards: const [],
              draws: const [ItemId('0:1')],
              underdogPrize: u1,
              winners: const [],
              policy: const PrizePolicy(),
              freeCellIndex: 1,
            )
            .decided,
        isFalse,
      );
    });
  });
}
