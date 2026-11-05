import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';

/// Loading motion of the "token arredondado" language (§8). Every widget here
/// honours `MediaQuery.disableAnimations`: motion becomes a gentle fade.

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// A repeating 0→1 animation shared by the loaders below.
mixin _Looping<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  Duration get period;

  late final AnimationController loop = AnimationController(
    vsync: this,
    duration: period,
  )..repeat();

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

/// Three mini tokens hopping in sequence (the "…" of a pending action).
class LoadingDots extends StatefulWidget {
  const LoadingDots({
    super.key,
    this.color = AppColors.white,
    this.dotSize = 14,
    this.gap,
    this.semanticLabel = 'Carregando',
  });

  final Color color;
  final double dotSize;
  final double? gap;
  final String semanticLabel;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin, _Looping<LoadingDots> {
  @override
  Duration get period => const Duration(milliseconds: 1200);

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    final s = widget.dotSize;
    final gap = widget.gap ?? s * .45;
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: loop,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: gap),
                _dot(i, s, reduce),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int i, double s, bool reduce) {
    // Each dot is offset by a third of the cycle.
    final t = (loop.value - i * .16) % 1.0;
    // Hop during the first 40% of its phase, rest otherwise.
    final hop = t < .4 ? math.sin(t / .4 * math.pi) : 0.0;
    final opacity = .45 + .55 * hop;
    final box = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(s * .3),
      ),
    );
    if (reduce) return Opacity(opacity: opacity, child: box);
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, -hop * s * .7),
        child: Transform.rotate(
          angle: (hop * 18 - 8) * math.pi / 180,
          child: box,
        ),
      ),
    );
  }
}

/// Text whose trailing "…" (or "...") is animated: ".", "..", "...".
/// Without a trailing ellipsis it is a plain [Text]. The dots keep a fixed
/// width so the layout never jumps.
class EllipsisText extends StatefulWidget {
  const EllipsisText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  static String? _base(String t) {
    if (t.endsWith('…')) return t.substring(0, t.length - 1);
    if (t.endsWith('...')) return t.substring(0, t.length - 3);
    return null;
  }

  @override
  State<EllipsisText> createState() => _EllipsisTextState();
}

class _EllipsisTextState extends State<EllipsisText>
    with SingleTickerProviderStateMixin, _Looping<EllipsisText> {
  @override
  Duration get period => const Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    final base = EllipsisText._base(widget.text);
    if (base == null) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final reduce = _reduceMotion(context);
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            text: base,
            style: style,
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: AnimatedBuilder(
                  animation: loop,
                  builder: (context, _) {
                    // 0..3 dots; with reduced motion, all three pulse.
                    final n = reduce ? 3 : (loop.value * 4).floor().clamp(0, 3);
                    final fade = reduce
                        ? .4 +
                              .6 *
                                  (0.5 +
                                      0.5 * math.sin(loop.value * 2 * math.pi))
                        : 1.0;
                    return Stack(
                      children: [
                        Text(
                          '...',
                          style: style.copyWith(color: Colors.transparent),
                        ),
                        Opacity(
                          opacity: fade,
                          child: Text('.' * n, style: style),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        ),
      ),
    );
  }
}

/// Full loader between screens: the tilted token rocks and breathes with the
/// hopping dots inside.
class TokenLoader extends StatefulWidget {
  const TokenLoader({
    super.key,
    this.size = 96,
    this.color = AppColors.primary,
    this.dotColor = AppColors.white,
    this.label,
    this.labelColor = AppColors.navy,
  });

  final double size;
  final Color color;
  final Color dotColor;

  /// Optional caption under the token (e.g. "Entrando na sala…").
  final String? label;
  final Color labelColor;

  @override
  State<TokenLoader> createState() => _TokenLoaderState();
}

class _TokenLoaderState extends State<TokenLoader>
    with SingleTickerProviderStateMixin, _Looping<TokenLoader> {
  @override
  Duration get period => const Duration(milliseconds: 1600);

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    final token = TokenBox(
      size: widget.size,
      color: widget.color,
      child: LoadingDots(color: widget.dotColor, dotSize: widget.size * .12),
    );
    final label = widget.label;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: loop,
          child: token,
          builder: (context, child) {
            final wave = math.sin(loop.value * 2 * math.pi);
            if (reduce) {
              return Opacity(opacity: .75 + .25 * wave, child: child);
            }
            // Rocks between -8° and +8° around the resting tilt, and breathes.
            return Transform.rotate(
              angle: wave * 8 * math.pi / 180,
              child: Transform.scale(scale: 1 + .05 * wave, child: child),
            );
          },
        ),
        if (label != null) ...[
          SizedBox(height: widget.size * .3),
          EllipsisText(
            label,
            textAlign: TextAlign.center,
            style: AppText.body(
              16,
              weight: FontWeight.w700,
              color: widget.labelColor,
            ),
          ),
        ],
      ],
    );
  }
}
