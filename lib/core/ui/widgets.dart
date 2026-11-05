import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/loading.dart';

/// The "token": rounded square tilted -8° (§8). Content is counter-rotated.
class TokenBox extends StatelessWidget {
  const TokenBox({
    required this.size,
    required this.color,
    super.key,
    this.child,
    this.radiusFactor = 0.26,
    this.shadow = false,
  });

  final double size;
  final Color color;
  final Widget? child;
  final double radiusFactor;
  final bool shadow;

  static const double tilt = -8 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * radiusFactor),
          boxShadow: shadow
              ? const [
                  BoxShadow(
                    color: Color(0x40204A77),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: child == null
            ? null
            : Transform.rotate(angle: -tilt, child: child),
      ),
    );
  }
}

/// Avatar made of a token with initials.
class AvatarToken extends StatelessWidget {
  const AvatarToken({
    required this.initials,
    required this.size,
    super.key,
    this.color = AppColors.navy,
  });

  final String initials;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => TokenBox(
    size: size,
    color: color,
    radiusFactor: 0.28,
    child: Text(
      initials,
      style: AppText.display(size * 0.34, color: AppColors.onColor(color)),
    ),
  );
}

/// Big decorative tilted shape used on backgrounds. Purely decorative.
class BlobShape extends StatelessWidget {
  const BlobShape({required this.size, required this.color, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Transform.rotate(
      angle: TokenBox.tilt,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * .25),
        ),
      ),
    ),
  );
}

enum AppButtonKind { primary, secondary, outline, light, danger }

/// Rounded button used across the canvas (52–76px tall).
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.kind = AppButtonKind.primary,
    this.height = 52,
    this.expand = false,
    this.icon,
    this.displayFont = false,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final double height;
  final bool expand;
  final IconData? icon;
  final bool displayFont;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      AppButtonKind.primary => (AppColors.navy, AppColors.white, null),
      AppButtonKind.secondary => (
        AppColors.white,
        AppColors.navy,
        AppColors.navy,
      ),
      AppButtonKind.outline => (
        AppColors.white,
        AppColors.graphite,
        AppColors.graphite,
      ),
      AppButtonKind.light => (AppColors.white, AppColors.navy, null),
      AppButtonKind.danger => (AppColors.purple, AppColors.white, null),
    };
    final disabled = onPressed == null;
    final style = displayFont
        ? AppText.display(
            fontSize ?? 22,
            color: disabled ? const Color(0xFF6B6869) : fg,
          )
        : AppText.body(
            fontSize ?? 15,
            weight: FontWeight.w700,
            color: disabled ? const Color(0xFF6B6869) : fg,
          );
    final button = Material(
      color: disabled ? AppColors.light : bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(height * .32),
        side: border == null || disabled
            ? BorderSide.none
            : BorderSide(color: border, width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(height * .32),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: style.color, size: 20),
                const SizedBox(width: 10),
              ],
              if (expand)
                Flexible(
                  child: EllipsisText(
                    label,
                    style: style,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                EllipsisText(label, style: style, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// White rounded card section.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(24),
    this.color = AppColors.white,
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// Small rounded label.
class Pill extends StatelessWidget {
  const Pill({
    required this.label,
    super.key,
    this.color = AppColors.white,
    this.textColor,
    this.bold = false,
  });

  final String label;
  final Color color;
  final Color? textColor;
  final bool bold;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: EllipsisText(
        label,
        style: AppText.body(
          14,
          weight: bold ? FontWeight.w700 : FontWeight.w500,
          color: textColor ?? AppColors.graphite,
        ),
      ),
    ),
  );
}

/// Title in the canvas style: light word + **bold** word ("sala de **espera**").
class SplitTitle extends StatelessWidget {
  const SplitTitle(
    this.light,
    this.bold, {
    super.key,
    this.size = 30,
    this.color,
  });

  final String light;
  final String bold;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: light.isEmpty ? '' : '$light ',
            style: AppText.body(size, weight: FontWeight.w300, color: color),
          ),
          TextSpan(
            text: bold,
            style: AppText.body(size, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    ),
  );
}

/// "tokingo" wordmark (Days One). No third-party marks (R12).
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26, this.color = AppColors.navy});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tokingo',
    child: ExcludeSemantics(
      child: Text('tokingo', style: AppText.display(size, color: color)),
    ),
  );
}

/// Data for one cell of [BingoGrid].
class GridCell {
  const GridCell({
    required this.label,
    this.background = AppColors.white,
    this.foreground = AppColors.graphite,
    this.border = const BorderSide(color: AppColors.light, width: 2),
    this.stamped = false,
    this.stampRotation = 0,
    this.semanticsLabel,
    this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final BorderSide border;
  final bool stamped;

  /// Degrees, -10..10.
  final double stampRotation;
  final String? semanticsLabel;
  final VoidCallback? onTap;
}

/// The bingo card: colored header pills + square cells (§8 Componentes).
class BingoGrid extends StatelessWidget {
  const BingoGrid({
    required this.headers,
    required this.headerColors,
    required this.cells,
    required this.cols,
    super.key,
    this.gap = 10,
    this.cellFontSize = 30,
    this.cellRadius = 18,
    this.headerHeight = 52,
  });

  final List<String> headers;
  final List<Color> headerColors;
  final List<GridCell> cells;
  final int cols;
  final double gap;
  final double cellFontSize;
  final double cellRadius;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final rows = (cells.length / cols).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var c = 0; c < cols; c++) ...[
              if (c > 0) SizedBox(width: gap),
              Expanded(
                child: Container(
                  height: headerHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: headerColors[c % headerColors.length],
                    borderRadius: BorderRadius.circular(headerHeight / 2),
                  ),
                  child: Text(
                    headers[c],
                    style: AppText.display(
                      headerHeight * .5,
                      color: AppColors.onColor(
                        headerColors[c % headerColors.length],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: gap),
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) SizedBox(height: gap),
          Row(
            children: [
              for (var c = 0; c < cols; c++) ...[
                if (c > 0) SizedBox(width: gap),
                Expanded(
                  child: _CellView(
                    cell: cells[r * cols + c],
                    fontSize: cellFontSize,
                    radius: cellRadius,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _CellView extends StatelessWidget {
  const _CellView({
    required this.cell,
    required this.fontSize,
    required this.radius,
  });

  final GridCell cell;
  final double fontSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final long = cell.label.length > 4;
    return AspectRatio(
      aspectRatio: 1,
      child: Semantics(
        button: cell.onTap != null,
        label: cell.semanticsLabel ?? cell.label,
        excludeSemantics: true,
        child: Material(
          color: cell.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: cell.border,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: cell.onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (cell.stamped)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Transform.rotate(
                        angle: cell.stampRotation * math.pi / 180,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .88),
                            borderRadius: BorderRadius.circular(radius - 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    cell.label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(
                      long ? fontSize * .38 : fontSize,
                      color: cell.stamped ? AppColors.white : cell.foreground,
                    ),
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

/// Page scaffold with the light background and decorative blobs.
class AppPage extends StatelessWidget {
  const AppPage({
    required this.child,
    super.key,
    this.background = AppColors.light,
    this.blobs = const [],
  });

  final Widget child;
  final Color background;

  /// Decorative blobs positioned relative to the page.
  final List<Positioned> blobs;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    body: Stack(
      children: [
        ...blobs,
        Positioned.fill(child: SafeArea(child: child)),
      ],
    ),
  );
}
