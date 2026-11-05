import 'dart:math';

import 'package:tokingo/core/crypto/hashing.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';

/// Commit-reveal draw sequence (§6).
final class DrawSequence {
  const DrawSequence();

  /// 32 random bytes (Random.secure) as hex.
  String newSecretHex() {
    final r = Random.secure();
    return toHex([for (var i = 0; i < 32; i++) r.nextInt(256)]);
  }

  /// sha256(seedHex) as hex.
  String commitOf(String drawSeedHex) => sha256Hex(drawSeedHex);

  /// sha256 of the cards ordered by uid: lines `uid:id,id,_,…` joined by `\n`.
  String cardsHash(List<BingoCard> cards) {
    final sorted = [...cards]
      ..sort((a, b) => a.owner.value.compareTo(b.owner.value));
    return sha256Hex(
      sorted
          .map(
            (c) =>
                '${c.owner.value}:${c.cells.map((e) => e?.value ?? '_').join(',')}',
          )
          .join('\n'),
    );
  }

  /// sha256(drawSeed | cardsHash) as hex. Never published during the game.
  String finalSeed({required String drawSeedHex, required String cardsHash}) =>
      sha256Hex('$drawSeedHex|$cardsHash');

  /// Full deterministic permutation of the template pool.
  List<ItemId> sequence({
    required String finalSeedHex,
    required CardTemplate template,
  }) {
    final ids = [for (final p in template.pool) p.id];
    final rng = Mulberry32(uint32FromHex(finalSeedHex));
    for (var i = 0; i < ids.length - 1; i++) {
      final j = i + rng.next() % (ids.length - i);
      final tmp = ids[i];
      ids[i] = ids[j];
      ids[j] = tmp;
    }
    return ids;
  }
}
