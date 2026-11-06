import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/domain/reader_page_link.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';
import 'package:sefer/features/reader/domain/reader_search_backend.dart';
import 'package:sefer/features/reader/presentation/page_controller_navigation.dart';
import 'package:sefer/features/reader/presentation/reader_page_cell.dart';
import 'package:sefer/features/reader/presentation/paged_reader_gallery.dart';
import 'package:sefer/features/reader/presentation/reader_text_selection_controller.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';

/// A loaded document shown one page at a time. Publishes its page navigation
/// and search backend while mounted and reports readiness once.
class PagedDocumentReader extends StatefulWidget {
  const PagedDocumentReader({
    super.key,
    required this.config,
    required this.controller,
    required this.totalPages,
    required this.pageSizeOf,
    required this.rasterOf,
    required this.searchBackend,
    required this.linkSource,
    required this.textSource,
    required this.onReady,
  });

  final ReaderViewportConfig config;
  final PageController controller;
  final int totalPages;
  final Size Function(int pageNumber) pageSizeOf;
  final Widget Function(int pageNumber) rasterOf;
  final ReaderSearchBackend searchBackend;
  final ReaderPageLinkSource linkSource;
  final ReaderPageTextSource textSource;
  final VoidCallback onReady;

  @override
  State<PagedDocumentReader> createState() => _PagedDocumentReaderState();
}

class _PagedDocumentReaderState extends State<PagedDocumentReader> {
  final ReaderTextSelectionController _selection =
      ReaderTextSelectionController();

  ReaderViewportConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _config.navigation.attach(
      this,
      PageControllerNavigation(
        controller: widget.controller,
        totalPages: widget.totalPages,
      ),
    );
    _config.searchBackend.attach(this, widget.searchBackend);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  @override
  void didUpdateWidget(PagedDocumentReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.annotating) _selection.clear();
  }

  @override
  void dispose() {
    _config.searchBackend.detach(this);
    _config.navigation.detach(this);
    _selection.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageNumber) {
    if (!mounted) return;
    _selection.clear();
    _config.onPageChanged(pageNumber);
  }

  void _onTap() {
    if (!mounted || _selection.clear()) return;
    _config.onGeneralTap();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _selection.dragging,
      builder: (context, selecting, _) => PagedReaderGallery(
        controller: widget.controller,
        totalPages: widget.totalPages,
        swipeEnabled: !_config.annotating && !selecting,
        onPageChanged: _onPageChanged,
        onTap: _onTap,
        pageBuilder: (context, pageNumber) => ReaderPageCell(
          pageNumber: pageNumber,
          pageSize: widget.pageSizeOf(pageNumber),
          raster: widget.rasterOf(pageNumber),
          config: _config,
          linkSource: widget.linkSource,
          textSource: widget.textSource,
          selection: _selection,
        ),
      ),
    );
  }
}
