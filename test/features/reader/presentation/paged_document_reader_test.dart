import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import '../support/paged_reader_harness.dart';
import '../support/reader_viewport_fixture.dart';

void main() {
  late ReaderViewportFixture fixture;

  setUp(() => fixture = ReaderViewportFixture());

  Future<PagedReaderHarness> pumpReader(
    WidgetTester tester, {
    int initialPage = 1,
    bool annotating = false,
  }) async {
    final harness = PagedReaderHarness(
      config: fixture.config(initialPage: initialPage, annotating: annotating),
      initialPage: initialPage,
    );
    await harness.pump(tester);
    return harness;
  }

  Future<void> swipeToNext(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }

  Future<void> swipeToPrevious(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
  }

  Finder raster(int pageNumber) => find.byKey(rasterKey(pageNumber));

  group('page layout', () {
    testWidgets('shows exactly one page of the document', (tester) async {
      await pumpReader(tester);

      expect(raster(1), findsOneWidget);
      expect(raster(2), findsNothing);
    });

    testWidgets('starts on the resume page without reporting a change', (
      tester,
    ) async {
      await pumpReader(tester, initialPage: 3);

      expect(raster(3), findsOneWidget);
      expect(raster(1), findsNothing);
      expect(fixture.reportedPages, isEmpty);
    });

    testWidgets('reports readiness once per mount', (tester) async {
      final harness = await pumpReader(tester);
      await tester.pump();
      await tester.pump();

      expect(harness.readyCount, 1);
    });
  });

  group('swiping', () {
    testWidgets('swiping forward reports the next one-based page', (
      tester,
    ) async {
      await pumpReader(tester);

      await swipeToNext(tester);

      expect(fixture.reportedPages, [2]);
      expect(raster(2), findsOneWidget);
    });

    testWidgets('swiping back reports the previous one-based page', (
      tester,
    ) async {
      await pumpReader(tester, initialPage: 3);

      await swipeToPrevious(tester);

      expect(fixture.reportedPages, [2]);
    });

    testWidgets('swiping back on the first page stays on it', (tester) async {
      await pumpReader(tester);

      await swipeToPrevious(tester);

      expect(fixture.reportedPages, isEmpty);
      expect(raster(1), findsOneWidget);
    });

    testWidgets('swiping forward on the last page stays on it', (tester) async {
      await pumpReader(tester, initialPage: 5);

      await swipeToNext(tester);

      expect(fixture.reportedPages, isEmpty);
      expect(raster(5), findsOneWidget);
    });

    testWidgets('rapid swipes settle on the last reported page', (
      tester,
    ) async {
      await pumpReader(tester);

      for (var i = 0; i < 3; i++) {
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 2000);
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();

      final lastReported = fixture.reportedPages.last!;
      expect(lastReported, greaterThan(1));
      expect(fixture.navigation.currentPage, lastReported);
      expect(raster(lastReported), findsOneWidget);
    });
  });

  group('page navigation', () {
    testWidgets('is attached while the reader is mounted', (tester) async {
      await pumpReader(tester, initialPage: 2);

      expect(fixture.navigation.currentPage, 2);
    });

    testWidgets('jump requests move the pager to the requested page', (
      tester,
    ) async {
      await pumpReader(tester);

      unawaited(fixture.navigation.goToPage(4));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(raster(4), findsOneWidget);
      expect(fixture.reportedPages, [4]);
    });

    testWidgets('requests are dropped once the reader is removed', (
      tester,
    ) async {
      await pumpReader(tester, initialPage: 3);

      await tester.pumpWidget(const SizedBox());
      await fixture.navigation.goToPage(5);

      expect(fixture.navigation.currentPage, 1);
    });
  });

  group('gesture policy', () {
    testWidgets('annotating turns page swiping off', (tester) async {
      await pumpReader(tester, annotating: true);

      await swipeToNext(tester);

      expect(fixture.reportedPages, isEmpty);
      expect(raster(1), findsOneWidget);
    });

    testWidgets('leaving annotation mode restores page swiping', (
      tester,
    ) async {
      final harness = await pumpReader(tester, annotating: true);

      await harness.repump(tester, fixture.config());
      await swipeToNext(tester);

      expect(fixture.reportedPages, [2]);
    });

    testWidgets('every annotation tool keeps swiping off', (tester) async {
      for (final tool in AnnotationTool.values) {
        final harness = PagedReaderHarness(
          config: fixture.config(annotating: true, activeTool: tool),
        );
        await harness.pump(tester);

        await swipeToNext(tester);

        expect(fixture.reportedPages, isEmpty, reason: '$tool');
      }
    });

    testWidgets('tapping a page toggles the reader chrome', (tester) async {
      await pumpReader(tester);

      await tester.tap(find.byType(PageView));

      expect(fixture.generalTapCount, 1);
    });
  });
}
