import 'package:tokingo/core/crypto/hashing.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/card_template.dart';

/// Deterministic card generation (§4): sha256(uid|gameId|salt) → mulberry32
/// → Fisher-Yates per column. Identical on VM and web.
final class CardGenerator {
  const CardGenerator();

  /// Hex sha256 of `uid|gameId|salt`.
  String seedHex({
    required UserId uid,
    required GameId gameId,
    required String salt,
  }) => sha256Hex('${uid.value}|${gameId.value}|$salt');

  BingoCard generate({
    required UserId uid,
    required GameId gameId,
    required String salt,
    required CardTemplate template,
  }) {
    final rng = Mulberry32(
      uint32FromHex(seedHex(uid: uid, gameId: gameId, salt: salt)),
    );
    final free = template.freeCellIndex;
    final freeCol = free == null ? -1 : free % template.cols;
    final cells = List<ItemId?>.filled(template.rows * template.cols, null);
    for (var c = 0; c < template.cols; c++) {
      final n = template.labelsOf(c).length;
      final idx = [for (var i = 0; i < n; i++) i];
      final need = c == freeCol ? template.rows - 1 : template.rows;
      for (var i = 0; i < need; i++) {
        final j = i + rng.next() % (n - i);
        final tmp = idx[i];
        idx[i] = idx[j];
        idx[j] = tmp;
      }
      var k = 0;
      for (var r = 0; r < template.rows; r++) {
        final cell = r * template.cols + c;
        if (cell == free) continue;
        cells[cell] = ItemId.of(c, idx[k++]);
      }
    }
    return BingoCard(owner: uid, cells: cells);
  }
}
