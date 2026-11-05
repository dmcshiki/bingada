import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';

/// Why a player cannot claim right now (shown on the BINGO button).
final class PenaltyBlock {
  const PenaltyBlock({required this.reason, this.drawsLeft});

  final String reason;
  final int? drawsLeft;
}

/// R31 / §5.4: extensible penalty. With [NoPenalty] never blocks.
final class PenaltyEvaluator {
  const PenaltyEvaluator();

  PenaltyBlock? blockFor({
    required UserId uid,
    required ClaimPenaltyPolicy policy,
    required List<Claim> history,
    required int currentDrawIndex,
  }) => switch (policy) {
    NoPenalty() => null,
    SkipDraws(:final draws) => _skip(uid, draws, history, currentDrawIndex),
  };

  PenaltyBlock? _skip(UserId uid, int n, List<Claim> history, int current) {
    int? last;
    for (final c in history) {
      if (c.uid == uid &&
          c.verdict == ClaimVerdict.missed &&
          (last == null || c.drawIndex > last)) {
        last = c.drawIndex;
      }
    }
    if (last == null) return null;
    final elapsed = current - last;
    return elapsed < n
        ? PenaltyBlock(
            reason: 'Bloqueado por comer bola',
            drawsLeft: n - elapsed,
          )
        : null;
  }
}
