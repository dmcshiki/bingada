import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';

void main() {
  const a = UserId('a'), b = UserId('b'), c = UserId('c');

  Winner w(String prize, UserId u) =>
      Winner(prizeId: PrizeId(prize), uid: u, drawIndex: 1);

  test('fewestPrizes with all tied on equal prizes: all contend', () {
    final winners = [w('p1', a), w('p2', b), w('p3', c)];
    expect(tieContenders([a, b, c], winners, TieBreakRule.fewestPrizes), [
      a,
      b,
      c,
    ]);
    expect(tieContenders([a, b, c], const [], TieBreakRule.fewestPrizes), [
      a,
      b,
      c,
    ]);
  });

  test('fewestPrizes vs draw with uneven prizes', () {
    final winners = [w('p1', a), w('p2', a), w('p3', b)];
    expect(tieContenders([a, b, c], winners, TieBreakRule.fewestPrizes), [c]);
    expect(tieContenders([a, b], winners, TieBreakRule.fewestPrizes), [b]);
    expect(tieContenders([a, b, c], winners, TieBreakRule.draw), [a, b, c]);
  });

  test('a single tied player is kept as is', () {
    expect(tieContenders([a], [w('p1', a)], TieBreakRule.fewestPrizes), [a]);
  });
}
