import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/presentation/paged_document_reader.dart';
import 'package:sefer/features/reader/presentation/reader_document_loader.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';
import 'package:sefer/features/reader/presentation/viewer_ready_reporter.dart';

/// Swipe Pages: one PDF page per screen. pdfrx rasterises each page; search
/// and links read the loaded document directly.
class PagedReaderViewport extends StatefulWidget {
  const PagedReaderViewport({super.key, required this.config});

  final ReaderViewportConfig config;

  @override
  State<PagedReaderViewport> createState() => _PagedReaderViewportState();
}

class _PagedReaderViewportState extends State<PagedReaderViewport> {
  late final PageController _controller;

  ReaderViewportConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: math.max(0, _config.initialPage - 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ReaderDocumentLoader(
    pdfPath: _config.pdfPath,
    isAsset: _config.isAsset,
    builder: (context, document, session) => PagedDocumentReader(
      config: _config,
      controller: _controller,
      totalPages: session.pageCount,
      pageSizeOf: (pageNumber) {
        final page = document.pages[pageNumber - 1];
        return Size(page.width, page.height);
      },
      rasterOf: (pageNumber) => PdfPageView(
        document: document,
        pageNumber: pageNumber,
        decoration: const BoxDecoration(color: Colors.white),
      ),
      searchBackend: session.searchBackend,
      linkSource: session.linkSource,
      textSource: session.textSource,
      onReady: () => reportViewerReady(_config, document),
    ),
  );
}
