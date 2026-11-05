import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';

/// Simple color picker: palette swatches + hex field. Returns `#rrggbb`.
Future<String?> showColorPickerDialog(
  BuildContext context, {
  required String initial,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ColorPickerDialog(initial: initial),
);

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});

  final String initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  static const palette = [
    '#779ccf',
    '#4f86c6',
    '#204a77',
    '#1868a1',
    '#09b5f0',
    '#4ec45f',
    '#2e8a3e',
    '#c679cc',
    '#914ec4',
    '#424041',
    '#e6e9e9',
    '#f2b134',
    '#e8684a',
    '#d94f70',
    '#1a2b40',
    '#ffffff',
  ];

  late final _ctrl = TextEditingController(text: widget.initial.toLowerCase());

  static final _hex = RegExp(r'^#?([0-9a-fA-F]{6})$');

  String? get _value {
    final m = _hex.firstMatch(_ctrl.text.trim());
    return m == null ? null : '#${m.group(1)!.toLowerCase()}';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _value;
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        'Cor da coluna',
        style: AppText.body(18, weight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in palette)
                  Semantics(
                    button: true,
                    selected: v == hex,
                    label: 'Cor $hex',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _ctrl.text = hex),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.parseHex(hex),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: v == hex ? AppColors.navy : AppColors.light,
                            width: v == hex ? 3 : 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: v == null ? AppColors.white : AppColors.parseHex(v),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.light, width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    label: 'Cor em hexadecimal',
                    textField: true,
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (_) => setState(() {}),
                      style: AppText.body(15, color: AppColors.graphite),
                      decoration: InputDecoration(
                        hintText: '#779ccf',
                        errorText: v == null ? 'Use o formato #rrggbb' : null,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancelar',
          kind: AppButtonKind.outline,
          height: 44,
          fontSize: 14,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Usar cor',
          height: 44,
          fontSize: 14,
          onPressed: v == null ? null : () => Navigator.of(context).pop(v),
        ),
      ],
    );
  }
}
