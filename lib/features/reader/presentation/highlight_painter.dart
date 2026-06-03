import 'package:flutter/material.dart';

import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/utils/coordinate_mapper.dart';

/// Renders annotation overlays on top of a PDF page.
///
/// [pageSize] MUST be the rendered page size on screen (from LayoutBuilder),
/// not the PDF logical page size in user-space points.
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
    final paint = Paint()
      ..color = annotation.color.overlay
      ..style = PaintingStyle.fill;

    for (final rect in annotation.rects) {
      canvas.drawRect(toAbsolute(rect, pageSize), paint);
    }
  }

  void _paintNote(Canvas canvas, Annotation annotation) {
    if (annotation.rects.isEmpty) return;

    final pos = annotation.rects.first;
    // left == 0.0 → left edge, left == 1.0 → right edge.
    final isLeftEdge = pos.left < 0.5;
    final verticalCenter = pos.top * pageSize.height;

    const tabWidth = 20.0;
    const tabHeight = 28.0;
    const cornerRadius = Radius.circular(4);

    // Tab protrudes inward from the edge.
    final tabRect = isLeftEdge
        ? Rect.fromLTWH(0, verticalCenter - tabHeight / 2, tabWidth, tabHeight)
        : Rect.fromLTWH(
            pageSize.width - tabWidth,
            verticalCenter - tabHeight / 2,
            tabWidth,
            tabHeight,
          );

    final rrect = isLeftEdge
        ? RRect.fromRectAndCorners(
            tabRect,
            topRight: cornerRadius,
            bottomRight: cornerRadius,
          )
        : RRect.fromRectAndCorners(
            tabRect,
            topLeft: cornerRadius,
            bottomLeft: cornerRadius,
          );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = annotation.color.solid
        ..style = PaintingStyle.fill,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: '✎',
        style: TextStyle(fontSize: 13, color: Colors.white, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        tabRect.center.dx - tp.width / 2,
        tabRect.center.dy - tp.height / 2,
      ),
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
