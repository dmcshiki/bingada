import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/room/presentation/create/create_room_controller.dart';
import 'package:tokingo/features/room/presentation/create/create_room_page.dart';
import 'package:tokingo/features/room/presentation/create/create_widgets.dart';

/// 06 – regras da casa + revisão final.
class ReviewStep extends StatelessWidget {
  const ReviewStep({
    required this.c,
    required this.onBack,
    required this.onSubmit,
    super.key,
  });

  final CreateRoomController c;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  static const List<(TieBreakRule, String)> _tieItems = [
    (TieBreakRule.draw, 'Sorteio entre os empatados'),
    (TieBreakRule.fewestPrizes, 'Quem tem menos prêmios leva'),
  ];

  static const _penaltyOptions = [1, 2, 3, 5];

  @override
  Widget build(BuildContext context) => WizardColumns(
    sideWidth: 520,
    main: SectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                style: AppText.body(30, weight: FontWeight.w300),
                children: const [
                  TextSpan(
                    text: 'regras',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' da casa'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _RuleRow(
            title: 'Host também joga',
            desc: 'Você recebe uma cartela e ocupa 1 das 60 vagas.',
            control: DraftDropdown<bool>(
              semanticsLabel: 'Host também joga',
              value: c.hostPlays,
              items: const [(true, 'Sim'), (false, 'Não')],
              onChanged: (v) => c.update(() => c.hostPlays = v),
            ),
          ),
          _RuleRow(
            title: 'Penalidade por comer bola',
            desc: c.penaltyDraws == 0
                ? 'Por enquanto o grito errado só não vale e o jogo segue.'
                : 'Quem gritar errado fica ${c.penaltyDraws} ${c.penaltyDraws == 1 ? 'bola' : 'bolas'} sem poder gritar.',
            control: DraftDropdown<int>(
              semanticsLabel: 'Penalidade por comer bola',
              value: c.penaltyDraws,
              items: [
                (0, 'Nenhuma'),
                for (final n in _penaltyOptions)
                  (n, 'Pular $n ${n == 1 ? 'bola' : 'bolas'}'),
              ],
              onChanged: (v) => c.update(() => c.penaltyDraws = v),
            ),
          ),
          _RuleRow(
            title: 'Mostrar “comeu bola” na transmissão',
            desc: 'A vergonha pública opcional.',
            control: DraftDropdown<bool>(
              semanticsLabel: 'Mostrar comeu bola na transmissão',
              value: c.showFailsOnStream,
              items: const [(true, 'Mostrar'), (false, 'Esconder')],
              onChanged: (v) => c.update(() => c.showFailsOnStream = v),
            ),
          ),
          _RuleRow(
            title: 'Empate no mesmo prêmio',
            desc:
                'Dois ou mais gritos válidos na mesma bola. Só uma pessoa leva; '
                'em "menos prêmios", se ainda empatar, há sorteio.',
            control: DraftDropdown<TieBreakRule>(
              semanticsLabel: 'Empate no mesmo prêmio',
              value: c.tieBreak,
              items: _tieItems,
              onChanged: (v) => c.update(() => c.tieBreak = v),
            ),
          ),
          if (c.underdog)
            _RuleRow(
              title: 'Desempate do azarão',
              desc:
                  'Os últimos que sobraram saíram na mesma bola. Só uma pessoa '
                  'leva; em "menos prêmios", se ainda empatar, há sorteio.',
              control: DraftDropdown<TieBreakRule>(
                semanticsLabel: 'Desempate do azarão',
                value: c.underdogTie,
                items: _tieItems,
                onChanged: (v) => c.update(() => c.underdogTie = v),
              ),
            ),
          const SizedBox(height: 28),
          WizardFooter(
            buttons: [
              AppButton(
                label: 'Voltar',
                onPressed: c.busy ? null : onBack,
                kind: AppButtonKind.outline,
              ),
              AppButton(
                label: c.busy ? 'Criando…' : 'Criar sala e abrir espera',
                onPressed: c.busy ? null : onSubmit,
              ),
            ],
          ),
        ],
      ),
    ),
    side: SectionCard(
      color: AppColors.navy,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SplitTitle(
            'revisão',
            'final',
            size: 24,
            color: AppColors.white,
          ),
          const SizedBox(height: 14),
          _SummaryItem(k: 'EVENTO', v: '${c.eventName} · até 60 jogadores'),
          _SummaryItem(k: 'ACESSO', v: c.accessSummary),
          _SummaryItem(k: 'CARTELA', v: c.cardSummary),
          _SummaryItem(k: 'PRÊMIOS', v: c.prizesSummary),
          _SummaryItem(
            k: 'AZARÃO',
            v: c.underdog
                ? 'Prêmio azarão (por eliminação, durante o jogo)'
                : 'Sem prêmio azarão',
          ),
          Text(
            'Ao criar, geramos o salt da sala e publicamos o commit do sorteio. Acesso, cartela e prêmios ficam travados quando você começar o jogo.',
            style: AppText.body(13, color: AppColors.white, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.title,
    required this.desc,
    required this.control,
  });

  final String title;
  final String desc;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.body(16, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(desc, style: AppText.body(13)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth < 480
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [text, const SizedBox(height: 10), control],
                  )
                : Row(
                    children: [
                      Expanded(child: text),
                      const SizedBox(width: 18),
                      SizedBox(width: 210, child: control),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.k, required this.v});

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              k,
              style: AppText.body(
                12,
                weight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              v,
              style: AppText.body(15, color: AppColors.white, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );
}
