import 'package:flutter/material.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/tie_player_card.dart';
import 'package:tokingo/features/game/presentation/host/host_panel_controller.dart';

/// 12b – deterministic tiebreak draw (R26). Nobody picks, not even the host.
class TiebreakDialog extends StatefulWidget {
  const TiebreakDialog({
    required this.controller,
    required this.tied,
    super.key,
  });

  final HostPanelController controller;
  final List<Claim> tied;

  @override
  State<TiebreakDialog> createState() => _TiebreakDialogState();
}

class _TiebreakDialogState extends State<TiebreakDialog> {
  UserId? _winner;

  Future<void> _draw() async {
    final w = await widget.controller.drawTie(widget.tied);
    if (mounted) setState(() => _winner = w);
  }

  Future<void> _confirm() async {
    final w = _winner;
    if (w == null) return;
    final ok = await widget.controller.confirmTie(widget.tied, w);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final g = c.game;
      if (g == null) return const SizedBox.shrink();
      final prize = g.prizeById(widget.tied.first.prizeId) ?? g.currentPrize;
      final ball = g.currentBall == null
          ? ''
          : ' (${g.template.ballText(g.currentBall!)})';
      final done = _winner != null;
      final count = widget.tied.length;
      final countWord = switch (count) {
        2 => 'dois',
        3 => 'três',
        _ => '$count',
      };
      return Dialog.fullscreen(
        backgroundColor: AppColors.navy,
        child: Semantics(
          label: 'Sorteio de desempate',
          scopesRoute: true,
          namesRoute: true,
          child: Stack(
            children: [
              const Positioned(
                right: -180,
                top: -220,
                child: BlobShape(size: 560, color: AppColors.deepBlue),
              ),
              const Positioned(
                left: -200,
                bottom: -280,
                child: BlobShape(size: 560, color: AppColors.graphite),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width < 700
                          ? 24
                          : 72,
                      vertical: 48,
                    ),
                    child: Column(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'EMPATE · ${prize?.label.toUpperCase() ?? ''} · '
                              '${prize == null ? '' : modalityName(prize).toUpperCase()} · MESMA BOLA$ball',
                              textAlign: TextAlign.center,
                              style: AppText.kicker(color: AppColors.white)
                                  .copyWith(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        SplitTitle(
                          '$countWord bingos,',
                          'um prêmio: ${prize?.label ?? ''}',
                          size: MediaQuery.sizeOf(context).width < 700
                              ? 32
                              : 54,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 26),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Text(
                            'Os $countWord gritos são válidos e fecharam na mesma bola. O desempate é '
                            'sorteado pelo sistema: ninguém escolhe o resultado, nem o host. '
                            'Esta tela aparece também no telão.',
                            textAlign: TextAlign.center,
                            style: AppText.body(
                              17,
                              color: AppColors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 38),
                        Wrap(
                          spacing: 48,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final t in widget.tied)
                              TiePlayerCard(
                                name: playerName(c.players, t.uid),
                                uid: t.uid,
                                how: describeMatches(
                                  t.matched,
                                  g.template,
                                  prize: prize,
                                ),
                                state: !done
                                    ? TieCardState.pending
                                    : t.uid == _winner
                                    ? TieCardState.winner
                                    : TieCardState.loser,
                                winnerTag: 'VENCEU O DESEMPATE',
                              ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        if (c.actionError case final err?)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              err,
                              style: AppText.body(
                                14,
                                weight: FontWeight.w700,
                                color: AppColors.pink,
                              ),
                            ),
                          ),
                        if (!done)
                          AppButton(
                            label: 'SORTEAR DESEMPATE',
                            kind: AppButtonKind.light,
                            height: 72,
                            displayFont: true,
                            fontSize: 26,
                            onPressed: c.busy ? null : _draw,
                          )
                        else
                          AppButton(
                            label: 'Confirmar e seguir para o próximo prêmio',
                            kind: AppButtonKind.light,
                            height: 60,
                            fontSize: 16,
                            onPressed: c.busy ? null : _confirm,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
