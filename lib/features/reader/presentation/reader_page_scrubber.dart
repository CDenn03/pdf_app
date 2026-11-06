import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/domain/page_range.dart';

const double kScrubberGutterWidth = 24;
const Duration kScrubberRequestInterval = Duration(milliseconds: 80);

class ReaderPageScrubber extends StatefulWidget {
  const ReaderPageScrubber({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageRequested,
    required this.readingMode,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageRequested;
  final ReadingMode readingMode;

  @override
  State<ReaderPageScrubber> createState() => _ReaderPageScrubberState();
}

class _ReaderPageScrubberState extends State<ReaderPageScrubber> {
  static const _thumbHeight = 48.0;

  Timer? _cooldown;
  int? _previewPage;
  int? _lastRequestedPage;
  int? _pendingPage;
  double _dragTop = 0;

  PageRange get _range => PageRange(widget.totalPages);
  bool get _dragging => _previewPage != null;
  int get _shownPage => _range.clamp(_previewPage ?? widget.currentPage);

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  double _topForPage(int page, double maxTop) =>
      (page - 1) / (widget.totalPages - 1) * maxTop;

  int _pageForTop(double top, double maxTop) =>
      _range.clamp((top / maxTop * (widget.totalPages - 1)).round() + 1);

  void _onDragStart(double maxTop) {
    _dragTop = _topForPage(_range.clamp(widget.currentPage), maxTop);
    _lastRequestedPage = null;
    _pendingPage = null;
    setState(() => _previewPage = _range.clamp(widget.currentPage));
  }

  void _onDragUpdate(double deltaY, double maxTop) {
    _dragTop = (_dragTop + deltaY).clamp(0.0, maxTop);
    final page = _pageForTop(_dragTop, maxTop);
    if (page == _previewPage) return;
    setState(() => _previewPage = page);
    _requestThrottled(page);
  }

  void _requestThrottled(int page) {
    if (_cooldown?.isActive ?? false) {
      _pendingPage = page;
      return;
    }
    _request(page);
  }

  void _request(int page) {
    _pendingPage = null;
    if (page == _lastRequestedPage) return;
    _lastRequestedPage = page;
    widget.onPageRequested(page);
    _cooldown = Timer(kScrubberRequestInterval, _onCooldownElapsed);
  }

  void _onCooldownElapsed() {
    final pending = _pendingPage;
    if (pending != null) _request(pending);
  }

  void _onDragEnd() {
    final finalPage = _previewPage;
    _cooldown?.cancel();
    _pendingPage = null;
    if (finalPage != null && finalPage != _lastRequestedPage) {
      _lastRequestedPage = finalPage;
      widget.onPageRequested(finalPage);
    }
    setState(() => _previewPage = null);
  }

  void _onDragCancel() {
    _cooldown?.cancel();
    _pendingPage = null;
    setState(() => _previewPage = null);
  }

  String _pageLabel(int page) => 'Page $page of ${widget.totalPages}';

  void _step(int delta) =>
      widget.onPageRequested(_range.clamp(widget.currentPage + delta));

  @override
  Widget build(BuildContext context) {
    if (widget.totalPages <= 1) return const SizedBox.shrink();
    final mode = widget.readingMode;
    final label = _pageLabel(_shownPage);

    return SizedBox(
      width: kScrubberGutterWidth,
      child: Semantics(
        slider: true,
        label: 'Page scrubber',
        value: label,
        increasedValue: _pageLabel(_range.clamp(widget.currentPage + 1)),
        decreasedValue: _pageLabel(_range.clamp(widget.currentPage - 1)),
        onIncrease: () => _step(1),
        onDecrease: () => _step(-1),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxTop = (constraints.maxHeight - _thumbHeight).clamp(
              1.0,
              double.infinity,
            );
            final top = _topForPage(_shownPage, maxTop);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _Rail(color: mode.primaryText.withValues(alpha: 0.28)),
                Positioned(
                  top: top,
                  right: 0,
                  width: kScrubberGutterWidth,
                  height: _thumbHeight,
                  child: GestureDetector(
                    key: const ValueKey('page-scrubber-thumb'),
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) => _onDragStart(maxTop),
                    onVerticalDragUpdate: (d) =>
                        _onDragUpdate(d.delta.dy, maxTop),
                    onVerticalDragEnd: (_) => _onDragEnd(),
                    onVerticalDragCancel: _onDragCancel,
                    child: _Thumb(mode: mode, expanded: _dragging),
                  ),
                ),
                if (_dragging)
                  Positioned(
                    top: top + (_thumbHeight - 32) / 2,
                    right: kScrubberGutterWidth + 4,
                    child: _PageBubble(mode: mode, text: '$_shownPage'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
    right: 4,
    top: 0,
    bottom: 0,
    width: 3,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.mode, required this.expanded});

  final ReadingMode mode;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.only(right: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: expanded ? 10 : 7,
        decoration: BoxDecoration(
          color: mode.primaryText.withValues(alpha: expanded ? 0.85 : 0.6),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: mode.background.withValues(alpha: 0.6)),
        ),
      ),
    ),
  );
}

class _PageBubble extends StatelessWidget {
  const _PageBubble({required this.mode, required this.text});

  final ReadingMode mode;
  final String text;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: mode.controlSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mode.primaryText.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: mode.primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
