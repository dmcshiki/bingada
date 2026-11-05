import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';

/// Entry animation for stream overlays: scale + fade with a little overshoot.
/// With reduced motion it is a plain fade.
class PopIn extends StatelessWidget {
  const PopIn({required this.child, super.key, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final total = delay + Duration(milliseconds: reduce ? 200 : 520);
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) {
        final p = start >= 1 ? 1.0 : ((t - start) / (1 - start)).clamp(0, 1);
        final opacity = p.toDouble().clamp(0.0, 1.0);
        if (reduce) return Opacity(opacity: opacity, child: child);
        final scale = Curves.easeOutBack.transform(p.toDouble()) * .25 + .75;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}

/// One-shot burst of small rounded tokens flying out from the center, in the
/// column colors. Nothing is drawn with reduced motion.
class TokenBurst extends StatefulWidget {
  const TokenBurst({
    super.key,
    this.count = 28,
    this.radius = 420,
    this.delay = Duration.zero,
  });

  final int count;
  final double radius;
  final Duration delay;

  @override
  State<TokenBurst> createState() => _TokenBurstState();
}

class _TokenBurstState extends State<TokenBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    if (widget.delay == Duration.zero) {
      _a.forward();
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _a.forward();
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _a,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _BurstPainter(
              t: _a.value,
              count: widget.count,
              radius: widget.radius,
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({
    required this.t,
    required this.count,
    required this.radius,
  });

  final double t;
  final int count;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final ease = Curves.easeOutCubic.transform(t);
    final fade = t < .6 ? 1.0 : 1 - (t - .6) / .4;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count + (i.isEven ? .12 : -.08);
      final dist = radius * (.55 + ((i * 37) % 45) / 100) * ease;
      final s = 14.0 + (i * 7) % 12;
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * dist;
      final color = AppColors.columns[i % AppColors.columns.length];
      canvas
        ..save()
        ..translate(pos.dx, pos.dy + 80 * t * t)
        ..rotate(angle + t * 4)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s, height: s),
            Radius.circular(s * .28),
          ),
          Paint()..color = color.withValues(alpha: fade),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
