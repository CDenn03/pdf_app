import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sefer/features/reader/domain/reader_page_text.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';
import 'package:sefer/features/reader/domain/reader_text_selection.dart';
import 'package:sefer/features/reader/domain/selected_text_sharer.dart';
import 'package:sefer/features/reader/presentation/reader_page_geometry.dart';
import 'package:sefer/features/reader/presentation/reader_text_selection_controller.dart';
import 'package:sefer/features/reader/presentation/selection_handle.dart';
import 'package:sefer/features/reader/presentation/selection_highlight_painter.dart';
import 'package:sefer/features/reader/presentation/selection_toolbar.dart';

/// Long-press text selection for one page, placed over [geometry]'s rendered
/// rect. Selection only begins on a long press so horizontal swipes keep
/// turning pages.
class PageTextSelectionLayer extends StatefulWidget {
  const PageTextSelectionLayer({
    super.key,
    required this.geometry,
    required this.source,
    required this.controller,
    required this.enabled,
    required this.sharer,
    required this.highlightColor,
    required this.handleColor,
  });

  final ReaderPageGeometry geometry;
  final ReaderPageTextSource source;
  final ReaderTextSelectionController controller;
  final bool enabled;
  final SelectedTextSharer sharer;
  final Color highlightColor;
  final Color handleColor;

  @override
  State<PageTextSelectionLayer> createState() => _PageTextSelectionLayerState();
}

class _PageTextSelectionLayerState extends State<PageTextSelectionLayer> {
  static const _pressTolerance = 0.04;

  ReaderPageText? _text;
  ReaderTextSelection? _pressedWord;
  _HandleDrag? _handleDrag;

  int get _pageNumber => widget.geometry.pageNumber;
  Size get _size => widget.geometry.renderedRect.size;
  ReaderTextSelectionController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(_loadText());
  }

  @override
  void didUpdateWidget(PageTextSelectionLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) unawaited(_loadText());
  }

  Future<void> _loadText() async {
    try {
      final text = await widget.source.textOn(_pageNumber);
      if (mounted) setState(() => _text = text);
    } catch (error, stack) {
      developer.log(
        'Loading text on page $_pageNumber failed',
        name: 'sefer.reader',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
    }
  }

  Offset _localOf(Offset global) =>
      (context.findRenderObject()! as RenderBox).globalToLocal(global);

  Offset _normalized(Offset local) =>
      Offset(local.dx / _size.width, local.dy / _size.height);

  void _onLongPressStart(LongPressStartDetails details) {
    final text = _text;
    if (text == null) return;
    final index = text.characterNear(
      _normalized(details.localPosition),
      maxDistance: _pressTolerance,
    );
    final word = index == null ? null : text.wordAt(index);
    if (word == null) return;
    _pressedWord = word;
    _controller.dragging.value = true;
    _controller.select(_pageNumber, word);
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    final word = _pressedWord;
    final index = _text?.characterNear(_normalized(details.localPosition));
    if (word == null || index == null) return;
    _controller.select(_pageNumber, word.extendedTo(index));
  }

  void _endLongPress() {
    if (_pressedWord == null) return;
    _pressedWord = null;
    _controller.dragging.value = false;
  }

  void _startHandleDrag({
    required int fixedIndex,
    required Offset anchor,
    required double lineHeight,
    required Offset global,
  }) {
    _handleDrag = _HandleDrag(
      fixedIndex: fixedIndex,
      grabOffset: _localOf(global) - anchor,
      lineHeight: lineHeight,
    );
  }

  void _updateHandleDrag(Offset global) {
    final drag = _handleDrag;
    if (drag == null) return;
    final target = _localOf(global) - drag.grabOffset;
    final index = _text?.characterNear(
      _normalized(target.translate(0, -drag.lineHeight / 2)),
    );
    if (index == null) return;
    _controller.select(
      _pageNumber,
      ReaderTextSelection.between(drag.fixedIndex, index),
    );
  }

  Future<void> _copy(String selectedText) async {
    try {
      await Clipboard.setData(ClipboardData(text: selectedText));
    } catch (error, stack) {
      developer.log(
        'Copying selected text failed',
        name: 'sefer.reader',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
    }
    _controller.clear();
  }

  void _share(String selectedText) {
    unawaited(widget.sharer.share(selectedText));
    _controller.clear();
  }

  Rect _toPixels(Rect fraction) => Rect.fromLTRB(
    fraction.left * _size.width,
    fraction.top * _size.height,
    fraction.right * _size.width,
    fraction.bottom * _size.height,
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final text = _text;
        final selection = _controller.selectionOn(_pageNumber);
        final lines = text == null || selection == null
            ? const <Rect>[]
            : text.lineBoundsOf(selection);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: _onLongPressStart,
                onLongPressMoveUpdate: _onLongPressMove,
                onLongPressEnd: (_) => _endLongPress(),
                onLongPressCancel: _endLongPress,
                child: CustomPaint(
                  painter: SelectionHighlightPainter(
                    lineBounds: lines,
                    color: widget.highlightColor,
                  ),
                ),
              ),
            ),
            if (text != null && selection != null && lines.isNotEmpty)
              ..._controls(text, selection, lines),
          ],
        );
      },
    );
  }

  List<Widget> _controls(
    ReaderPageText text,
    ReaderTextSelection selection,
    List<Rect> lines,
  ) {
    final first = _toPixels(lines.first);
    final last = _toPixels(lines.last);
    final selectedText = text.textOf(selection);
    return [
      SelectionHandle(
        anchor: first.bottomLeft,
        layerSize: _size,
        color: widget.handleColor,
        dragging: _controller.dragging,
        onDragStart: (global) => _startHandleDrag(
          fixedIndex: selection.lastIndex,
          anchor: first.bottomLeft,
          lineHeight: first.height,
          global: global,
        ),
        onDragUpdate: _updateHandleDrag,
      ),
      SelectionHandle(
        anchor: last.bottomRight,
        layerSize: _size,
        color: widget.handleColor,
        dragging: _controller.dragging,
        onDragStart: (global) => _startHandleDrag(
          fixedIndex: selection.start,
          anchor: last.bottomRight,
          lineHeight: last.height,
          global: global,
        ),
        onDragUpdate: _updateHandleDrag,
      ),
      Positioned.fill(
        child: ValueListenableBuilder<bool>(
          valueListenable: _controller.dragging,
          builder: (context, dragging, _) => dragging
              ? const SizedBox.shrink()
              : SelectionToolbar(
                  selectionBounds: lines
                      .map(_toPixels)
                      .reduce((a, b) => a.expandToInclude(b)),
                  onCopy: () => unawaited(_copy(selectedText)),
                  onShare: () => _share(selectedText),
                ),
        ),
      ),
    ];
  }
}

class _HandleDrag {
  const _HandleDrag({
    required this.fixedIndex,
    required this.grabOffset,
    required this.lineHeight,
  });

  final int fixedIndex;
  final Offset grabOffset;
  final double lineHeight;
}
