import 'package:flutter/material.dart';

import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/utils/coordinate_mapper.dart';

/// Renders annotation overlays on top of a PDF page.
///
/// [pageSize] MUST be the rendered page size on screen (from LayoutBuilder),
/// not the PDF logical page size in user-space points. Using the rendered size
/// ensures that highlights are drawn at the correct screen positions.
///
/// Wrapped in [IgnorePointer] so gestures pass through to the viewer.
class HighlightPainter extends CustomPainter {
  final List<Annotation> annotations;
  final Size pageSize;

  HighlightPainter({required this.annotations, required this.pageSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      if (annotation.isDeleted) continue;

      switch (annotation.type) {
        case AnnotationType.highlight:
          _paintHighlight(canvas, annotation);
        case AnnotationType.note:
          _paintNote(canvas, annotation);
        case AnnotationType.bookmark:
          break;
      }
    }
  }

  void _paintHighlight(Canvas canvas, Annotation annotation) {
    final rect = annotation.rect;
    if (rect == null) return;

    final absoluteRect = toAbsolute(rect, pageSize);
    canvas.drawRect(
      absoluteRect,
      Paint()
        ..color = annotation.color.overlay
        ..style = PaintingStyle.fill,
    );
  }

  /// Paints a note as a highlighted text band with a badge icon at its
  /// top-right corner, making notes immediately discoverable while reading.
  void _paintNote(Canvas canvas, Annotation annotation) {
    final rect = annotation.rect;
    if (rect == null) return;

    final absoluteRect = toAbsolute(rect, pageSize);

    // Highlight band behind the note so the user can see what text it covers.
    canvas.drawRect(
      absoluteRect,
      Paint()
        ..color = annotation.color.overlay
        ..style = PaintingStyle.fill,
    );

    // Badge circle at the top-right corner of the highlighted region.
    const badgeRadius = 10.0;
    final badgeCenter = Offset(
      absoluteRect.right - badgeRadius,
      absoluteRect.top + badgeRadius,
    );

    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()
        ..color = annotation.color.solid
        ..style = PaintingStyle.fill,
    );

    // Pencil icon character drawn inside the badge for clarity.
    final tp = TextPainter(
      text: const TextSpan(
        text: '✎',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      badgeCenter - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant HighlightPainter old) {
    if (old.pageSize != pageSize) return true;
    if (old.annotations.length != annotations.length) return true;
    for (var i = 0; i < annotations.length; i++) {
      if (old.annotations[i] != annotations[i]) return true;
    }
    return false;
  }
}
