import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/room/presentation/create/color_picker_dialog.dart';
import 'package:tokingo/features/room/presentation/create/create_room_controller.dart';
import 'package:tokingo/features/room/presentation/create/create_room_page.dart';
import 'package:tokingo/features/room/presentation/create/create_widgets.dart';
import 'package:tokingo/features/room/presentation/room_common.dart';

/// 04 – monte a cartela.
class CardStep extends StatelessWidget {
  const CardStep({
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
    sideWidth: 500,
    main: _Editor(c: c, onBack: onBack, onNext: onNext),
    side: _Preview(c: c),
  );
}

class _Editor extends StatelessWidget {
  const _Editor({required this.c, required this.onBack, required this.onNext});

  final CreateRoomController c;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SplitTitle('monte a', 'cartela'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                'Modelos:',
                style: AppText.body(13, weight: FontWeight.w700),
              ),
            ),
            for (final p in CardPreset.values)
              ChoiceChipButton(
                label: p.label,
                height: 40,
                selected: c.preset == p,
                onTap: () => c.applyPreset(p),
              ),
            for (final t in c.savedTemplates)
              ChoiceChipButton(
                label: t.name,
                height: 40,
                selected: c.preset == null && c.templateName == t.name,
                onTap: () => c.loadTemplate(t),
              ),
            ChoiceChipButton(
              label: 'Importar JSON',
              height: 40,
              selected: false,
              onTap: () => _importJsonDialog(context, c),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            FieldLabel(
              label: 'Tamanho',
              child: DraftDropdown<int>(
                width: 140,
                fontSize: 15,
                semanticsLabel: 'Tamanho',
                value: c.size,
                items: [
                  for (final s in CreateRoomController.sizes) (s, '$s × $s'),
                ],
                onChanged: c.setSize,
              ),
            ),
            FieldLabel(
              label: 'Centro livre',
              child: DraftDropdown<_FreeMode>(
                width: 200,
                fontSize: 15,
                semanticsLabel: 'Centro livre',
                value: !(c.freeEnabled && c.freeAvailable)
                    ? _FreeMode.none
                    : c.freeUseImage
                    ? _FreeMode.image
                    : _FreeMode.text,
                items: [
                  if (c.freeAvailable) (_FreeMode.text, 'Sim · texto “★”'),
                  if (c.freeAvailable) (_FreeMode.image, 'Sim · imagem'),
                  (_FreeMode.none, 'Não'),
                ],
                onChanged: (v) => c.update(() {
                  c.freeEnabled = v != _FreeMode.none;
                  c.freeUseImage = v == _FreeMode.image;
                }),
              ),
            ),
            if (c.freeEnabled && c.freeAvailable && c.freeUseImage)
              FieldLabel(
                label: 'URL da imagem',
                child: SizedBox(
                  width: 280,
                  child: DraftField(
                    initial: c.freeImageUrl,
                    height: 44,
                    hint: 'https://…/logo.png',
                    semanticsLabel: 'URL da imagem do centro livre',
                    keyboardType: TextInputType.url,
                    onChanged: (v) => c.update(() => c.freeImageUrl = v),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _ColumnsTable(c: c),
        const SizedBox(height: 28),
        WizardFooter(
          buttons: [
            AppButton(
              label: 'Voltar',
              onPressed: onBack,
              kind: AppButtonKind.outline,
            ),
            AppButton(
              label: 'Salvar como modelo',
              kind: AppButtonKind.secondary,
              onPressed: () {
                final err = c.saveAsTemplate();
                if (err != null) {
                  showFriendlyError(context, err);
                  return;
                }
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(content: Text('Modelo “${c.templateName}” salvo.')),
                );
              },
            ),
            AppButton(label: 'Próximo: prêmios', onPressed: onNext),
          ],
        ),
      ],
    ),
  );
}

Future<void> _importJsonDialog(
  BuildContext context,
  CreateRoomController c,
) async {
  final ctrl = TextEditingController();
  final raw = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        'Importar JSON',
        style: AppText.body(18, weight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 480,
        child: Semantics(
          label: 'JSON do modelo',
          textField: true,
          child: TextField(
            controller: ctrl,
            maxLines: 12,
            minLines: 8,
            style: AppText.body(13, color: AppColors.graphite),
            decoration: const InputDecoration(
              hintText:
                  '{"name": "…", "headers": [], "colors": [], "columns": []}',
            ),
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancelar',
          kind: AppButtonKind.outline,
          height: 44,
          fontSize: 14,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        AppButton(
          label: 'Importar',
          height: 44,
          fontSize: 14,
          onPressed: () => Navigator.of(ctx).pop(ctrl.text),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (raw == null || raw.trim().isEmpty) return;
  final err = c.importJson(raw);
  if (err != null && context.mounted) showFriendlyError(context, err);
}

enum _FreeMode { text, image, none }

class _ColumnsTable extends StatelessWidget {
  const _ColumnsTable({required this.c});

  final CreateRoomController c;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 560;
      final head = AppText.body(12, weight: FontWeight.w700);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  SizedBox(width: 70, child: Text('Título', style: head)),
                  const SizedBox(width: 10),
                  SizedBox(width: 90, child: Text('Cor', style: head)),
                  const SizedBox(width: 10),
                  SizedBox(width: 150, child: Text('Tipo', style: head)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Conteúdo', style: head)),
                  const SizedBox(width: 10),
                  SizedBox(width: 90, child: Text('Itens', style: head)),
                ],
              ),
            ),
          for (var i = 0; i < c.size; i++) ...[
            const SizedBox(height: 10),
            _ColumnRow(
              key: ValueKey('col-$i-${c.preset}-${c.templateName}'),
              c: c,
              index: i,
              wide: wide,
            ),
          ],
        ],
      );
    },
  );
}

