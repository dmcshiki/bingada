import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';

part 'claim.freezed.dart';

/// Result of checking a claim (§5).
enum ClaimVerdict {
  valid,
  missed,
  wrongPattern,
  notEligible,
  penalized,
  tampered,
}

/// `awaitingChoice`: valid, but the player already holds a prize and must pick
/// one (keep the old or swap). `declined`: valid, the player kept the old one.
enum ClaimStatus {
  pending,
  confirmed,
  rejected,
  tied,
  awaitingChoice,
  declined,
}

/// Player answer to an [ClaimStatus.awaitingChoice] claim.
enum ClaimChoice { keep, swap }

@freezed
abstract class Claim with _$Claim {
  const factory Claim({
    required ClaimId id,
    required UserId uid,
    required PrizeId prizeId,

    /// `draws.length` at the moment of the claim.
    required int drawIndex,

    /// Row-major indexes the player had stamped when claiming (marks are
    /// local until a claim; the snapshot is what the host verifies).
    @Default(<int>[]) List<int> markedCells,
    @Default(ClaimStatus.pending) ClaimStatus status,
    ClaimVerdict? verdict,
    @Default(<PatternMatch>[]) List<PatternMatch> matched,

    /// Prize offered while awaiting a choice when it differs from [prizeId]
    /// (a prize passed on from a tie).
    PrizeId? offerPrizeId,
    ClaimChoice? choice,
    required DateTime createdAt,
  }) = _Claim;
}

/// What the verifier says about a claim.
@freezed
abstract class ClaimResult with _$ClaimResult {
  const factory ClaimResult({
    required ClaimVerdict verdict,
    @Default(<PatternMatch>[]) List<PatternMatch> matched,

    /// Card items marked/required but not drawn (for "comeu bola" UI).
    @Default(<ItemId>[]) List<ItemId> notDrawn,

    /// Human-readable reason for the UI.
    @Default('') String reason,
  }) = _ClaimResult;
}
