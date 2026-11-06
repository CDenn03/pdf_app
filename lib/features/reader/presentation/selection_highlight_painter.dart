import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Fills each of [lineBounds] (fractions of the painted size) with [color].
class SelectionHighlightPainter extends CustomPainter {
  const SelectionHighlightPainter({
    required this.lineBounds,
    required this.color,
  });

  final List<Rect> lineBounds;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final bounds in lineBounds) {
      canvas.drawRect(
        Rect.fromLTRB(
          bounds.left * size.width,
          bounds.top * size.height,
          bounds.right * size.width,
          bounds.bottom * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SelectionHighlightPainter oldDelegate) =>
      oldDelegate.color != color ||
      !listEquals(oldDelegate.lineBounds, lineBounds);
}
