import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';

void main() {
  const a = UserId('a'), b = UserId('b'), c = UserId('c');
  final winners = [
    const Winner(prizeId: PrizeId('p1'), uid: a, drawIndex: 3),
  ];

  test('draw keeps everyone tied', () {
    expect(tieContenders([a, b, c], winners, TieBreakRule.draw), [a, b, c]);
  });

  test('fewestPrizes keeps only those with the fewest prizes', () {
    expect(
      tieContenders([a, b, c], winners, TieBreakRule.fewestPrizes),
      [b, c],
    );
    expect(tieContenders([a, b], winners, TieBreakRule.fewestPrizes), [b]);
  });
}
