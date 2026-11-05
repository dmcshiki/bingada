import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';

/// R30: how many prizes, and which together, one player may hold.
///
/// A set of prizes is valid when:
/// 1. its size is at most `maxPerPlayer` (`null` = unlimited);
/// 2. for every prize X in it that has a key in `allow`, every other prize in
///    the set is listed in `allow[X]` ("who won X may compete for Y").
/// A prize with no key in `allow` only obeys the global cap.
final class PrizePolicyEvaluator {
  const PrizePolicyEvaluator();

  /// Whether one player may hold all of [prizes] together.
  bool canHold(Iterable<PrizeId> prizes, PrizePolicy policy) {
    final set = prizes.toSet();
    final max = policy.maxPerPlayer;
    if (max != null && set.length > max) return false;
    for (final p in set) {
      final allowed = policy.allow[p];
      if (allowed == null) continue;
      for (final q in set) {
        if (q != p && !allowed.contains(q)) return false;
      }
    }
    return true;
  }

  /// Prizes [uid] holds in [winners], optionally excluding [except].
  List<PrizeId> heldBy(UserId uid, List<Winner> winners, {PrizeId? except}) => [
    for (final w in winners)
      if (w.uid == uid && w.prizeId != except) w.prizeId,
  ];

  /// May [uid] add [target] to what they already hold without giving
  /// anything up?
  bool isEligible({
    required UserId uid,
    required Prize target,
    required List<Winner> winners,
    required PrizePolicy policy,
  }) =>
      canHold([...heldBy(uid, winners, except: target.id), target.id], policy);

  /// Prizes the player may give up when winning [offer] while holding [held]
  /// would break the policy. Empty when they can simply keep everything.
  /// Each option leaves a valid set; giving up [offer] (= keep what they had)
  /// is always offered.
  List<PrizeId> releaseOptions({
    required List<PrizeId> held,
    required PrizeId offer,
    required PrizePolicy policy,
  }) {
    final all = [...held.where((p) => p != offer), offer];
    if (canHold(all, policy)) return const [];
    final out = <PrizeId>[
      for (final p in all)
        if (p == offer || canHold(all.where((q) => q != p), policy)) p,
    ];
    return out;
  }
}
