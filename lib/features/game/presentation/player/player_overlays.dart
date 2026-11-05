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
import 'package:tokingo/features/game/presentation/player/player_game_controller.dart';
import 'package:tokingo/features/help/presentation/how_to_play.dart';

/// 10 / 10b–d: result of the player's own claim.
class ClaimResultOverlay extends StatelessWidget {
  const ClaimResultOverlay({
    required this.kind,
    required this.claim,
    required this.game,
    required this.onClose,
    super.key,
  });

  final ClaimOverlayKind kind;
  final Claim? claim;
  final Game game;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = game.template;
    final prize = claim == null
        ? null
        : prizeById(game, claim!.offerPrizeId ?? claim!.prizeId);
    final how = describeMatches(claim?.matched ?? const [], t, prize: prize);
    final current = game.currentPrize;
    final (
      icon,
      iconSize,
      color,
      fg,
      titleColor,
      title,
      text,
      btn,
    ) = switch (kind) {
      ClaimOverlayKind.waiting => (
        '…',
        64.0,
        AppColors.primary,
        AppColors.white,
        AppColors.navy,
        'BINGO enviado!',
        'O host está conferindo sua cartela. Nada de apagar carimbo agora.',
        null,
      ),
      ClaimOverlayKind.valid => (
        '✓',
        80.0,
        AppColors.green,
        const Color(0xFF123B19),
        const Color(0xFF2E7D3A),
        'VOCÊ GANHOU!',
        '${prize == null ? how : modalityName(prize)}, na ${ballOrdinal(claim?.drawIndex ?? 0)}. Prêmio: ${prize?.label ?? ''}. '
            'O jogo segue valendo o próximo prêmio.',
        'Continuar jogando',
      ),
      ClaimOverlayKind.missed => (
        '✕',
        80.0,
        AppColors.purple,
        AppColors.white,
        AppColors.purple,
        'COMEU BOLA',
        'Você marcou bola que ainda não saiu, ou a cartela não fechou. '
            'Esse grito não valeu, mas o jogo segue: confira a cartela e '
            'grite quando fechar de verdade.',
        'Voltar à cartela',
      ),
      ClaimOverlayKind.wrongPattern => (
        '!',
        80.0,
        AppColors.pink,
        AppColors.inkOnLight,
        AppColors.graphite,
        'MODALIDADE ERRADA',
        '${claim?.matched.isNotEmpty ?? false ? 'Sua $how fechou' : 'Você fechou outro padrão'}, '
            'mas agora vale ${current == null ? 'outro prêmio' : modalityName(current)}. '
            'Guarde a emoção para o próximo prêmio.',
        'Voltar à cartela',
      ),
      ClaimOverlayKind.tieLost => (
        '=',
        72.0,
        AppColors.primary,
        AppColors.white,
        AppColors.navy,
        'EMPATE',
        'Seu BINGO valeu, mas empatou na mesma bola e o sorteio de desempate '
            'escolheu outra pessoa. '
            'Se quem ganhou ficar com o prêmio que já tinha, este pode vir para você. O jogo segue!',
        'Voltar à cartela',
      ),
      ClaimOverlayKind.kept => (
        '✓',
        72.0,
        AppColors.primary,
        AppColors.white,
        AppColors.navy,
        'PRÊMIO MANTIDO',
        'Você ficou com o prêmio que já tinha. O jogo segue, e você pode gritar BINGO de novo.',
        'Continuar jogando',
      ),
      // Rendered by [ChoosePrizeOverlay]; never reaches this switch.
      ClaimOverlayKind.choose || ClaimOverlayKind.other => (
        '!',
        72.0,
        AppColors.graphite,
        AppColors.white,
        AppColors.graphite,
        'GRITO NÃO VALEU',
        switch (claim?.verdict) {
          ClaimVerdict.notEligible =>
            'Você já atingiu o limite de prêmios desta sala.',
          ClaimVerdict.tampered =>
            'Sua cartela não confere com a seed da partida.',
          _ => 'O host rejeitou este grito. O jogo segue.',
        },
        'Voltar à cartela',
      ),
    };
    return ScrimOverlay(
      child: DialogCard(
        semanticLabel: 'Resultado do seu BINGO',
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TokenBox(
                size: 150,
                color: color,
                child: kind == ClaimOverlayKind.waiting
                    ? LoadingDots(
                        color: fg,
                        dotSize: 18,
                        semanticLabel: 'Aguardando o host',
                      )
                    : Text(icon, style: AppText.display(iconSize, color: fg)),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.display(40, color: titleColor),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppText.body(18, height: 1.5),
                ),
              ),
              if (btn != null) ...[
                const SizedBox(height: 20),
                AppButton(label: btn, height: 56, onPressed: onClose),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 09c – prize delivered, "AGORA VALE".
class PrizeDeliveredOverlay extends StatelessWidget {
  const PrizeDeliveredOverlay({
    required this.delivered,
    required this.game,
    required this.players,
    required this.claims,
    required this.onClose,
    super.key,
  });

  final DeliveredPrize delivered;
  final Game game;
  final List<Player> players;
  final List<Claim> claims;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final names = [
      for (final w in delivered.winners) playerName(players, w.uid),
    ];
    final who = names.isEmpty ? 'Alguém' : names.join(' e ');
    final verb = names.length > 1 ? 'levaram' : 'levou';
    // Live open prizes, not a single "next" snapshot.
    final open = game.openPrizes;
    final underdog = delivered.prize.pattern == PatternKind.underdog;
    return ScrimOverlay(
      color: const Color(0xBF204A77),
      child: DialogCard(
        semanticLabel: 'Prêmio entregue',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              underdog ? 'TEMOS UM AZARÃO' : 'PRÊMIO ENTREGUE',
              style: AppText.kicker(),
            ),
            const SizedBox(height: 16),
            Text(
              '$who $verb:\n${delivered.prize.label}',
              textAlign: TextAlign.center,
              style: AppText.display(34, color: AppColors.navy),
            ),
            const SizedBox(height: 16),
            _MatchedLine(game: game, delivered: delivered, claims: claims),
            if (open.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionCard(
                radius: 20,
                color: AppColors.blueSoft,
                padding: const EdgeInsets.all(18),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        open.length > 1
                            ? 'CONTINUAM VALENDO'
                            : underdog
                            ? 'CONTINUA VALENDO'
                            : 'AGORA VALE',
                        style: AppText.kicker(),
                      ),
                      // Every prize open right now (e.g. Horizontal + Vertical).
                      for (final p in open) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${p.label} · ${modalityName(p)}',
                          textAlign: TextAlign.center,
                          style: AppText.display(26, color: AppColors.navy),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        open.length > 1
                            ? 'Seus carimbos continuam valendo. Vale qualquer um deles.'
                            : 'Seus carimbos continuam valendo. Vale ${modalityHint(open.first.pattern)}.',
                        textAlign: TextAlign.center,
                        style: AppText.body(14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(label: 'Bora', height: 56, onPressed: onClose),
          ],
        ),
      ),
    );
  }
}

class _MatchedLine extends StatelessWidget {
  const _MatchedLine({
    required this.game,
    required this.delivered,
    required this.claims,
  });

