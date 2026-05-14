import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/utils/coordinate_mapper.dart';
import 'package:pdf_app/features/reader/presentation/annotation_toolbar.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

/// Captures annotation gestures on top of the PDF viewer.
///
/// Behavior depends on [activeTool]:
/// - [AnnotationTool.highlight]: drag creates a highlight
/// - [AnnotationTool.note]: tap opens an inline bottom-sheet note input
/// - [AnnotationTool.bookmark]: tap creates a bookmark
///
/// Only inserted into the widget tree when annotation mode is active,
/// eliminating gesture disambiguation overhead during normal reading.
class GestureHandler extends ConsumerStatefulWidget {
  const GestureHandler({
    super.key,
    required this.pageSize,
    required this.currentPage,
    required this.pdfId,
    required this.activeTool,
  });

  final Size pageSize;
  final int currentPage;
  final String pdfId;
  final AnnotationTool activeTool;

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
        ref
            .read(annotationNotifierProvider.notifier)
            .addHighlight(
              rect: toRelative(rect, widget.pageSize),
              page: widget.currentPage,
              color: _activeColor,
            );
      }
    }

    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  Future<void> _onTap(TapUpDetails details) async {
    switch (widget.activeTool) {
      case AnnotationTool.highlight:
        break; // Handled by drag.
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
    ref
        .read(annotationNotifierProvider.notifier)
        .addNote(
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

  /// Shows a bottom-sheet note input instead of a modal dialog.
  ///
  /// Bottom sheet keeps the document visible and feels less disruptive
  /// than a full modal dialog.
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
// Note input bottom sheet
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
