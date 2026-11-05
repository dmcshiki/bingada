import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/presentation/common/dashed_border.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';
import 'package:tokingo/features/game/presentation/host/host_panel_controller.dart';

/// What the host decided in the verify modal.
sealed class VerifyAction {
  const VerifyAction();
}

final class VerifyReject extends VerifyAction {
  const VerifyReject(this.claim);
  final Claim claim;
}

final class VerifyConfirm extends VerifyAction {
  const VerifyConfirm(this.claim);
  final Claim claim;
}

final class VerifyConfirmAll extends VerifyAction {
  const VerifyConfirmAll(this.tied);
  final List<Claim> tied;
}

final class VerifyGoTiebreak extends VerifyAction {
  const VerifyGoTiebreak(this.tied);
  final List<Claim> tied;
}

/// 12 / 12a – verify one claim at a glance.
class VerifyClaimDialog extends StatefulWidget {
  const VerifyClaimDialog({
    required this.controller,
    required this.claimId,
    super.key,
  });

  final HostPanelController controller;
  final ClaimId claimId;

  @override
  State<VerifyClaimDialog> createState() => _VerifyClaimDialogState();
}

class _VerifyClaimDialogState extends State<VerifyClaimDialog> {
  BingoCard? _card;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCard());
  }

  Future<void> _loadCard() async {
    final g = widget.controller.game;
    final claim = _claim;
    if (g == null || claim == null) return;
    final card = await sl<GameRepository>().getCard(g.id, claim.uid);
    if (mounted) setState(() => _card = card);
  }

  Claim? get _claim {
    for (final c in widget.controller.claims) {
      if (c.id == widget.claimId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final g = c.game;
      final claim = _claim;
      if (g == null || claim == null) return const SizedBox.shrink();
      final result = c.results[claim.id];
      final tied = result == null ? const <Claim>[] : c.tiedFor(claim);
      final wide = MediaQuery.sizeOf(context).width >= 1000;
      final cardView = _VerifyCardView(
        game: g,
        claim: claim,
        card: _card,
        result: result,
      );
      final info = _VerifyInfo(
        game: g,
        claim: claim,
        result: result,
        name: playerName(c.players, claim.uid),
        tied: tied,
        players: c.players,
      );
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: DialogCard(
          semanticLabel: 'Verificar pedido de BINGO',
          maxWidth: 1040,
          padding: const EdgeInsets.all(36),
          child: SingleChildScrollView(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 460, child: cardView),
                      const SizedBox(width: 40),
                      Expanded(child: info),
                    ],
                  )
                : Column(
                    children: [info, const SizedBox(height: 24), cardView],
                  ),
          ),
        ),
      );
    },
  );
}

enum _CellState { inPattern, drawn, markedNotDrawn, neutral }

class _VerifyCardView extends StatelessWidget {
  const _VerifyCardView({
    required this.game,
    required this.claim,
    required this.card,
    required this.result,
  });

  final Game game;
  final Claim claim;
  final BingoCard? card;
  final ClaimResult? result;

