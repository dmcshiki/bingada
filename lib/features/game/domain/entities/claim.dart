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
enum ClaimChoice {
  keep,
  swap,

  /// Tie while at the limit: enter the draw anyway.
  join,

  /// Tie while at the limit: skip it; the others share the prize.
  skip,
}

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

    /// Legacy answer (keep = give up the offer, swap = give up the held one).
    ClaimChoice? choice,

    /// Player answer: the prize they give up (the offer or one they hold).
    PrizeId? releasePrizeId,

    /// Tie while the player is at the limit: they are asked first whether
    /// they join the draw ([ClaimChoice.join]) or skip it.
    @Default(false) bool tieOptIn,
    required DateTime createdAt,
  }) = _Claim;
}

extension ClaimX on Claim {
  /// The player already answered an `awaitingChoice`.
  bool get answered => choice != null || releasePrizeId != null;
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
