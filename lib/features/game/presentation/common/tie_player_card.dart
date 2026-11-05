import 'package:flutter/material.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';

enum TieCardState { pending, winner, loser }

/// Player card in the tiebreak (shared with the stream 13e/13f).
class TiePlayerCard extends StatelessWidget {
  const TiePlayerCard({
    required this.name,
    required this.uid,
    required this.state,
    required this.winnerTag,
    super.key,
    this.how,
    this.width = 360,
  });

  final String name;
  final UserId uid;
  final String? how;
  final TieCardState state;
  final String winnerTag;
  final double width;

  @override
  Widget build(BuildContext context) {
    final win = state == TieCardState.winner;
    final lose = state == TieCardState.loser;
    final fg = win ? AppColors.navy : AppColors.white;
    final tag = switch (state) {
      TieCardState.winner => winnerTag,
      TieCardState.loser => 'fica para o próximo',
      TieCardState.pending => 'bingo válido',
    };
    return Opacity(
      opacity: lose ? .55 : 1,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: win ? AppColors.white : AppColors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: win
                ? AppColors.green
                : AppColors.white.withValues(alpha: .25),
            width: win ? 4 : 2,
          ),
        ),
        child: Column(
          children: [
            NameToken(name: name, uid: uid, size: 120),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AppText.display(28, color: fg),
            ),
            if (how case final h?) ...[
              const SizedBox(height: 16),
              Text(
                h,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(14, color: fg),
              ),
            ],
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: win
                    ? AppColors.green
                    : AppColors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  tag,
                  style: AppText.body(
                    15,
                    weight: FontWeight.w700,
                    color: win ? AppColors.inkOnLight : fg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
