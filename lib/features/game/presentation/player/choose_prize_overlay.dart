import 'package:flutter/material.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/bingo_card.dart';
import 'package:tokingo/features/game/domain/entities/claim.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/game/domain/services/prize_policy_evaluator.dart';
import 'package:tokingo/features/game/presentation/common/game_format.dart';
import 'package:tokingo/features/game/presentation/common/game_widgets.dart';

/// Valid BINGO that would put the player over the room's prize limit: they
/// pick which prize to give up (the new one or one they already hold). Only
/// options that leave a set allowed by the room rules are listed. The prize
/// given up goes to the other tied player (1), is drawn among the other tied
/// players (2+), or goes back into play (no tie).
class ChoosePrizeOverlay extends StatelessWidget {
  const ChoosePrizeOverlay({
    required this.claim,
    required this.game,
    required this.players,
    required this.claims,
    required this.busy,
    required this.onChoose,
    this.onRelease,
    this.onAnswerTie,
    super.key,
  });

  /// Tie while at the limit ([Claim.tieOptIn]): true = join the draw.
  final ValueChanged<bool>? onAnswerTie;

  final Claim claim;
  final Game game;
  final List<Player> players;
  final List<Claim> claims;
  final bool busy;

  /// Legacy answer: keep (give up the new prize) or swap.
  final ValueChanged<ClaimChoice> onChoose;

  /// Gives up this prize. Preferred over [onChoose] when provided (needed to
  /// pick among 2+ held prizes).
  final ValueChanged<PrizeId>? onRelease;

  static const _policy = PrizePolicyEvaluator();

  void _pick(PrizeId id, PrizeId offer) {
    final release = onRelease;
    if (release != null) return release(id);
    onChoose(id == offer ? ClaimChoice.keep : ClaimChoice.swap);
  }