  Set<int> _patternCells(Prize? prize) {
    final t = game.template;
    final rows = t.rows;
    final cols = t.cols;
    final out = <int>{};
    for (final m in result?.matched ?? const <PatternMatch>[]) {
      final total = rows * cols;
      switch (m.kind) {
        case PatternKind.horizontal:
          out.addAll([for (var c = 0; c < cols; c++) m.index * cols + c]);
        case PatternKind.vertical:
          out.addAll([for (var r = 0; r < rows; r++) r * cols + m.index]);
        case PatternKind.diagonal:
          out.addAll([
            for (var i = 0; i < rows; i++)
              if (m.index == 0) i * cols + i else i * cols + (cols - 1 - i),
          ]);
        case PatternKind.x:
          out.addAll([
            for (var i = 0; i < rows; i++) ...[
              i * cols + i,
              i * cols + (cols - 1 - i),
            ],
          ]);
        case PatternKind.corners:
          out.addAll([0, cols - 1, (rows - 1) * cols, total - 1]);
        case PatternKind.frame:
          out.addAll([
            for (var i = 0; i < total; i++)
              if (i < cols ||
                  i >= total - cols ||
                  i % cols == 0 ||
                  i % cols == cols - 1)
                i,
          ]);
        case PatternKind.full:
          out.addAll([for (var i = 0; i < total; i++) i]);
        case PatternKind.custom:
          final mask = prize?.customMask ?? const <bool>[];
          out.addAll([
            for (final (i, on) in mask.indexed)
              if (on) i,
          ]);
        case PatternKind.line || PatternKind.underdog:
          break;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cd = card;
    final t = game.template;
    if (cd == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: LoadingDots(color: AppColors.primary, dotSize: 16),
        ),
      );
    }
    final drawn = game.draws.take(claim.drawIndex).toSet();
    final marked = claim.markedCells.toSet();
    final pattern = _patternCells(prizeById(game, claim.prizeId));
    final free = t.freeCellIndex;
    final cells = <Widget>[];
    for (final (i, id) in cd.cells.indexed) {
      final isFree = i == free || id == null;
      final isDrawn = isFree || drawn.contains(id);
      final state = switch ((
        isDrawn,
        marked.contains(i) || isFree,
        pattern.contains(i),
      )) {
        (true, true, true) => _CellState.inPattern,
        (false, true, _) when !isFree => _CellState.markedNotDrawn,
        (true, _, _) => _CellState.drawn,
        _ => _CellState.neutral,
      };
      final base = isFree ? t.free.label : t.item(id).label;
      final name = isFree ? 'Livre' : t.ballText(id);
      cells.add(switch (state) {
        _CellState.inPattern => _VerifyCell(
          label: '$base✓',
          background: AppColors.green,
          foreground: const Color(0xFF123B19),
          border: AppColors.light,
          semanticsLabel: '$name, no padrão',
        ),
        _CellState.drawn => _VerifyCell(
          label: base,
          background: const Color(0xFFDCE6F4),
          foreground: AppColors.navy,
          border: AppColors.light,
          semanticsLabel: '$name, saiu${marked.contains(i) ? ', marcado' : ''}',
        ),
        _CellState.markedNotDrawn => _VerifyCell(
          label: '$base✕',
          background: const Color(0xFFF3EAFA),
          foreground: AppColors.purple,
          border: AppColors.purple,
          dashed: true,
          semanticsLabel: '$name, marcou e não saiu',
        ),
        _CellState.neutral => _VerifyCell(
          label: base,
          background: AppColors.light,
          foreground: AppColors.graphite,
          border: AppColors.light,
          semanticsLabel: name,
        ),
      });
    }
    final cols = t.cols;
    final rows = (cells.length / cols).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (var c = 0; c < cols; c++) ...[
                if (c > 0) const SizedBox(width: 8),
                Expanded(
                  child: r * cols + c < cells.length
                      ? cells[r * cols + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 14),
        const Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _Legend(
              symbol: '✓',
              color: Color(0xFF2E7D3A),
              text: 'marcou e saiu (no padrão)',
            ),
            _Legend(symbol: '●', color: Color(0xFF4F86C6), text: 'saiu'),
            _Legend(
              symbol: '✕',
              color: AppColors.purple,
              text: 'marcou e não saiu',
            ),
          ],
        ),
      ],
    );
  }
}

/// Verify-grid cell (12): no header row, 2px border; dashed purple when the
/// player stamped a ball that was not drawn.
class _VerifyCell extends StatelessWidget {
  const _VerifyCell({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
    required this.semanticsLabel,
    this.dashed = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color border;
  final bool dashed;
  final String semanticsLabel;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppText.display(
              label.length > 5 ? 12 : 22,
              color: foreground,
            ),
          ),
        ),
      ),
    );
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(_radius),
        border: dashed ? null : Border.all(color: border, width: 2),
      ),
      child: content,
    );
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: dashed
            ? CustomPaint(
                foregroundPainter: DashedRRectPainter(
                  color: border,
                  radius: _radius,
                ),
                child: box,
              )
            : box,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.symbol,
    required this.color,
    required this.text,
  });

  final String symbol;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: AppText.body(13),
      children: [
        TextSpan(
          text: '$symbol ',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        TextSpan(text: text),
      ],
    ),
  );
}

class _VerifyInfo extends StatelessWidget {
  const _VerifyInfo({
    required this.game,
    required this.claim,
    required this.result,
    required this.name,
    required this.tied,
    required this.players,
  });

