import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:sefer/core/models/annotation.dart' as app;
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import 'package:sefer/features/reader/presentation/gesture_handler.dart';
import 'package:sefer/features/reader/presentation/highlight_painter.dart';
import 'package:sefer/features/reader/presentation/reader_sheets.dart';
import 'package:sefer/features/reader/state/providers.dart';

class DocumentLoadingOverlay extends StatelessWidget {
  const DocumentLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black54,
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

/// Tap target aligned with the note tab drawn by the highlight painter.
class NoteTapTarget extends StatelessWidget {
  const NoteTapTarget({
    super.key,
    required this.annotation,
    required this.pageSize,
  });

  final app.Annotation annotation;
  final Size pageSize;

  @override
  Widget build(BuildContext context) {
    final pos = annotation.rects.first;
    final isLeftEdge = pos.left < 0.5;
    const tabWidth = 20.0;
    const tabHeight = 28.0;
    final verticalCenter = pos.top * pageSize.height;

    return Positioned(
      left: isLeftEdge ? 0.0 : null,
      right: isLeftEdge ? null : 0.0,
      top: (verticalCenter - tabHeight / 2).clamp(0.0, double.infinity),
      child: GestureDetector(
        onTap: () => _showNoteSheet(context),
        behavior: HitTestBehavior.opaque,
        child: const SizedBox(width: tabWidth, height: tabHeight),
      ),
    );
  }

  void _showNoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => NoteMarkerSheet(annotation: annotation),
    );
  }
}

class BookmarkTapTarget extends StatelessWidget {
  const BookmarkTapTarget({
    super.key,
    required this.annotation,
    required this.index,
  });

  final app.Annotation annotation;
  final int index;

  static const _ribbonW = 24.0;
  static const _ribbonH = 40.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 4.0 + index * (_ribbonW + 4),
      top: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showDrawer(context),
        child: const SizedBox(width: _ribbonW, height: _ribbonH),
      ),
    );
  }

  void _showDrawer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => BookmarkSheet(annotation: annotation),
    );
  }
}

/// Per-page annotation layer: highlights, the active-tool gesture handler,
/// and tap targets for notes and bookmarks.
class ReaderPageOverlay extends ConsumerWidget {
  const ReaderPageOverlay({
    super.key,
    required this.pageRectInViewer,
    required this.page,
    required this.annotating,
    required this.pdfId,
    required this.activeTool,
    required this.sfDocument,
    required this.onAddBookmark,
  });

  final Rect pageRectInViewer;
  final PdfPage page;
  final bool annotating;
  final String pdfId;
  final AnnotationTool activeTool;
  final sf_pdf.PdfDocument? sfDocument;
  final Future<void> Function() onAddBookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageSize = pageRectInViewer.size;
    final pageNumber = page.pageNumber;
    final pdfPageSize = Size(page.width, page.height);

    final annotations = ref
        .watch(annotationNotifierProvider.select((m) => m[pageNumber] ?? []))
        .where((a) => !a.isDeleted)
        .toList();

    final notes = annotations
        .where((a) => a.type == AnnotationType.note && a.rects.isNotEmpty)
        .toList();

    final bookmarks = annotations
        .where((a) => a.type == AnnotationType.bookmark)
        .toList();

    return SizedBox(
      width: pageSize.width,
      height: pageSize.height,
      child: Stack(
        children: [
          if (annotations.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HighlightPainter(
                    annotations: annotations,
                    pageSize: pageSize,
                  ),
                ),
              ),
            ),

          if (annotating)
            Positioned.fill(
              child: GestureHandler(
                pageSize: pageSize,
                currentPage: pageNumber,
                pdfId: pdfId,
                activeTool: activeTool,
                pdfPageSize: pdfPageSize,
                sfDocument: sfDocument,
                onAddBookmark: onAddBookmark,
              ),
            ),

          // Note tap targets must sit above GestureHandler so existing note
          // badges intercept taps before the gesture handler does.
          for (final note in notes)
            NoteTapTarget(annotation: note, pageSize: pageSize),

          for (final (i, bm) in bookmarks.indexed)
            BookmarkTapTarget(annotation: bm, index: i),
        ],
      ),
    );
  }
}