  @override
  Widget build(BuildContext context) {
    if (claim.tieOptIn) return _optIn(context);
    final offerId = claim.offerPrizeId ?? claim.prizeId;
    final held = _policy.heldBy(claim.uid, game.winners, except: offerId);
    var options = _policy.releaseOptions(
      held: held,
      offer: offerId,
      policy: game.prizePolicy,
    );
    if (options.isEmpty) options = [...held, offerId];
    // Without [onRelease] only the new prize and a single held one can be
    // told apart.
    if (onRelease == null && held.length > 1) {
      final firstHeld = options.where((p) => p != offerId).firstOrNull;
      options = [
        for (final o in options)
          if (o == offerId || o == firstHeld) o,
      ];
    }
    final others = [
      for (final c in claims)
        if (c.id != claim.id &&
            c.prizeId == claim.prizeId &&
            c.status == ClaimStatus.tied)
          c,
    ];
    final fate = switch (others.length) {
      0 when game.settings.overLimit == OverLimitRule.raffle =>
        'O prêmio que você não escolher será sorteado entre quem ainda '
            'pode ganhar.',
      0 =>
        'O prêmio que você não escolher volta para o jogo (o azarão é '
            'sorteado entre quem ainda pode ganhar).',
      1 =>
        'O prêmio de que você abrir mão vai para '
            '${playerName(players, others.single.uid)}, que empatou com você.',
      final n =>
        'O prêmio de que você abrir mão será sorteado entre os outros $n '
            'empatados.',
    };
    final limit = game.prizePolicy.maxPerPlayer;
    final rule = limit == null
        ? 'Pela regra da sala, alguns prêmios não podem ficar juntos.'
        : 'Pela regra da sala, cada pessoa fica com no máximo '
              '$limit ${limit == 1 ? 'prêmio' : 'prêmios'}.';
    final offer = prizeById(game, offerId);
    return ScrimOverlay(
      child: DialogCard(
        semanticLabel: 'Escolha de qual prêmio abrir mão',
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TokenBox(
                size: 110,
                color: AppColors.green,
                child: Text(
                  '⇄',
                  style: AppText.display(56, color: AppColors.white),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'VOCÊ GANHOU DE NOVO!',
                textAlign: TextAlign.center,
                style: AppText.display(34, color: const Color(0xFF2E7D3A)),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha com quais prêmios ficar',
                textAlign: TextAlign.center,
                style: AppText.body(20, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Você ganhou ${offer?.label ?? 'um novo prêmio'}. $rule '
                  '$fate',
                  textAlign: TextAlign.center,
                  style: AppText.body(17, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
              if (busy)
                const LoadingDots(
                  color: AppColors.navy,
                  semanticLabel: 'Enviando sua escolha',
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final id in options) ...[
                        _OptionCard(
                          keep: [
                            for (final k in [...held, offerId])
                              if (k != id) prizeById(game, k),
                          ],
                          prize: prizeById(game, id),
                          isNew: id == offerId,
                          onTap: () => _pick(id, offerId),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tie while already at the limit: join the draw or let the others have it.
  Widget _optIn(BuildContext context) {
    final prize = prizeById(game, claim.prizeId);
    final others = [
      for (final c in claims)
        if (c.id != claim.id &&
            c.prizeId == claim.prizeId &&
            c.drawIndex == claim.drawIndex &&
            c.uid != claim.uid &&
            (c.status == ClaimStatus.pending ||
                c.status == ClaimStatus.awaitingChoice))
          playerName(players, c.uid).split(' ').first,
    ];
    final held = _policy.heldBy(claim.uid, game.winners);
    final limit = game.prizePolicy.maxPerPlayer;
    final answer = onAnswerTie;
    return ScrimOverlay(
      child: DialogCard(
        semanticLabel: 'Entrar ou pular o desempate',
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TokenBox(
                size: 110,
                color: AppColors.cyan,
                child: Text(
                  '=',
                  style: AppText.display(56, color: AppColors.white),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'EMPATE NO ${prize?.label.toUpperCase() ?? 'PRÊMIO'}!',
                textAlign: TextAlign.center,
                style: AppText.display(30, color: AppColors.navy),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Você bingou junto com ${others.isEmpty ? 'outra pessoa' : others.join(', ')}. '
                  'Você já tem ${held.length} '
                  '${held.length == 1 ? 'prêmio' : 'prêmios'}'
                  '${limit == null ? '' : ' (o limite da sala é $limit)'}. '
                  'Quer entrar no sorteio? Se ganhar, escolhe com quais prêmios '
                  'fica e o que sobrar vai para quem bingou com você. Se pular, '
                  'o prêmio fica com eles.',
                  textAlign: TextAlign.center,
                  style: AppText.body(17, height: 1.5),
                ),
              ),
              const SizedBox(height: 22),
              if (busy)
                const LoadingDots(
                  color: AppColors.navy,
                  semanticLabel: 'Enviando sua escolha',
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    AppButton(
                      label: 'Pular o sorteio',
                      kind: AppButtonKind.outline,
                      height: 56,
                      onPressed: answer == null ? null : () => answer(false),
                    ),
                    AppButton(
                      label: 'Entrar no sorteio',
                      height: 56,
                      onPressed: answer == null ? null : () => answer(true),
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.keep,
    required this.prize,
    required this.isNew,
    required this.onTap,
  });

  /// Prizes the player ends up with when picking this option.
  final List<Prize?> keep;
  final Prize? prize;
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = prize;
    final label = p?.label ?? 'Prêmio';
    final kept = keep.isEmpty
        ? 'nenhum'
        : keep.map((k) => k?.label ?? 'Prêmio').join(' + ');
    final sub =
        'abre mão de $label'
        '${isNew ? ' (o que acabou de ganhar)' : ''}';
    return Semantics(
      button: true,
      label: 'Ficar com $kept, $sub',
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ficar com: $kept',
                          style: AppText.body(17, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(sub, style: AppText.body(14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('→', style: AppText.body(20, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
