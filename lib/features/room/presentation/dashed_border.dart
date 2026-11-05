import 'package:flutter/material.dart';

/// Rounded dashed border (CSS `border: 2px dashed`), local to the room feature.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    required this.child,
    required this.color,
    super.key,
    this.radius = 16,
    this.width = 2,
    this.dash = 6,
    this.gap = 4,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double width;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: DashedBorderPainter(
      color: color,
      radius: radius,
      strokeWidth: width,
      dash: dash,
      gap: gap,
    ),
    child: child,
  );
}

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.radius = 16,
    this.strokeWidth = 2,
    this.dash = 6,
    this.gap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular((radius - inset).clamp(0, double.infinity)),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = (d + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}
