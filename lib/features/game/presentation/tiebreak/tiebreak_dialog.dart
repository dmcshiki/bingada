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

  @override
  void initState() {
    super.initState();
    // Tied players already at the limit choose first: join or skip.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.askTieOptIns(widget.tied),
    );
  }

  List<Claim> get _live => widget.controller.tieState(widget.tied).contenders;

  Future<void> _draw() async {
    final w = await widget.controller.drawTie(_live);
    if (mounted) setState(() => _winner = w);
  }

  Future<void> _confirm() async {
    final w = _winner;
    if (w == null) return;
    final ok = await widget.controller.confirmTie(_live, w);
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
      final st = c.tieState(widget.tied);
      final skipped = {for (final s in st.skipped) s.uid};
      // The host's own claim waiting for join/skip: answered right here.
      final mine = [
        for (final t in c.claims)
          if (widget.tied.any((x) => x.id == t.id) &&
              t.uid == g.hostUid &&
              t.status == ClaimStatus.awaitingChoice &&
              t.tieOptIn)
            t,
      ].firstOrNull;
      // One card per player (an old duplicate claim must not show twice).
      final seen = <UserId>{};
      final cards = [
        for (final t in widget.tied)
          if (seen.add(t.uid)) t,
      ];
      final waitingNames = [
        for (final t in c.claims)
          if (widget.tied.any((x) => x.id == t.id) &&
              t.status == ClaimStatus.awaitingChoice &&
              t.tieOptIn)
            playerName(c.players, t.uid),
      ];
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
                              '${prize == null ? '' : modalityName(prize).toUpperCase()} · MESMO NÚMERO$ball',
                              textAlign: TextAlign.center,
                              style: AppText.kicker(color: AppColors.white)
                                  .copyWith(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        SplitTitle(
                          '${countWord[0].toUpperCase()}${countWord.substring(1)} '
                          'bingos, um prêmio:',
                          prize?.label ?? '',
                          size: MediaQuery.sizeOf(context).width < 700
                              ? 32
                              : 54,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 26),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Text(
                            'Os $countWord gritos são válidos e fecharam no mesmo número. O desempate é '
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
                        _EqualCards(
                          children: [
                            for (final t in cards)
                              TiePlayerCard(
                                name: playerName(c.players, t.uid),
                                uid: t.uid,
                                how: describeMatches(
                                  t.matched,
                                  g.template,
                                  prize: prize,
                                ),
                                state: skipped.contains(t.uid)
                                    ? TieCardState.loser
                                    : !done
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
                        if (mine != null)
                          _HostOptIn(
                            busy: c.busy,
                            others: [
                              for (final n in waitingNames)
                                if (n != playerName(c.players, g.hostUid)) n,
                            ],
                            onAnswer: (join) =>
                                c.answerOwnTie(mine, join: join),
                          )
                        else if (st.waiting)
                          Text(
                            'Aguardando ${waitingNames.join(', ')} decidir se entra no '
                            'sorteio: já está no limite de prêmios da sala.',
                            textAlign: TextAlign.center,
                            style: AppText.body(
                              16,
                              weight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          )
                        else if (!done && st.live.isEmpty)
                          AppButton(
                            label: 'Todos pularam · seguir a regra da sala',
                            kind: AppButtonKind.light,
                            height: 60,
                            fontSize: 16,
                            onPressed: c.busy
                                ? null
                                : () async {
                                    final nav = Navigator.of(context);
                                    final ok = await c.releaseSkippedTie(
                                      widget.tied.first.prizeId,
                                    );
                                    if (ok) nav.pop();
                                  },
                          )
                        else if (!done && st.contenders.length == 1)
                          AppButton(
                            label:
                                '${playerName(c.players, st.contenders.single.uid)} '
                                '${st.contenders.length < st.live.length ? '(menos prêmios) ' : ''}'
                                'fica com o prêmio',
                            kind: AppButtonKind.light,
                            height: 60,
                            fontSize: 16,
                            onPressed: c.busy
                                ? null
                                : () async {
                                    final nav = Navigator.of(context);
                                    final ok = await c.awardSoleTied(
                                      st.contenders.single,
                                    );
                                    if (ok) nav.pop();
                                  },
                          )
                        else if (!done)
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

/// The host is tied and at the limit: join or skip, right in this screen.
class _HostOptIn extends StatelessWidget {
  const _HostOptIn({
    required this.busy,
    required this.others,
    required this.onAnswer,
  });

  final bool busy;
  final List<String> others;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Text(
          'Você também empatou e já está no limite de prêmios da sala. '
          'Entra no sorteio? Se ganhar, escolhe com quais prêmios fica.'
          '${others.isEmpty ? '' : ' Também falta ${others.join(', ')} decidir.'}',
          textAlign: TextAlign.center,
          style: AppText.body(
            16,
            weight: FontWeight.w700,
            color: AppColors.white,
            height: 1.5,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          AppButton(
            label: 'Pular o sorteio',
            kind: AppButtonKind.outline,
            height: 60,
            onPressed: busy ? null : () => onAnswer(false),
          ),
          AppButton(
            label: 'Entrar no sorteio',
            kind: AppButtonKind.light,
            height: 60,
            onPressed: busy ? null : () => onAnswer(true),
          ),
        ],
      ),
    ],
  );
}

/// Tie cards all the same size: up to 6 per row, scaled to fit the screen.
class _EqualCards extends StatelessWidget {
  const _EqualCards({required this.children});

  final List<Widget> children;

  static const _card = 360.0;
  static const _gap = 32.0;

  @override
  Widget build(BuildContext context) {
    final n = children.length;
    if (n == 0) return const SizedBox.shrink();
    final rows = (n / 6).ceil();
    final perRow = (n / rows).ceil();
    final size = MediaQuery.sizeOf(context);
    final maxW = size.width * .9;
    final cw = ((maxW - _gap * (perRow - 1)) / perRow).clamp(120.0, _card);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW, maxHeight: size.height * .5),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: cw * perRow + _gap * (perRow - 1),
          child: Wrap(
            spacing: _gap,
            runSpacing: _gap * .75,
            alignment: WrapAlignment.center,
            children: [
              for (final c in children)
                SizedBox(
                  width: cw,
                  child: FittedBox(child: c),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
