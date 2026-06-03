import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' show PdfDocument, PdfTextExtractor;

import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/core/utils/coordinate_mapper.dart';
import 'package:pdf_app/features/reader/presentation/annotation_toolbar.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

/// Captures annotation gestures on top of a single PDF page overlay.
///
/// Receives [pageSize] from [PdfViewerParams.pageOverlaysBuilder], which
/// provides the exact rendered pixel size of the page — so coordinate
/// math via [toRelative] / [toAbsolute] is correct without any scaling.
///
/// [pdfPageSize] is the PDF logical page size in user-space points (from
/// [PdfPage.width] / [PdfPage.height]). Used only to convert relative coords
/// back to PDF points for [PdfTextExtractor] word-overlap detection.
///
/// [sfDocument] is the syncfusion_flutter_pdf document loaded separately for
/// text extraction. Null for image-only PDFs or before the document loads;
/// in those cases text extraction is skipped gracefully.
class GestureHandler extends ConsumerStatefulWidget {
  const GestureHandler({
    super.key,
    required this.pageSize,
    required this.currentPage,
    required this.pdfId,
    required this.activeTool,
    required this.onAddBookmark,
    this.pdfPageSize = Size.zero,
    this.sfDocument,
  });

  final Size pageSize;
  final Size pdfPageSize;
  final int currentPage;
  final String pdfId;
  final AnnotationTool activeTool;
  final Future<void> Function() onAddBookmark;
  final PdfDocument? sfDocument;

  @override
  ConsumerState<GestureHandler> createState() => _GestureHandlerState();
}

class _GestureHandlerState extends ConsumerState<GestureHandler> {
  Offset? _dragStart;
  Offset? _dragCurrent;

  AnnotationColor get _activeColor => ref.read(activeAnnotationColorProvider);

  void _onDragStart(DragStartDetails details) {
    if (widget.activeTool != AnnotationTool.highlight) return;
    setState(() {
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.activeTool != AnnotationTool.highlight) return;
    setState(() => _dragCurrent = details.localPosition);
  }

  void _onDragEnd(DragEndDetails _) {
    final start = _dragStart;
    final end = _dragCurrent;

    if (start != null && end != null) {
      final dragRect = Rect.fromPoints(start, end);
      if (dragRect.width > 10 && dragRect.height > 4) {
        final (rects, text) = _extractWordRectsAndText(dragRect);
        // Fall back to the drag rect itself when text extraction is unavailable.
        final finalRects = rects.isNotEmpty
            ? rects
            : [toRelative(dragRect, widget.pageSize)];
        ref.read(annotationNotifierProvider.notifier).addHighlight(
          rects: finalRects,
          page: widget.currentPage,
          color: _activeColor,
          selectedText: text,
        );
      }
    }

    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  /// Returns (wordRects, selectedText) for words overlapping [dragRect].
  ///
  /// Word bounds from Syncfusion are in PDF user-space points; we normalise
  /// each to [0,1] relative to [pdfPageSize] so they are renderer-independent.
  /// Falls back to ([], null) for image-only PDFs or on extraction failure.
  (List<RelativeRectModel>, String?) _extractWordRectsAndText(Rect dragRect) {
    final doc = widget.sfDocument;
    if (doc == null) return ([], null);

    final pdf = widget.pdfPageSize;
    if (pdf == Size.zero) return ([], null);

    // Convert screen drag rect to PDF user-space for overlap testing.
    final screenRel = toRelative(dragRect, widget.pageSize);
    final pdfLeft = screenRel.left * pdf.width;
    final pdfTop = screenRel.top * pdf.height;
    final pdfRight = screenRel.right * pdf.width;
    final pdfBottom = screenRel.bottom * pdf.height;

    try {
      final extractor = PdfTextExtractor(doc);
      final lines = extractor.extractTextLines(
        startPageIndex: widget.currentPage - 1,
        endPageIndex: widget.currentPage - 1,
      );

      final rects = <RelativeRectModel>[];
      final words = <String>[];

      for (final line in lines) {
        for (final word in line.wordCollection) {
          final b = word.bounds;
          final overlaps = b.left < pdfRight &&
              b.left + b.width > pdfLeft &&
              b.top < pdfBottom &&
              b.top + b.height > pdfTop;
          if (!overlaps) continue;
          words.add(word.text);
          rects.add(
            RelativeRectModel(
              left: b.left / pdf.width,
              top: b.top / pdf.height,
              right: (b.left + b.width) / pdf.width,
              bottom: (b.top + b.height) / pdf.height,
            ),
          );
        }
      }
      return (rects, words.isEmpty ? null : words.join(' '));
    } catch (e, s) {
      developer.log(
        'Text extraction failed on page ${widget.currentPage}',
        name: 'pdf_app.gesture',
        level: 500,
        error: e,
        stackTrace: s,
      );
      return ([], null);
    }
  }

  Future<void> _onTap(TapUpDetails details) async {
    switch (widget.activeTool) {
      case AnnotationTool.highlight:
        break;
      case AnnotationTool.note:
        await _addNote(details.localPosition);
      case AnnotationTool.bookmark:
        _addBookmark();
    }
  }

  Future<void> _addNote(Offset position) async {
    final text = await _showNoteInput();
    if (text == null || text.isEmpty) return;

    // Determine which edge: left half of page → left edge (left=0.0),
    // right half → right edge (left=1.0). top = vertical fraction.
    final isLeftEdge = position.dx < widget.pageSize.width / 2;
    final edgePosition = RelativeRectModel(
      left: isLeftEdge ? 0.0 : 1.0,
      top: (position.dy / widget.pageSize.height).clamp(0.0, 1.0),
      right: isLeftEdge ? 0.0 : 1.0,
      bottom: (position.dy / widget.pageSize.height).clamp(0.0, 1.0),
    );

    ref.read(annotationNotifierProvider.notifier).addNote(
      edgePosition: edgePosition,
      initialText: text,
      page: widget.currentPage,
      color: _activeColor,
    );
  }

  Future<void> _addBookmark() async {
    await widget.onAddBookmark();
  }

  Future<String?> _showNoteInput() {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _NoteInputSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      onTapUp: _onTap,
      child: CustomPaint(
        painter: _DragPreviewPainter(
          dragStart: _dragStart,
          dragCurrent: _dragCurrent,
          color: _activeColor.overlay,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Note input sheet
// ---------------------------------------------------------------------------

class _NoteInputSheet extends StatefulWidget {
  @override
  State<_NoteInputSheet> createState() => _NoteInputSheetState();
}

class _NoteInputSheetState extends State<_NoteInputSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add note', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write your note…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, _controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drag preview painter
// ---------------------------------------------------------------------------

class _DragPreviewPainter extends CustomPainter {
  const _DragPreviewPainter({
    this.dragStart,
    this.dragCurrent,
    required this.color,
  });

  final Offset? dragStart;
  final Offset? dragCurrent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (dragStart == null || dragCurrent == null) return;
    canvas.drawRect(
      Rect.fromPoints(dragStart!, dragCurrent!),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _DragPreviewPainter old) =>
      old.dragStart != dragStart ||
      old.dragCurrent != dragCurrent ||
      old.color != color;
}
