import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/entities/game.dart';
import 'package:tokingo/features/game/domain/entities/prize.dart';
import 'package:tokingo/features/room/presentation/create/create_room_controller.dart';
import 'package:tokingo/features/room/presentation/create/create_room_page.dart';
import 'package:tokingo/features/room/presentation/create/create_widgets.dart';
import 'package:tokingo/features/room/presentation/dashed_border.dart';

/// 05 – defina os prêmios + limite (R30) + modalidades.
class PrizesStep extends StatelessWidget {
  const PrizesStep({
    required this.c,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final CreateRoomController c;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => WizardColumns(
    sideWidth: 420,
    gap: 32,
    main: _PrizeList(c: c, onBack: onBack, onNext: onNext),
    side: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LimitCard(c: c),
        const SizedBox(height: 16),
        const _KindsGallery(),
      ],
    ),
  );
}

class _PrizeList extends StatelessWidget {
  const _PrizeList({
    required this.c,
    required this.onBack,
    required this.onNext,
  });

  final CreateRoomController c;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SplitTitle('defina os', 'prêmios'),
        const SizedBox(height: 16),
        Text(
          'Os prêmios de padrão (horizontal, vertical…) valem ao mesmo tempo, e as bolas sorteadas continuam valendo entre um e outro. A cartela cheia vale só depois que todos saírem; o jogo termina quando ela sai.',
          style: AppText.body(14),
        ),
        for (var i = 0; i < c.prizes.length; i++) ...[
          const SizedBox(height: 16),
          _PrizeRow(key: ObjectKey(c.prizes[i]), c: c, index: i),
        ],
        const SizedBox(height: 16),
        _UnderdogRow(c: c),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          excludeSemantics: true,
          label: 'Adicionar prêmio',
          child: DashedBorder(
            color: AppColors.primary,
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: c.addPrize,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '+ Adicionar prêmio',
                      style: AppText.body(
                        15,
                        weight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        WizardFooter(
          buttons: [
            AppButton(
              label: 'Voltar',
              onPressed: onBack,
              kind: AppButtonKind.outline,
            ),
            AppButton(label: 'Próximo: regras', onPressed: onNext),
          ],
        ),
      ],
    ),
  );
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({required this.c, required this.index, super.key});

  final CreateRoomController c;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = c.prizes[index];
    final order = Transform.rotate(
      angle: -8 * math.pi / 180,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${index + 1}',
          style: AppText.display(16, color: AppColors.white),
        ),
      ),
    );
    final label = FieldLabel(
      label: 'Prêmio',
      size: 12,
      gap: 4,
      child: DraftField(
        initial: p.label,
        height: 40,
        semanticsLabel: 'Nome do prêmio ${index + 1}',
        onChanged: (v) => c.update(() => p.label = v),
      ),
    );
    final kind = FieldLabel(
      label: 'Modalidade',
      size: 12,
      gap: 4,
      child: DraftDropdown<PatternKind>(
        fontSize: 15,
        semanticsLabel: 'Modalidade do prêmio ${index + 1}',
        value: p.pattern,
        items: [
          for (final k in CreateRoomController.sequentialKinds) (k, k.label),
        ],
        onChanged: (v) => c.update(() => p.pattern = v),
      ),
    );
    final winners = FieldLabel(
      label: 'Vencedores',
      size: 12,
      gap: 4,
      child: DraftField(
        initial: '${p.winners}',
        height: 40,
        keyboardType: TextInputType.number,
        semanticsLabel: 'Vencedores do prêmio ${index + 1}',
        onChanged: (v) =>
            c.update(() => p.winners = int.tryParse(v.trim()) ?? 0),
      ),
    );
    final remove = Semantics(
      button: true,
      label: 'Remover prêmio ${index + 1}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: c.prizes.length > 1 ? () => c.removePrize(index) : null,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(Icons.close, size: 18, color: AppColors.graphite),
            ),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 600
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: order),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: label),
                    const SizedBox(width: 12),
                    SizedBox(width: 220, child: kind),
                    const SizedBox(width: 12),
                    SizedBox(width: 110, child: winners),
                    const SizedBox(width: 12),
                    remove,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(child: order),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: label),
                        const SizedBox(width: 12),
                        remove,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: kind),
                        const SizedBox(width: 12),
                        SizedBox(width: 110, child: winners),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _UnderdogRow extends StatelessWidget {
  const _UnderdogRow({required this.c});

  final CreateRoomController c;

  @override
  Widget build(BuildContext context) => DashedBorder(
    color: AppColors.pink,
    radius: 18,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 6,
        children: [
          Text(
            'DURANTE O JOGO',
            style: AppText.body(12, weight: FontWeight.w700, letterSpacing: .6),
          ),
          Text.rich(
            TextSpan(
              style: AppText.body(15),
              children: const [
                TextSpan(
                  text: 'Prêmio azarão',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' · a cada bola, sai quem tem o número na cartela (marcou ou não). O último que sobrar leva',
                ),
              ],
            ),
          ),
          MergeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: c.underdog,
                  activeColor: AppColors.navy,
                  onChanged: (v) => c.setUnderdog(v ?? false),
                ),
                Text('ativo', style: AppText.body(13, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({required this.c});

  final CreateRoomController c;

  static String _limitLabel(int? n) => switch (n) {
    null => 'Sem limite',
    1 => '1 prêmio',
    _ => '$n prêmios',
  };

  @override
  Widget build(BuildContext context) {
    final cols = c.matrixCols;
    final bold12 = AppText.body(12, weight: FontWeight.w700);
    return SectionCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SplitTitle('quem já ganhou', 'pode ganhar de novo?', size: 22),
          const SizedBox(height: 14),
          Text('Máximo de prêmios por pessoa', style: bold12),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final (i, n)
                  in CreateRoomController.limitOptions.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChipButton(
                    label: _limitLabel(n),
                    selected: c.maxPerPlayer == n,
                    radius: 14,
                    onTap: () => c.setLimit(n),
                  ),
                ),
              ],
            ],
          ),
          if (c.maxPerPlayer != null) ...[
            const SizedBox(height: 14),
            Text(
              'Se alguém ganhar além do limite, escolhe com quais fica e o '
              'prêmio que sobrar…',
              style: bold12,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChipButton(
                    label: 'volta para o jogo',
                    selected: c.overLimit == OverLimitRule.backToGame,
                    radius: 14,
                    onTap: () => c.setOverLimit(OverLimitRule.backToGame),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChipButton(
                    label: 'é sorteado entre os outros',
                    selected: c.overLimit == OverLimitRule.raffle,
                    radius: 14,
                    onTap: () => c.setOverLimit(OverLimitRule.raffle),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Se outras pessoas bingaram junto, o prêmio vai para elas '
              '(sorteado na tela se forem várias). O azarão é sempre sorteado.',
              style: AppText.body(12, height: 1.4),
            ),
          ],
          if (cols.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Quem ganhou… pode concorrer a:', style: bold12),
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 140),
                for (final t in cols) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Tooltip(
                      message: t,
                      child: Text(
                        t,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: bold12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            for (final r in c.matrixRows) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Tooltip(
                      message: c.rowLabel(r),
                      child: Text(
                        c.rowLabel(r),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(13, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                  for (var k = 0; k < cols.length; k++) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MatrixCell(
                        state: c.cell(r, k),
                        aria: '${c.rowLabel(r)} pode concorrer a ${cols[k]}',
                        onTap: () => c.toggle(r, k),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
          const SizedBox(height: 14),
          Text(
            '${c.limitHelp} Quem não pode mais ganhar continua jogando, mas o BINGO dele fica desativado para aquele prêmio, e ele é ignorado no cálculo do azarão.',
            style: AppText.body(12, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({
    required this.state,
    required this.aria,
    required this.onTap,
  });

  final AllowCell state;
  final String aria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (t, bg, fg, value) = switch (state) {
      AllowCell.notApplicable => (
        '—',
        AppColors.surfaceSoft,
        const Color(0xFF9A9899),
        'não se aplica',
      ),
      AllowCell.allowed => (
        'Pode',
        AppColors.green,
        const Color(0xFF123B19),
        'sim',
      ),
      AllowCell.denied => ('Não', AppColors.light, AppColors.graphite, 'não'),
    };
    final na = state == AllowCell.notApplicable;
    return Semantics(
      button: !na,
      label: '$aria: $value',
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: na ? null : onTap,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                t,
                style: AppText.body(13, weight: FontWeight.w700, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini 5×5 masks for each modality (compact gallery).
class _KindsGallery extends StatelessWidget {
  const _KindsGallery();

  static final _kinds = <(String, bool Function(int, int))>[
    ('Horizontal', (r, c) => r == 1),
    ('Vertical', (r, c) => c == 3),
    ('Diagonal', (r, c) => r == c),
    ('Quatro cantos', (r, c) => (r == 0 || r == 4) && (c == 0 || c == 4)),
    ('X', (r, c) => r == c || r + c == 4),
    ('Moldura', (r, c) => r == 0 || r == 4 || c == 0 || c == 4),
    ('Cartela cheia', (r, c) => true),
    ('Azarão', (r, c) => r == 0 && c == 3),
    ('Customizado', (r, c) => r == 2 || c == 2),
  ];

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('MODALIDADES', style: AppText.body(12, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (n, f) in _kinds)
              SizedBox(
                width: 64,
                child: Semantics(
                  label: 'Modalidade $n',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      _MiniMask(f: f),
                      const SizedBox(height: 4),
                      Text(
                        n,
                        textAlign: TextAlign.center,
                        style: AppText.body(10, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _MiniMask extends StatelessWidget {
  const _MiniMask({required this.f});

  final bool Function(int, int) f;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 46,
    child: Column(
      children: [
        for (var r = 0; r < 5; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Row(
              children: [
                for (var c = 0; c < 5; c++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 1),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: f(r, c)
                                ? AppColors.primary
                                : AppColors.light,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
