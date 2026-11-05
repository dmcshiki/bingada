import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';

/// One step of "Como jogar" (§5.2, R22).
class HowToStep {
  const HowToStep(this.n, this.title, this.text, this.color);

  final String n;
  final String title;
  final String text;
  final Color color;

  static const all = [
    HowToStep(
      '1',
      'Entre e pegue sua cartela',
      'Entre com sua conta e o código da sala. Você recebe uma cartela única, que é a mesma em qualquer dispositivo.',
      AppColors.primary,
    ),
    HowToStep(
      '2',
      'Fique de olho nas bolas',
      'O host sorteia e mostra cada bola na tela de transmissão. Elas também aparecem no topo da sua tela.',
      AppColors.cyan,
    ),
    HowToStep(
      '3',
      'Carimbe você mesmo',
      'Saiu um número da sua cartela? Toque nele. O app não marca nada sozinho e não avisa: a atenção é sua.',
      AppColors.green,
    ),
    HowToStep(
      '4',
      'Fechou? BINGO!',
      'Completou a modalidade que está valendo? Aperte BINGO. O host confere na hora. Se você marcou um número que não saiu, comeu bola!',
      AppColors.purple,
    ),
  ];
}

/// "Como jogar": 4 tabbed steps + modalities (01–01d). [compact] renders a
/// vertical list for the in-game side sheet (09e).
class HowToPlayPanel extends StatefulWidget {
  const HowToPlayPanel({
    super.key,
    this.compact = false,
    this.initialStep = 0,
    this.showTitle = true,
  });

  final bool compact;

  /// False when the host container already shows "como jogar".
  final bool showTitle;
  final int initialStep;

  @override
  State<HowToPlayPanel> createState() => _HowToPlayPanelState();
}

class _HowToPlayPanelState extends State<HowToPlayPanel> {
  late int _i = widget.initialStep.clamp(0, 3);

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTitle) ...[
            const SplitTitle('como', 'jogar', size: 26),
            const SizedBox(height: 16),
          ],
          for (final s in HowToStep.all) ...[
            _CompactStep(step: s),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          const _Modalities(),
        ],
      );
    }
    final step = HowToStep.all[_i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SplitTitle('como', 'jogar', size: 34),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (k, s) in HowToStep.all.indexed)
              _StepTab(
                label: 'Passo ${s.n}',
                selected: k == _i,
                onTap: () => setState(() => _i = k),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _StepCard(step: step),
        const SizedBox(height: 22),
        const _Modalities(),
      ],
    );
  }
}

class _StepTab extends StatelessWidget {
  const _StepTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? AppColors.navy : AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppText.body(
                14,
                weight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.graphite,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final HowToStep step;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final narrow = c.maxWidth < 560;
      final token = TokenBox(
        size: narrow ? 120 : 200,
        color: step.color,
        child: Text(
          step.n,
          style: AppText.display(narrow ? 44 : 72, color: AppColors.white),
        ),
      );
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(step.title, style: AppText.display(28, color: AppColors.navy)),
          const SizedBox(height: 12),
          Text(step.text, style: AppText.body(18, height: 1.5)),
        ],
      );
      return SectionCard(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 236),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [token, const SizedBox(height: 24), text],
                )
              : Row(
                  children: [
                    SizedBox(width: 220, child: Center(child: token)),
                    const SizedBox(width: 32),
                    Expanded(child: text),
                  ],
                ),
        ),
      );
    },
  );
}

class _CompactStep extends StatelessWidget {
  const _CompactStep({required this.step});

  final HowToStep step;

  @override
  Widget build(BuildContext context) => SectionCard(
    radius: 20,
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TokenBox(
          size: 48,
          color: step.color,
          child: Text(
            step.n,
            style: AppText.display(20, color: AppColors.white),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: AppText.display(17, color: AppColors.navy),
              ),
              const SizedBox(height: 4),
              Text(step.text, style: AppText.body(14, height: 1.45)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Modalities extends StatelessWidget {
  const _Modalities();

  static const _items = [
    ('Horizontal', ': uma linha'),
    ('Vertical', ': uma coluna'),
    ('Diagonal', ''),
    ('Cartela cheia', ': tudo'),
    ('Azarão', ': o último a não ter nenhuma bola sorteada'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Modalidades que podem valer',
        style: AppText.body(14, weight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final (b, rest) in _items)
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text.rich(
                  TextSpan(
                    style: AppText.body(13, color: AppColors.graphite),
                    children: [
                      TextSpan(
                        text: b,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: rest),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

/// Opens [HowToPlayPanel] (compact) in a right side sheet.
Future<void> showHowToPlaySheet(BuildContext context) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar como jogar',
      pageBuilder: (context, _, _) => const _HowToSheet(),
      transitionBuilder: (context, anim, _, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
        child: child,
      ),
    );

class _HowToSheet extends StatelessWidget {
  const _HowToSheet();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.light,
        child: SizedBox(
          width: w < 480 ? w : 440,
          height: double.infinity,
          child: SafeArea(
            child: Stack(
              children: [
                const SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: HowToPlayPanel(compact: true),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    tooltip: 'Fechar',
                    iconSize: 24,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
