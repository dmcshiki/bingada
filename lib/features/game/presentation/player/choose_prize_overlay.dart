import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';

/// Valid BINGO while already holding a prize: keep the old one or swap.
/// The prize let go goes to the other tied player (1), is drawn among the
/// other tied players (2+), or goes back into play (no tie).
class ChoosePrizeOverlay extends StatelessWidget {
  const ChoosePrizeOverlay({
    required this.claim,
    required this.game,
    required this.players,
    required this.claims,
    required this.busy,
    required this.onChoose,
    super.key,
  });

  final Claim claim;
  final Game game;
  final List<Player> players;
  final List<Claim> claims;
  final bool busy;
  final ValueChanged<ClaimChoice> onChoose;

  @override
  Widget build(BuildContext context) {
    final offer = prizeById(game, claim.offerPrizeId ?? claim.prizeId);
    Prize? held;
    for (final w in game.winners) {
      if (w.uid == claim.uid && w.prizeId != offer?.id) {
        held = prizeById(game, w.prizeId);
        break;
      }
    }
    final others = [
      for (final c in claims)
        if (c.id != claim.id &&
            c.prizeId == claim.prizeId &&
            c.status == ClaimStatus.tied)
          c,
    ];
    final fate = switch (others.length) {
      0 => 'O que você não ficar volta para o jogo.',
      1 =>
        'O que você não ficar vai para ${playerName(players, others.single.uid)}, que empatou com você.',
      final n =>
        'O que você não ficar será sorteado entre os outros $n empatados.',
    };
    final heldLabel = held?.label ?? 'seu prêmio';
    final offerLabel = offer?.label ?? 'o novo prêmio';
    return ScrimOverlay(
      child: DialogCard(
        semanticLabel: 'Escolha seu prêmio',
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TokenBox(
                size: 130,
                color: AppColors.green,
                child: Text(
                  '⇄',
                  style: AppText.display(64, color: AppColors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'VOCÊ GANHOU DE NOVO!',
                textAlign: TextAlign.center,
                style: AppText.display(36, color: const Color(0xFF2E7D3A)),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Você levou $offerLabel, mas já tem $heldLabel. '
                  'Só dá para ficar com um. $fate',
                  textAlign: TextAlign.center,
                  style: AppText.body(18, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              if (busy)
                const LoadingDots(
                  color: AppColors.navy,
                  semanticLabel: 'Enviando sua escolha',
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppButton(
                      label: 'Manter $heldLabel',
                      height: 56,
                      onPressed: () => onChoose(ClaimChoice.keep),
                    ),
                    AppButton(
                      label: 'Trocar por $offerLabel',
                      height: 56,
                      onPressed: () => onChoose(ClaimChoice.swap),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