class _ColumnRow extends StatelessWidget {
  const _ColumnRow({
    required this.c,
    required this.index,
    required this.wide,
    super.key,
  });

  final CreateRoomController c;
  final int index;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final col = c.columns[index];
    final ok = c.columnOk(index);
    final title = SizedBox(
      width: 70,
      child: DraftField(
        initial: col.header,
        height: 44,
        center: true,
        semanticsLabel: 'Título da coluna ${index + 1}',
        style: AppText.display(18, color: AppColors.graphite),
        onChanged: (v) => c.update(() => col.header = v),
      ),
    );
    final color = SizedBox(
      width: 90,
      height: 44,
      child: Semantics(
        button: true,
        label: 'Cor da coluna ${index + 1}, tocar para trocar',
        child: Material(
          color: AppColors.parseHex(col.color),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final v = await showColorPickerDialog(
                context,
                initial: col.color,
              );
              if (v != null) c.update(() => col.color = v);
            },
          ),
        ),
      ),
    );
    final type = SizedBox(
      width: 150,
      child: DraftDropdown<ColumnKind>(
        semanticsLabel: 'Tipo',
        value: col.kind,
        items: const [
          (ColumnKind.range, 'Faixa de números'),
          (ColumnKind.items, 'Lista de textos'),
        ],
        onChanged: (v) => c.update(() {
          c.preset = null;
          col.kind = v;
        }),
      ),
    );
    final content = DraftField(
      initial: col.content,
      height: 44,
      hint: col.kind == ColumnKind.range ? '1 – 15' : 'Item 1, Item 2, …',
      semanticsLabel: 'Conteúdo da coluna ${index + 1}',
      style: AppText.body(14, color: AppColors.graphite),
      onChanged: (v) => c.update(() => col.content = v),
    );
    final count = SizedBox(
      width: 90,
      child: Text(
        ok ? '${col.itemCount} ✓' : '${col.itemCount} / ${c.neededFor(index)}',
        style: AppText.body(
          13,
          weight: FontWeight.w700,
          color: ok ? const Color(0xFF2E7D3A) : AppColors.purple,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: wide
            ? Row(
                children: [
                  title,
                  const SizedBox(width: 10),
                  color,
                  const SizedBox(width: 10),
                  type,
                  const SizedBox(width: 10),
                  Expanded(child: content),
                  const SizedBox(width: 10),
                  count,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      title,
                      const SizedBox(width: 10),
                      Expanded(child: color),
                      const SizedBox(width: 10),
                      count,
                    ],
                  ),
                  const SizedBox(height: 8),
                  type,
                  const SizedBox(height: 8),
                  content,
                ],
              ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.c});

  final CreateRoomController c;

  @override
  Widget build(BuildContext context) {
    final t = c.template;
    final card = c.previewCard;
    return SectionCard(
      color: AppColors.navy,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SplitTitle(
            'prévia',
            'aleatória',
            size: 22,
            color: AppColors.white,
          ),
          const SizedBox(height: 16),
          SectionCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: t == null || card == null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      c.cardError ?? '',
                      textAlign: TextAlign.center,
                      style: AppText.body(14),
                    ),
                  )
                : BingoGrid(
                    headers: t.headers,
                    headerColors: [
                      for (final h in t.colors) AppColors.parseHex(h),
                    ],
                    cols: t.cols,
                    gap: 8,
                    cellFontSize: 20,
                    cellRadius: 12,
                    headerHeight: 40,
                    cells: [
                      for (final id in card.cells)
                        GridCell(
                          label: id == null ? t.free.label : t.item(id).label,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: t == null ? null : c.reshufflePreview,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: AppText.body(14, weight: FontWeight.w700),
              ),
              child: const Text('Gerar outra prévia'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cada coluna precisa de pelo menos ${c.size} itens. A cartela de cada jogador sai da seed (conta + jogo + salt) e pode ser auditada.',
            style: AppText.body(13, color: AppColors.white, height: 1.5),
          ),
        ],
      ),
    );
  }
}
