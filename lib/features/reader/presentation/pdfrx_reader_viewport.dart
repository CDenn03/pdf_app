import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/data/pdfrx_search_adapter.dart';
import 'package:sefer/features/reader/domain/initial_page_report_filter.dart';
import 'package:sefer/features/reader/domain/page_range.dart';
import 'package:sefer/features/reader/presentation/pdf_viewer_page_navigation.dart';
import 'package:sefer/features/reader/presentation/pdfrx_search_highlight_painter.dart';
import 'package:sefer/features/reader/presentation/reader_link_handler.dart';
import 'package:sefer/features/reader/presentation/reader_overlays.dart';
import 'package:sefer/features/reader/presentation/reader_page_geometry.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';

/// A pdfrx [PdfViewer] wired to the reader.
class PdfrxReaderViewport extends StatefulWidget {
  const PdfrxReaderViewport({super.key, required this.config});

  final ReaderViewportConfig config;

  @override
  State<PdfrxReaderViewport> createState() => _PdfrxReaderViewportState();
}

class _PdfrxReaderViewportState extends State<PdfrxReaderViewport> {
  late final PdfViewerController _controller;
  late final PdfrxSearchAdapter _searchAdapter;
  late final InitialPageReportFilter _initialReportFilter;

  ReaderViewportConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _initialReportFilter = InitialPageReportFilter(
      initialPage: _config.initialPage,
    );
    _controller = PdfViewerController();
    _searchAdapter = PdfrxSearchAdapter(viewer: _controller);
    _config.navigation.attach(
      this,
      PdfViewerPageNavigation(controller: _controller),
    );
    _config.searchBackend.attach(this, _searchAdapter);
    _config.highlights.addListener(_searchAdapter.invalidate);
  }

  @override
  void dispose() {
    _config.highlights.removeListener(_searchAdapter.invalidate);
    _config.searchBackend.detach(this);
    _config.navigation.detach(this);
    super.dispose();
  }

  void _onViewerReady(PdfDocument document) {
    if (!mounted) return;
    _config.onViewerReady(document).catchError((Object e, StackTrace s) {
      developer.log(
        'onViewerReady failed',
        name: 'sefer.reader',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    });
  }

  void _onPageChanged(int? page) {
    if (mounted && _initialReportFilter.shouldForward(page)) {
      _config.onPageChanged(page);
    }
  }

  PdfViewerParams _params() {
    final painter = PdfrxSearchHighlightPainter(
      highlights: _config.highlights,
      matchColor: _config.readingMode.searchMatchColor,
      activeMatchColor: _config.readingMode.searchActiveMatchColor,
    );
    return PdfViewerParams(
      margin: 8,
      calculateInitialPageNumber: (document, _) =>
          PageRange(document.pages.length).clamp(_config.initialPage),
      onViewerReady: (document, _) => _onViewerReady(document),
      onPageChanged: _onPageChanged,
      linkHandlerParams: readerLinkHandlerParams(
        navigation: _config.navigation,
        linkOpener: _config.linkOpener,
      ),
      onGeneralTap: (context, controller, details) {
        if (mounted) _config.onGeneralTap();
        return false;
      },
      textSelectionParams: PdfTextSelectionParams(enabled: !_config.annotating),
      pagePaintCallbacks: [painter.paint],
      pageOverlaysBuilder: (context, pageRectInViewer, page) => [
        ReaderPageOverlay(
          geometry: ReaderPageGeometry(
            pageNumber: page.pageNumber,
            pageSize: Size(page.width, page.height),
            renderedRect: pageRectInViewer,
          ),
          annotating: _config.annotating,
          pdfId: _config.pdfPath,
          activeTool: _config.activeTool,
          sfDocument: _config.sfDocument,
          onAddBookmark: _config.onAddBookmark,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = _config.pdfPath;
    if (_config.isAsset) {
      return PdfViewer.asset(path, controller: _controller, params: _params());
    }
    return PdfViewer.file(path, controller: _controller, params: _params());
  }
}
