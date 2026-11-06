import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/pdfrx_page_rasterizer.dart';
import 'package:sefer/features/reader/presentation/book_flip_document_reader.dart';
import 'package:sefer/features/reader/presentation/reader_document_loader.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';
import 'package:sefer/features/reader/presentation/viewer_ready_reporter.dart';

/// Book Flip: one PDF page at a time, turned by dragging its edge.
class BookFlipReaderViewport extends StatelessWidget {
  const BookFlipReaderViewport({super.key, required this.config});

  final ReaderViewportConfig config;

  @override
  Widget build(BuildContext context) => ReaderDocumentLoader(
    pdfPath: config.pdfPath,
    isAsset: config.isAsset,
    builder: (context, document, session) => BookFlipDocumentReader(
      key: ObjectKey(document),
      config: config,
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
      rasterizer: PdfrxPageRasterizer(document: document),
      searchBackend: session.searchBackend,
      linkSource: session.linkSource,
      textSource: session.textSource,
      onReady: () => reportViewerReady(config, document),
    ),
  );
}
