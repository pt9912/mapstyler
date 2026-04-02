import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints Well-Known-Name marker shapes on a canvas.
///
/// Supported shapes: `circle`, `square`, `triangle`, `star`, `cross`, `x`,
/// and `diamond`. Unknown names fall back to a circle.
class MarkPainter extends CustomPainter {
  /// Creates a painter for a single Well-Known-Name marker shape.
  const MarkPainter({
    required this.wellKnownName,
    required this.color,
    this.strokeColor,
    this.strokeWidth = 1.0,
  });

  /// Name of the symbol shape to paint.
  final String wellKnownName;

  /// Fill color of the marker.
  final Color color;

  /// Optional outline color.
  final Color? strokeColor;

  /// Outline width used when [strokeColor] is set.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor ?? const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    switch (wellKnownName) {
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), r, fillPaint);
        if (strokeColor != null) {
          canvas.drawCircle(Offset(cx, cy), r, strokePaint);
        }

      case 'square':
        final rect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: r * 2,
          height: r * 2,
        );
        canvas.drawRect(rect, fillPaint);
        if (strokeColor != null) canvas.drawRect(rect, strokePaint);

      case 'diamond':
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
        canvas.drawPath(path, fillPaint);
        if (strokeColor != null) canvas.drawPath(path, strokePaint);

      case 'triangle':
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r)
          ..lineTo(cx - r, cy + r)
          ..close();
        canvas.drawPath(path, fillPaint);
        if (strokeColor != null) canvas.drawPath(path, strokePaint);

      case 'star':
        _drawStar(canvas, cx, cy, r, fillPaint, strokePaint);

      case 'cross':
        final w = r * 0.3;
        final path = Path()
          ..moveTo(cx - w, cy - r)
          ..lineTo(cx + w, cy - r)
          ..lineTo(cx + w, cy - w)
          ..lineTo(cx + r, cy - w)
          ..lineTo(cx + r, cy + w)
          ..lineTo(cx + w, cy + w)
          ..lineTo(cx + w, cy + r)
          ..lineTo(cx - w, cy + r)
          ..lineTo(cx - w, cy + w)
          ..lineTo(cx - r, cy + w)
          ..lineTo(cx - r, cy - w)
          ..lineTo(cx - w, cy - w)
          ..close();
        canvas.drawPath(path, fillPaint);
        if (strokeColor != null) canvas.drawPath(path, strokePaint);

      case 'x':
        final w = r * 0.25;
        strokePaint
          ..strokeWidth = w * 2
          ..strokeCap = StrokeCap.butt;
        final p1 = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 2
          ..strokeCap = StrokeCap.butt;
        canvas.drawLine(Offset(cx - r, cy - r), Offset(cx + r, cy + r), p1);
        canvas.drawLine(Offset(cx + r, cy - r), Offset(cx - r, cy + r), p1);
        if (strokeColor != null) {
          strokePaint.strokeWidth = strokeWidth;
        }

      default:
        // Fallback keeps unsupported names renderable without failing the map.
        canvas.drawCircle(Offset(cx, cy), r, fillPaint);
        if (strokeColor != null) {
          canvas.drawCircle(Offset(cx, cy), r, strokePaint);
        }
    }
  }

  /// Paints a five-pointed star centered in the marker bounds.
  void _drawStar(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path();
    const points = 5;
    final innerR = r * 0.4;
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final rad = i.isEven ? r : innerR;
      final x = cx + rad * math.cos(angle);
      final y = cy + rad * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    if (strokeColor != null) canvas.drawPath(path, stroke);
  }

  /// Repaints whenever one of the visual marker parameters changes.
  @override
  bool shouldRepaint(MarkPainter oldDelegate) =>
      wellKnownName != oldDelegate.wellKnownName ||
      color != oldDelegate.color ||
      strokeColor != oldDelegate.strokeColor ||
      strokeWidth != oldDelegate.strokeWidth;
}
