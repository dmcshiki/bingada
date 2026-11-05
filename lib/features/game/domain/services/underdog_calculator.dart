import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/prize_policy_evaluator.dart';

/// Outcome of the azarão elimination after replaying the draws.
final class UnderdogOutcome {
  const UnderdogOutcome({
    required this.decided,
    required this.survivors,
    required this.decidedAt,
    required this.alive,
  });

  /// True once there is a winner (or tied winners).
  final bool decided;

  /// Winner(s) when [decided]; more than one means a tie (R26).
  final List<UserId> survivors;

  /// Number of draws when it was decided (the ball that settled it).
  final int? decidedAt;

  /// Players still in the race (while not decided).
  final int alive;

  bool get tied => survivors.length > 1;

  static const none = UnderdogOutcome(
    decided: false,
    survivors: [],
    decidedAt: null,
    alive: 0,
  );
}

/// Azarão by elimination: every eligible player starts in the race; on each
/// ball, whoever has that number on the card is out, marked or not (stamps
/// don't matter). The last one standing wins. If the last players all fall on
/// the same ball, they tie. If the game ends with several still standing,
/// they tie too. The free cell never counts.
///
/// Eligibility follows the prize policy as the game goes: a player who wins a
/// sequential prize that blocks the azarão leaves the race at that ball.
final class UnderdogCalculator {
  const UnderdogCalculator();

  UnderdogOutcome run({
    required List<BingoCard> cards,
    required List<ItemId> draws,
    required Prize underdogPrize,
    required List<Winner> winners,
    required PrizePolicy policy,
    required int? freeCellIndex,
    bool gameOver = false,
  }) {
    const policyEval = PrizePolicyEvaluator();
    bool eligible(UserId uid, int count) => policyEval.isEligible(
      uid: uid,
      target: underdogPrize,
      winners: [
        for (final w in winners)
          if (w.prizeId != underdogPrize.id && w.drawIndex <= count) w,
      ],
      policy: policy,
    );

    final numbers = <UserId, Set<ItemId>>{
      for (final card in cards)
        card.owner: {
          for (final (i, id) in card.cells.indexed)
            if (i != freeCellIndex && id != null) id,
        },
    };

    var alive = [
      for (final uid in numbers.keys)
        if (eligible(uid, 0)) uid,
    ];
    if (alive.isEmpty) return UnderdogOutcome.none;

    for (final (i, ball) in draws.indexed) {
      final count = i + 1;
      final before = [
        for (final uid in alive)
          if (eligible(uid, count)) uid,
      ];
      alive = [
        for (final uid in before)
          if (!numbers[uid]!.contains(ball)) uid,
      ];
      if (alive.length == 1) {
        return UnderdogOutcome(
          decided: true,
          survivors: alive,
          decidedAt: count,
          alive: 1,
        );
      }
      if (alive.isEmpty) {
        if (before.isEmpty) return UnderdogOutcome.none;
        return UnderdogOutcome(
          decided: true,
          survivors: before,
          decidedAt: count,
          alive: 0,
        );
      }
    }

    if (gameOver) {
      return UnderdogOutcome(
        decided: true,
        survivors: alive,
        decidedAt: draws.length,
        alive: alive.length,
      );
    }
    return UnderdogOutcome(
      decided: false,
      survivors: const [],
      decidedAt: null,
      alive: alive.length,
    );
  }
}
