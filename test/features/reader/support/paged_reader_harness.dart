import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/reader_page_link.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';
import 'package:sefer/features/reader/presentation/paged_document_reader.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';
import 'package:sefer/features/reader/state/providers.dart';
import 'fake_annotation_daos.dart';
import 'fake_page_link_source.dart';
import 'fake_page_text_source.dart';
import 'fake_search_backend.dart';

const portraitPage = Size(612, 792);
const landscapePage = Size(792, 612);

const defaultPageSizes = [
  portraitPage,
  portraitPage,
  portraitPage,
  portraitPage,
  portraitPage,
];

Key rasterKey(int pageNumber) => ValueKey('raster-$pageNumber');

class PagedReaderHarness {
  PagedReaderHarness({
    required this.config,
    this.pageSizes = defaultPageSizes,
    int initialPage = 1,
    ReaderPageLinkSource? linkSource,
    ReaderPageTextSource? textSource,
  }) : linkSource = linkSource ?? FakePageLinkSource(),
       textSource = textSource ?? FakePageTextSource(),
       controller = PageController(initialPage: initialPage - 1);

  final ReaderViewportConfig config;
  final List<Size> pageSizes;
  final PageController controller;
  final ReaderPageLinkSource linkSource;
  final ReaderPageTextSource textSource;
  final FakeSearchBackend searchBackend = FakeSearchBackend()
    ..canPlaceViewer = false;
  int readyCount = 0;

  Future<void> pump(WidgetTester tester) async {
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(reader()));
  }

  Future<void> repump(WidgetTester tester, ReaderViewportConfig next) =>
      tester.pumpWidget(wrap(reader(next)));

  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      annotationDaoProvider.overrideWithValue(FakeAnnotationDao()),
      noteEntryDaoProvider.overrideWithValue(FakeNoteEntryDao()),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );

  Widget reader([ReaderViewportConfig? override]) => PagedDocumentReader(
    config: override ?? config,
    controller: controller,
    totalPages: pageSizes.length,
    pageSizeOf: (pageNumber) => pageSizes[pageNumber - 1],
    rasterOf: (pageNumber) =>
        ColoredBox(key: rasterKey(pageNumber), color: Colors.white),
    searchBackend: searchBackend,
    linkSource: linkSource,
    textSource: textSource,
    onReady: () => readyCount++,
  );
}
