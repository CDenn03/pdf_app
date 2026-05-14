import 'package:flutter/material.dart';

import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/utils/coordinate_mapper.dart';

/// A [CustomPainter] that renders annotation overlays on top of a PDF page.
///
/// Highlights are rendered as semi-transparent colored rectangles.
/// Note anchors are rendered as small speech-bubble icons so they are
/// visible without obstructing reading.
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
          _paintNoteAnchor(canvas, annotation);
        case AnnotationType.bookmark:
          break; // Bookmarks have no spatial extent.
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

  void _paintNoteAnchor(Canvas canvas, Annotation annotation) {
    final rect = annotation.rect;
    if (rect == null) return;

    // Draw a small filled circle as the note anchor.
    final center = toAbsolute(rect, pageSize).center;
    final paint = Paint()
      ..color = annotation.color.solid
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, paint);

    // White dot in center for contrast.
    canvas.drawCircle(
      center,
      3,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) =>
      oldDelegate.annotations != annotations ||
      oldDelegate.pageSize != pageSize;
}
