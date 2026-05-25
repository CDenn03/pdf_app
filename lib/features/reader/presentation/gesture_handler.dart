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
    this.pdfPageSize = Size.zero,
    this.sfDocument,
  });

  final Size pageSize;
  final Size pdfPageSize;
  final int currentPage;
  final String pdfId;
  final AnnotationTool activeTool;
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
      final rect = Rect.fromPoints(start, end);
      if (rect.width > 10 && rect.height > 4) {
        final relRect = toRelative(rect, widget.pageSize);
        final selectedText = _extractText(relRect);
        ref.read(annotationNotifierProvider.notifier).addHighlight(
          rect: relRect,
          page: widget.currentPage,
          color: _activeColor,
          selectedText: selectedText,
        );
      }
    }

    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  /// Extracts the text words that overlap [relRect] using Syncfusion's
  /// PdfTextExtractor.
  ///
  /// [relRect] is in normalized [0,1] coords relative to the rendered page.
  /// We convert it to PDF user-space by multiplying by [pdfPageSize].
  ///
  /// Returns null silently if the document has no extractable text (scanned
  /// or image-only PDF), or if extraction throws for any reason.
  String? _extractText(RelativeRectModel relRect) {
    final doc = widget.sfDocument;
    if (doc == null) return null;

    final pdf = widget.pdfPageSize;
    if (pdf == Size.zero) return null;

    final pdfLeft = relRect.left * pdf.width;
    final pdfTop = relRect.top * pdf.height;
    final pdfRight = relRect.right * pdf.width;
    final pdfBottom = relRect.bottom * pdf.height;

    try {
      final extractor = PdfTextExtractor(doc);
      final lines = extractor.extractTextLines(
        startPageIndex: widget.currentPage - 1,
        endPageIndex: widget.currentPage - 1,
      );

      final words = <String>[];
      for (final line in lines) {
        for (final word in line.wordCollection) {
          final b = word.bounds;
          final overlaps = b.left < pdfRight &&
              b.left + b.width > pdfLeft &&
              b.top < pdfBottom &&
              b.top + b.height > pdfTop;
          if (overlaps) words.add(word.text);
        }
      }
      return words.isEmpty ? null : words.join(' ');
    } catch (e, s) {
      developer.log(
        'Text extraction failed on page ${widget.currentPage}',
        name: 'pdf_app.gesture',
        level: 500,
        error: e,
        stackTrace: s,
      );
      return null;
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

    const anchorSize = 24.0;
    final absoluteRect = Rect.fromCenter(
      center: position,
      width: anchorSize,
      height: anchorSize,
    );
    ref.read(annotationNotifierProvider.notifier).addNote(
      rect: toRelative(absoluteRect, widget.pageSize),
      text: text,
      page: widget.currentPage,
      color: _activeColor,
    );
  }

  void _addBookmark() {
    ref
        .read(annotationNotifierProvider.notifier)
        .addBookmark(page: widget.currentPage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark added on page ${widget.currentPage}'),
        duration: const Duration(seconds: 2),
      ),
    );
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
