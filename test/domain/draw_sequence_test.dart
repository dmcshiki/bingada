import 'package:flutter_test/flutter_test.dart';
import 'package:tokingo/core/crypto/hashing.dart';
import 'package:tokingo/features/game/domain/services/services.dart';

import 'fixtures.dart';

void main() {
  const ds = DrawSequence();
  test('newSecretHex is 64 hex chars and random', () {
    final a = ds.newSecretHex();
    expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(a, isNot(ds.newSecretHex()));
  });
  test('commitOf is sha256 of seed', () {
    expect(ds.commitOf(drawSeed), sha256Hex(drawSeed));
  });
  test('cardsHash is order independent', () {
    final cards = [cardOf('bob'), cardOf('alice')];
    expect(ds.cardsHash(cards), ds.cardsHash(cards.reversed.toList()));
    expect(ds.cardsHash(cards), isNot(ds.cardsHash([cardOf('alice')])));
  });
  test('sequence is a deterministic permutation of the pool', () {
    final fs = ds.finalSeed(
      drawSeedHex: drawSeed,
      cardsHash: ds.cardsHash([cardOf('alice')]),
    );
    final s = ds.sequence(finalSeedHex: fs, template: template);
    expect(s.length, 75);
    expect(s.toSet(), {for (final p in template.pool) p.id});
    expect(s, ds.sequence(finalSeedHex: fs, template: template));
    expect(s, isNot([for (final p in template.pool) p.id]));
  });
}