  final Game game;
  final Claim claim;
  final ClaimResult? result;
  final String name;
  final List<Claim> tied;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final t = game.template;
    final prize = prizeById(game, claim.prizeId);
    final current = game.currentPrize;
    final r = result;
    final kind = r == null
        ? 'conferindo…'
        : describeMatches(r.matched, t, prize: prize);
    final ok = r?.verdict == ClaimVerdict.valid;
    final (vBg, vTitle) = switch (r?.verdict) {
      null => (AppColors.graphite, 'CONFERINDO…'),
      ClaimVerdict.valid => (AppColors.greenDark, 'BINGO VÁLIDO'),
      ClaimVerdict.missed => (AppColors.purple, 'COMEU BOLA'),
      ClaimVerdict.wrongPattern => (AppColors.purple, 'MODALIDADE ERRADA'),
      ClaimVerdict.notEligible => (AppColors.graphite, 'NÃO ELEGÍVEL'),
      ClaimVerdict.penalized => (AppColors.graphite, 'PENALIZADO'),
      ClaimVerdict.tampered => (AppColors.graphite, 'CARTELA ADULTERADA'),
    };
    final vSub = r == null
        ? 'Recalculando a cartela e as bolas até o grito.'
        : ok
        ? '$kind completa na bola nº ${claim.drawIndex}.'
        : r.reason;
    final tampered = r?.verdict == ClaimVerdict.tampered;
    final current_ = current;
    final ballNow = game.currentBall == null
        ? ''
        : ' ${t.ballText(game.currentBall!)}';
    final others = [
      for (final o in tied)
        if (o.id != claim.id) o,
    ];
    final allWin = game.settings.tieBreak == TieBreakRule.allWin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NameToken(name: name, uid: claim.uid, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.body(20, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      style: AppText.body(14),
                      children: [
                        TextSpan(
                          text:
                              'gritou BINGO na ${ballOrdinal(claim.drawIndex)} · valendo ',
                        ),
                        TextSpan(
                          text: prize?.label ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (prize != null)
                          TextSpan(text: ' (${modalityName(prize)})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerLeft,
          child: Pill(
            label: 'Tipo detectado: $kind',
            color: AppColors.light,
            bold: true,
          ),
        ),
        const SizedBox(height: 22),
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: vBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EllipsisText(
                  vTitle,
                  style: AppText.display(40, color: AppColors.white),
                ),
                const SizedBox(height: 6),
                Text(vSub, style: AppText.body(17, color: AppColors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _CheckRow(
          ok: !tampered,
          text: 'Cartela confere com a seed (uid + jogo + salt)',
        ),
        _CheckRow(
          ok: ok,
          text: ok
              ? 'Modalidade do prêmio atual: ${current_ == null ? '—' : modalityName(current_)}'
              : 'Modalidade do prêmio atual (${current_ == null ? '—' : modalityName(current_)}) não fechou',
        ),
        _CheckRow(
          ok: true,
          text:
              'Validado com as ${claim.drawIndex} bolas sorteadas até o grito',
        ),
        const SizedBox(height: 22),
        if (others.isEmpty || !ok) ...[
          Text(
            'Janela de gritos da bola$ballNow: aberta até você sortear a próxima. '
            '${ok ? 'Nenhum outro grito válido até agora.' : ''}',
            style: AppText.body(13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Rejeitar',
                  kind: ok ? AppButtonKind.outline : AppButtonKind.primary,
                  height: 60,
                  onPressed: () =>
                      Navigator.of(context).pop(VerifyReject(claim)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Confirmar vencedor',
                  kind: ok ? AppButtonKind.primary : AppButtonKind.secondary,
                  height: 60,
                  onPressed: ok
                      ? () => Navigator.of(context).pop(VerifyConfirm(claim))
                      : null,
                ),
              ),
            ],
          ),
        ] else
          _TieBlock(
            others: others,
            players: players,
            template: game,
            onGo: () => Navigator.of(context)
                .pop(allWin ? VerifyConfirmAll(tied) : VerifyGoTiebreak(tied)),
            allWin: allWin,
          ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text('${ok ? '✓' : '✕'} $text', style: AppText.body(15)),
  );
}

/// 12a – "Empate detectado".
class _TieBlock extends StatelessWidget {
  const _TieBlock({
    required this.others,
    required this.players,
    required this.template,
    required this.onGo,
    required this.allWin,
  });

  final List<Claim> others;
  final List<Player> players;
  final Game template;
  final VoidCallback onGo;
  final bool allWin;

  @override
  Widget build(BuildContext context) {
    final names = others.map((o) => playerName(players, o.uid)).join(', ');
    final how = others
        .map(
          (o) => describeMatches(
            o.matched,
            template.template,
            prize: prizeById(template, o.prizeId),
          ),
        )
        .join(', ');
    final ball = template.currentBall == null
        ? ''
        : ', ${template.template.ballText(template.currentBall!)}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Empate detectado',
            style: AppText.display(22, color: AppColors.navy),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: AppText.body(15, height: 1.45),
              children: [
                TextSpan(
                  text: names,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      ' também ${others.length > 1 ? 'gritaram' : 'gritou'} um BINGO válido ($how) na mesma bola$ball. '
                      '${allWin ? 'Pela regra da sala, todos ganham juntos.' : 'Pela regra da sala, o prêmio vai para sorteio.'}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: allWin
                ? 'Confirmar todos os vencedores'
                : 'Ir para o sorteio de desempate',
            height: 60,
            onPressed: onGo,
          ),
        ],
      ),
    );
  }
}