  final Game game;
  final DeliveredPrize delivered;
  final List<Claim> claims;

  @override
  Widget build(BuildContext context) {
    // Only the prize modality, never the list of every closed pattern.
    return Text(
      modalityName(delivered.prize),
      textAlign: TextAlign.center,
      style: AppText.body(16),
    );
  }
}

/// 09d – host offline banner.
class HostOfflineBanner extends StatelessWidget {
  const HostOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
    top: 84,
    left: 16,
    right: 16,
    child: Center(
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.graphite,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: AppText.body(15, color: AppColors.white),
                      children: const [
                        TextSpan(
                          text: 'Host desconectado.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' Aguardando ele voltar. Sua cartela e seus carimbos estão salvos.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 09e – "como jogar" side panel.
class HelpSidePanel extends StatelessWidget {
  const HelpSidePanel({required this.game, required this.onClose, super.key});

  final Game game;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final current = game.currentPrize;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: const ColoredBox(color: Color(0x99424041)),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: width < 520 ? width : 460,
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              label: 'Como jogar',
              child: Material(
                color: AppColors.white,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: SplitTitle('como', 'jogar', size: 28),
                            ),
                            Semantics(
                              button: true,
                              label: 'Fechar',
                              child: ExcludeSemantics(
                                child: Material(
                                  color: AppColors.light,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: onClose,
                                    child: const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Icon(Icons.close),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const HowToPlayPanel(compact: true),
                        if (current != null) ...[
                          const SizedBox(height: 18),
                          SectionCard(
                            radius: 18,
                            color: AppColors.blueSoft,
                            padding: const EdgeInsets.all(16),
                            child: Text.rich(
                              TextSpan(
                                style: AppText.body(14, height: 1.5),
                                children: [
                                  const TextSpan(text: 'Valendo agora: '),
                                  TextSpan(
                                    text:
                                        '${current.label} · ${modalityName(current)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '. Vale ${modalityHint(current.pattern)}.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
