import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';

/// Labeled field (13px bold label above the input).
class FieldLabel extends StatelessWidget {
  const FieldLabel({
    required this.label,
    required this.child,
    super.key,
    this.size = 13,
    this.gap = 6,
  });

  final String label;
  final Widget child;
  final double size;
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppText.body(size, weight: FontWeight.w700)),
      SizedBox(height: gap),
      child,
    ],
  );
}

/// Text input with the canvas styling, keeping its own controller.
class DraftField extends StatefulWidget {
  const DraftField({
    required this.initial,
    required this.onChanged,
    super.key,
    this.semanticsLabel,
    this.height = 48,
    this.center = false,
    this.style,
    this.keyboardType,
    this.enabled = true,
    this.hint,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final String? semanticsLabel;
  final double height;
  final bool center;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? hint;

  @override
  State<DraftField> createState() => _DraftFieldState();
}

class _DraftFieldState extends State<DraftField> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(DraftField old) {
    super.didUpdateWidget(old);
    if (widget.initial != _ctrl.text && widget.initial != old.initial) {
      _ctrl.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    textField: true,
    child: SizedBox(
      height: widget.height,
      child: TextField(
        controller: _ctrl,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        textAlign: widget.center ? TextAlign.center : TextAlign.start,
        style: widget.style ?? AppText.body(15, color: AppColors.graphite),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppText.body(15, color: const Color(0xFF8A8889)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: (widget.height - 22) / 2,
          ),
          isDense: true,
        ),
      ),
    ),
  );
}

/// Canvas-styled dropdown.
class DraftDropdown<T> extends StatelessWidget {
  const DraftDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.semanticsLabel,
    super.key,
    this.width,
    this.fontSize = 14,
  });

  final double fontSize;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  final String semanticsLabel;
  final double? width;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    child: Container(
      width: width,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.light, width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: AppText.body(fontSize, color: AppColors.graphite),
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final (v, l) in items)
              DropdownMenuItem(
                value: v,
                child: Text(l, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    ),
  );
}

/// Rounded chip button (presets, options).
class ChoiceChipButton extends StatelessWidget {
  const ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.height = 44,
    this.expand = false,
    this.radius = 20,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double height;
  final bool expand;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final child = Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.navy : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: selected
              ? BorderSide.none
              : const BorderSide(color: AppColors.light, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: expand ? Alignment.center : null,
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.body(
                  13,
                  weight: FontWeight.w700,
                  color: selected ? AppColors.white : AppColors.graphite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return child;
  }
}
