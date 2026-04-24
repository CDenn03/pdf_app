import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/utils/coordinate_mapper.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

/// Captures annotation gestures on top of the PDF viewer.
///
/// Has two modes:
/// - Normal mode: all gestures pass through to [SfPdfViewer] for scroll/zoom.
/// - Annotation mode: drag creates a highlight, tap creates a note,
///   long-press opens the bookmark menu.
///
/// Toggle annotation mode via the [annotating] flag, controlled by
/// [ReaderPage] through the toolbar button.
class GestureHandler extends ConsumerStatefulWidget {
  const GestureHandler({
    super.key,
    required this.pageSize,
    required this.currentPage,
    required this.pdfId,
    required this.annotating,
  });

  final Size pageSize;
  final int currentPage;
  final String pdfId;

  /// When true, gestures are consumed for annotation.
  /// When false, gestures pass through to the PDF viewer.
  final bool annotating;

  @override
  ConsumerState<GestureHandler> createState() => _GestureHandlerState();
}

class _GestureHandlerState extends ConsumerState<GestureHandler> {
  Offset? _dragStart;
  Offset? _dragCurrent;

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
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
            );
      }
    }

    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  Future<void> _onTap(TapUpDetails details) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(),
    );

    if (text != null && text.isNotEmpty) {
      const anchorSize = 24.0;
      final absoluteRect = Rect.fromCenter(
        center: details.localPosition,
        width: anchorSize,
        height: anchorSize,
      );
      ref
          .read(annotationNotifierProvider.notifier)
          .addNote(
            rect: toRelative(absoluteRect, widget.pageSize),
            text: text,
            page: widget.currentPage,
          );
    }
  }

  Future<void> _onLongPress(LongPressStartDetails details) async {
    final pos = details.globalPosition;
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
      items: const [
        PopupMenuItem(value: 'bookmark', child: Text('Add Bookmark')),
      ],
    );

    if (value == 'bookmark') {
      ref
          .read(annotationNotifierProvider.notifier)
          .addBookmark(page: widget.currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // In normal mode, let all gestures pass through to SfPdfViewer.
    if (!widget.annotating) return const SizedBox.expand();

    return GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      onTapUp: _onTap,
      onLongPressStart: _onLongPress,
      child: CustomPaint(
        painter: _DragPreviewPainter(
          dragStart: _dragStart,
          dragCurrent: _dragCurrent,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Dialog for entering note text.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Note'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter note text'),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Paints a semi-transparent preview rectangle during a drag gesture.
class _DragPreviewPainter extends CustomPainter {
  const _DragPreviewPainter({this.dragStart, this.dragCurrent});

  final Offset? dragStart;
  final Offset? dragCurrent;

  @override
  void paint(Canvas canvas, Size size) {
    if (dragStart == null || dragCurrent == null) return;
    canvas.drawRect(
      Rect.fromPoints(dragStart!, dragCurrent!),
      Paint()
        ..color = Colors.yellow.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _DragPreviewPainter old) =>
      old.dragStart != dragStart || old.dragCurrent != dragCurrent;
}
