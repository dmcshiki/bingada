import 'package:tokingo/core/crypto/hashing.dart';
import 'package:tokingo/core/types/ids.dart';

/// R26: sha256(finalSeed | prizeId | sorted uids) mod N.
final class TieBreaker {
  const TieBreaker();

  UserId pick({
    required String finalSeedHex,
    required PrizeId prizeId,
    required List<UserId> tied,
  }) {
    if (tied.isEmpty) {
      throw ArgumentError.value(tied, 'tied', 'must not be empty');
    }
    final uids = [for (final u in tied) u.value]..sort();
    final h = sha256Bytes('$finalSeedHex|${prizeId.value}|${uids.join(',')}');
    return UserId(uids[uint32BE(h) % uids.length]);
  }
}
