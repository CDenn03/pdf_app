import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/data/book_page_image_repository.dart';
import 'package:sefer/features/reader/data/page_rasterizer.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';
import 'package:sefer/features/reader/domain/reader_search_backend.dart';
import 'package:sefer/features/reader/presentation/book_flip_controller.dart';
import 'package:sefer/features/reader/presentation/book_flip_page_navigation.dart';
import 'package:sefer/features/reader/presentation/book_flip_stage.dart';
import 'package:sefer/features/reader/presentation/book_page_images.dart';
import 'package:sefer/features/reader/presentation/reader_page_cell.dart';
import 'package:sefer/features/reader/presentation/reader_text_selection_controller.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';

/// A loaded document shown one page at a time, turned like a book page.
/// Publishes its page navigation and search backend while mounted and
/// reports readiness once. The rasterizer is read once: give a reader for a
/// different document a different key.
class BookFlipDocumentReader extends StatefulWidget {
  const BookFlipDocumentReader({
    super.key,
    required this.config,
    required this.totalPages,
    required this.pageSizeOf,
    required this.rasterOf,
    required this.rasterizer,
    required this.searchBackend,
    required this.linkSource,
    required this.textSource,
    required this.onReady,
  });

  final ReaderViewportConfig config;
  final int totalPages;
  final Size Function(int pageNumber) pageSizeOf;
  final Widget Function(int pageNumber) rasterOf;
  final PageRasterizer rasterizer;
  final ReaderSearchBackend searchBackend;
  final ReaderPageLinkSource linkSource;
  final ReaderPageTextSource textSource;
  final VoidCallback onReady;

  @override
  State<BookFlipDocumentReader> createState() => _BookFlipDocumentReaderState();
}

class _BookFlipDocumentReaderState extends State<BookFlipDocumentReader>
    with TickerProviderStateMixin {
  final ReaderTextSelectionController _selection =
      ReaderTextSelectionController();
  late final BookFlipController _controller;
  late final BookPageImages _images;
  Size? _viewport;

  ReaderViewportConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _controller = BookFlipController(
      vsync: this,
      totalPages: widget.totalPages,
      initialPage: _config.initialPage,
      onPageChanged: _onPageChanged,
    )..addListener(_clearSelectionWhileTurning);
    _images = BookPageImages(
      repository: BookPageImageRepository(rasterizer: widget.rasterizer),
      totalPages: widget.totalPages,
      pageSizeOf: widget.pageSizeOf,
    );
    _config.navigation.attach(
      this,
      BookFlipPageNavigation(
        controller: _controller,
        totalPages: widget.totalPages,
      ),
    );
    _config.searchBackend.attach(this, widget.searchBackend);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.textDirection = Directionality.of(context);
  }

  @override
  void didUpdateWidget(BookFlipDocumentReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.annotating) _selection.clear();
  }

  @override
  void dispose() {
    _config.searchBackend.detach(this);
    _config.navigation.detach(this);
    _controller.dispose();
    _images.dispose();
    _selection.dispose();
    super.dispose();
  }

  void _clearSelectionWhileTurning() {
    if (_controller.isTurning) _selection.clear();
  }

  void _onPageChanged(int pageNumber) {
    if (!mounted) return;
    _selection.clear();
    _config.onPageChanged(pageNumber);
  }

  void _onTap() {
    if (!mounted || _controller.isTurning || _selection.clear()) return;
    _config.onGeneralTap();
  }

  BookFlipTurnView? _turnView() {
    final direction = _controller.direction;
    if (direction == null) return null;
    return BookFlipTurnView(
      direction: direction,
      textDirection: _controller.textDirection,
      pose: _controller.pose!,
      image: _images.imageOf(_controller.currentPage),
    );
  }

  Rect _pageRect(Size viewport) {
    final page = _controller.currentPage;
    return ReaderPageCell.rectIn(viewport, widget.pageSizeOf(page), page);
  }

  void _cancelDragOnResize(Size viewport) {
    final changed = _viewport != null && _viewport != viewport;
    _viewport = viewport;
    if (!changed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.dragCancel();
    });
  }

  Widget _pageCell(BuildContext context, int pageNumber) => ReaderPageCell(
    pageNumber: pageNumber,
    pageSize: widget.pageSizeOf(pageNumber),
    raster: widget.rasterOf(pageNumber),
    config: _config,
    linkSource: widget.linkSource,
    textSource: widget.textSource,
    selection: _selection,
  );

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _cancelDragOnResize(constraints.biggest);
        return ValueListenableBuilder<bool>(
          valueListenable: _selection.dragging,
          builder: (context, selecting, _) => _TurnGestures(
            enabled: !_config.annotating && !selecting,
            controller: _controller,
            pageBounds: () => _pageRect(constraints.biggest),
            onTap: _onTap,
            child: ListenableBuilder(
              listenable: Listenable.merge([_controller, _images]),
              builder: (context, _) {
                final page = _controller.currentPage;
                _images.prepare(
                  page: page,
                  viewport: constraints.biggest,
                  devicePixelRatio: devicePixelRatio,
                );
                return BookFlipStage(
                  currentPage: page,
                  pageRect: _pageRect(constraints.biggest),
                  pageBuilder: _pageCell,
                  contentOpacity: _controller.contentOpacity,
                  edgeStretch: _controller.edgeStretch,
                  turn: _turnView(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TurnGestures extends StatefulWidget {
  const _TurnGestures({
    required this.enabled,
    required this.controller,
    required this.pageBounds,
    required this.onTap,
    required this.child,
  });

  final bool enabled;
  final BookFlipController controller;
  final Rect Function() pageBounds;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TurnGestures> createState() => _TurnGesturesState();
}

class _TurnGesturesState extends State<_TurnGestures> {
  Offset _touchDown = Offset.zero;

  BookFlipController get _controller => widget.controller;

  @override
  void didUpdateWidget(_TurnGestures oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.dragCancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onHorizontalDragDown: enabled
          ? (details) => _touchDown = details.localPosition
          : null,
      onHorizontalDragStart: enabled
          ? (_) => _controller.dragStart(
              position: _touchDown,
              pageBounds: widget.pageBounds(),
            )
          : null,
      onHorizontalDragUpdate: enabled
          ? (details) => _controller.dragUpdate(
              position: details.localPosition,
              delta: details.delta,
            )
          : null,
      onHorizontalDragEnd: enabled
          ? (details) =>
                _controller.dragEnd(velocity: details.velocity.pixelsPerSecond)
          : null,
      onHorizontalDragCancel: enabled ? _controller.dragCancel : null,
      child: widget.child,
    );
  }
}
