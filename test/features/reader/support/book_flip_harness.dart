import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/data/page_rasterizer.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';
import 'package:sefer/features/reader/presentation/book_flip_document_reader.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';
import 'package:sefer/features/reader/state/providers.dart';
import 'fake_annotation_daos.dart';
import 'fake_page_link_source.dart';
import 'fake_page_text_source.dart';
import 'fake_search_backend.dart';
import 'paged_reader_harness.dart';

class FakePageRasterizer implements PageRasterizer {
  FakePageRasterizer(this._master);

  final ui.Image _master;
  final List<int> rendered = [];
  Completer<void>? gate;

  @override
  Future<ui.Image?> render(
    int pageNumber,
    ui.Size pixelSize, {
    required PageRenderCancellation cancellation,
  }) async {
    rendered.add(pageNumber);
    await gate?.future;
    return _master.clone();
  }
}

class BookFlipHarness {
  BookFlipHarness._({
    required this.config,
    required this.rasterizer,
    required this.pageSizes,
    required this.linkSource,
    required this.textSource,
  });

  static Future<BookFlipHarness> create(
    WidgetTester tester, {
    required ReaderViewportConfig config,
    List<Size> pageSizes = defaultPageSizes,
    ReaderPageLinkSource? linkSource,
    ReaderPageTextSource? textSource,
  }) async {
    final master = (await tester.runAsync(
      () => createTestImage(width: 8, height: 8),
    ))!;
    addTearDown(master.dispose);
    return BookFlipHarness._(
      config: config,
      rasterizer: FakePageRasterizer(master),
      pageSizes: pageSizes,
      linkSource: linkSource ?? FakePageLinkSource(),
      textSource: textSource ?? FakePageTextSource(),
    );
  }

  final ReaderViewportConfig config;
  final FakePageRasterizer rasterizer;
  final List<Size> pageSizes;
  final ReaderPageLinkSource linkSource;
  final ReaderPageTextSource textSource;
  final FakeSearchBackend searchBackend = FakeSearchBackend()
    ..canPlaceViewer = false;
  int readyCount = 0;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(wrap(reader()));
    await tester.pump();
  }

  Future<void> repump(WidgetTester tester, ReaderViewportConfig next) =>
      tester.pumpWidget(wrap(reader(next)));

  Widget wrap(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      ProviderScope(
        overrides: [
          annotationDaoProvider.overrideWithValue(FakeAnnotationDao()),
          noteEntryDaoProvider.overrideWithValue(FakeNoteEntryDao()),
        ],
        child: MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: child),
          ),
        ),
      );

  Widget reader([ReaderViewportConfig? override]) => BookFlipDocumentReader(
    config: override ?? config,
    totalPages: pageSizes.length,
    pageSizeOf: (pageNumber) => pageSizes[pageNumber - 1],
    rasterOf: (pageNumber) =>
        ColoredBox(key: rasterKey(pageNumber), color: Colors.white),
    rasterizer: rasterizer,
    searchBackend: searchBackend,
    linkSource: linkSource,
    textSource: textSource,
    onReady: () => readyCount++,
  );
}
