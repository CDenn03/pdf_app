import 'package:flutter/material.dart';

import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/core/utils/coordinate_mapper.dart';

/// A [CustomPainter] that renders highlight overlays on top of a PDF page.
///
/// All highlight positions are stored as [RelativeRectModel] (0.0–1.0) and
/// converted to absolute pixel positions using the rendered [pageSize].
///
/// This painter should be wrapped in [IgnorePointer] so gestures pass through
/// to the PDF viewer beneath.
class HighlightPainter extends CustomPainter {
  final List<RelativeRectModel> highlights;
  final Size pageSize;

  HighlightPainter({required this.highlights, required this.pageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (final highlight in highlights) {
      final rect = toAbsolute(highlight, pageSize);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) {
    return oldDelegate.highlights != highlights ||
        oldDelegate.pageSize != pageSize;
  }
}
