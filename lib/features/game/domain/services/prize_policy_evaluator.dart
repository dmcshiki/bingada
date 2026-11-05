import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';

/// R30: may `uid` still compete for `target`?
///
/// Semantics:
/// 1. `wins` = number of `winners` entries for `uid`.
/// 2. If `maxPerPlayer != null` and `wins >= maxPerPlayer` → not eligible
///    (the global cap always wins over the matrix).
/// 3. Otherwise, for every prize the player already won, the matrix decides:
///    if `allow` has a key for that prize, `target` must be listed in it;
///    if it has no key, only the global cap applies (already satisfied in 2).
/// A player with no wins is always eligible.
final class PrizePolicyEvaluator {
  const PrizePolicyEvaluator();

  bool isEligible({
    required UserId uid,
    required Prize target,
    required List<Winner> winners,
    required PrizePolicy policy,
  }) {
    final won = [
      for (final w in winners)
        if (w.uid == uid) w.prizeId,
    ];
    final max = policy.maxPerPlayer;
    if (max != null && won.length >= max) return false;
    for (final p in won) {
      final allowed = policy.allow[p];
      if (allowed != null && !allowed.contains(target.id)) return false;
    }
    return true;
  }
}
