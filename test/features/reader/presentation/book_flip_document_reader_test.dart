import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import 'package:sefer/features/reader/presentation/book_flip_stage.dart';
import 'package:sefer/features/reader/presentation/book_page_curl_painter.dart';
import 'package:sefer/features/reader/presentation/page_link_layer.dart';
import 'package:sefer/features/reader/presentation/page_text_selection_layer.dart';
import 'package:sefer/features/reader/presentation/selection_toolbar.dart';
import '../support/book_flip_harness.dart';
import '../support/fake_page_text_source.dart';
import '../support/page_text_fixtures.dart';
import '../support/paged_reader_harness.dart';
import '../support/reader_viewport_fixture.dart';

const _center = Offset(400, 300);

void main() {
  late ReaderViewportFixture fixture;

  setUp(() => fixture = ReaderViewportFixture());

  Future<BookFlipHarness> pumpReader(
    WidgetTester tester, {
    int initialPage = 1,
    bool annotating = false,
    AnnotationTool tool = AnnotationTool.highlight,
    FakePageTextSource? textSource,
    bool holdImages = false,
  }) async {
    final harness = await BookFlipHarness.create(
      tester,
      config: fixture.config(
        initialPage: initialPage,
        annotating: annotating,
        activeTool: tool,
      ),
      textSource: textSource,
    );
    if (holdImages) harness.rasterizer.gate = Completer();
    await harness.pump(tester);
    return harness;
  }

  BookPageCurlPainter? curl(WidgetTester tester) {
    for (final paint in tester.widgetList<CustomPaint>(
      find.byType(CustomPaint),
    )) {
      final painter = paint.foregroundPainter;
      if (painter is BookPageCurlPainter) return painter;
    }
    return null;
  }

  double turnFraction(WidgetTester tester) => tester
      .widget<BookFlipStage>(find.byType(BookFlipStage))
      .turn!
      .pose
      .turnFraction;

  double pageWidth(WidgetTester tester) =>
      tester.widget<BookFlipStage>(find.byType(BookFlipStage)).pageRect.width;

  Finder raster(int pageNumber) => find.byKey(rasterKey(pageNumber));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> dragBy(TestGesture gesture, double dx) async {
    const slopStep = 30.0;
    await gesture.moveBy(Offset(slopStep * dx.sign, 0));
    await gesture.moveBy(Offset(dx - slopStep * dx.sign, 0));
  }

  Future<void> dragAndRelease(WidgetTester tester, double dx) async {
    final gesture = await tester.startGesture(_center);
    await dragBy(gesture, dx);
    await tester.pump();
    await gesture.up();
    await settle(tester);
  }

  group('resting', () {
    testWidgets('shows one page with no curl', (tester) async {
      await pumpReader(tester);

      expect(raster(1), findsOneWidget);
      expect(raster(2), findsNothing);
      expect(curl(tester), isNull);
    });

    testWidgets('starts on the resume page without reporting it', (
      tester,
    ) async {
      await pumpReader(tester, initialPage: 3);

      expect(raster(3), findsOneWidget);
      expect(fixture.reportedPages, isEmpty);
    });

    testWidgets('reports readiness once and preloads the neighbours', (
      tester,
    ) async {
      final harness = await pumpReader(tester, initialPage: 3);
      await tester.pump();

      expect(harness.readyCount, 1);
      expect(harness.rasterizer.rendered.toSet(), {2, 3, 4});
    });

    testWidgets('moves the preload window when the page changes', (
      tester,
    ) async {
      final harness = await pumpReader(tester);

      await dragAndRelease(tester, -600);

      expect(harness.rasterizer.rendered.toSet(), {1, 2, 3});
    });
  });

  group('turning', () {
    testWidgets('the curl follows the finger', (tester) async {
      await pumpReader(tester);

      final gesture = await tester.startGesture(_center);
      await dragBy(gesture, -200);
      await tester.pump();

      expect(curl(tester), isNotNull);
      expect(turnFraction(tester), closeTo(200 / pageWidth(tester), 0.08));
      expect(raster(2), findsOneWidget);

      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();
      expect(turnFraction(tester), closeTo(400 / pageWidth(tester), 0.08));

      await gesture.up();
      await settle(tester);
    });

    testWidgets('the pose follows the touch in two dimensions', (tester) async {
      await pumpReader(tester);
      final gesture = await tester.startGesture(_center + const Offset(0, 100));
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.moveBy(const Offset(-100, -40));
      await tester.pump();

      final pose = tester
          .widget<BookFlipStage>(find.byType(BookFlipStage))
          .turn!
          .pose;
      expect(pose.start.dy, greaterThan(0.5));
      expect(pose.current.dy, lessThan(pose.start.dy));
      expect(pose.current.dx, lessThan(pose.start.dx));

      await gesture.up();
      await settle(tester);
    });

    testWidgets('a touch outside the page rect does not turn', (tester) async {
      await pumpReader(tester);

      final outside = Offset(
        tester.getTopLeft(find.byType(BookFlipStage)).dx + 1,
        300,
      );
      final gesture = await tester.startGesture(outside);
      await dragBy(gesture, -400);
      await tester.pump();
      await gesture.up();
      await settle(tester);

      expect(fixture.reportedPages, isEmpty);
    });

    testWidgets('releasing far enough reports the next page once', (
      tester,
    ) async {
      await pumpReader(tester);

      await dragAndRelease(tester, -500);

      expect(fixture.reportedPages, [2]);
      expect(raster(2), findsOneWidget);
      expect(raster(1), findsNothing);
      expect(curl(tester), isNull);
    });

    testWidgets('releasing early keeps the page and reports nothing', (
      tester,
    ) async {
      await pumpReader(tester);

      await dragAndRelease(tester, -60);

      expect(fixture.reportedPages, isEmpty);
      expect(raster(1), findsOneWidget);
      expect(raster(2), findsNothing);
    });

    testWidgets('dragging right turns back', (tester) async {
      await pumpReader(tester, initialPage: 3);

      await dragAndRelease(tester, 500);

      expect(fixture.reportedPages, [2]);
    });

    testWidgets('the first page resists a backward drag', (tester) async {
      await pumpReader(tester);

      await dragAndRelease(tester, 500);

      expect(fixture.reportedPages, isEmpty);
      expect(raster(1), findsOneWidget);
      expect(curl(tester), isNull);
    });

    testWidgets('the last page resists a forward drag', (tester) async {
      await pumpReader(tester, initialPage: 5);

      await dragAndRelease(tester, -500);

      expect(fixture.reportedPages, isEmpty);
      expect(raster(5), findsOneWidget);
    });

    testWidgets('right to left reading turns forward with a right drag', (
      tester,
    ) async {
      final harness = await BookFlipHarness.create(
        tester,
        config: fixture.config(),
      );
      await tester.pumpWidget(
        harness.wrap(harness.reader(), direction: TextDirection.rtl),
      );
      await tester.pump();

      await dragAndRelease(tester, 500);

      expect(fixture.reportedPages, [2]);
    });

    testWidgets('without a ready image the live page is rotated', (
      tester,
    ) async {
      final harness = await pumpReader(tester, holdImages: true);

      final gesture = await tester.startGesture(_center);
      await dragBy(gesture, -300);
      await tester.pump();

      expect(curl(tester), isNull);
      expect(raster(1), findsOneWidget);
      expect(raster(2), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);

      harness.rasterizer.gate!.complete();
      await tester.pump();
      await tester.pump();
      expect(curl(tester), isNotNull);

      await gesture.up();
      await settle(tester);
    });
  });

  group('page navigation', () {
    testWidgets('is attached while mounted and dropped afterwards', (
      tester,
    ) async {
      await pumpReader(tester, initialPage: 2);
      expect(fixture.navigation.currentPage, 2);

      await tester.pumpWidget(const SizedBox());
      await fixture.navigation.goToPage(5);

      expect(fixture.navigation.currentPage, 1);
    });

    testWidgets('an adjacent request animates a turn', (tester) async {
      await pumpReader(tester);

      unawaited(fixture.navigation.goToPage(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(curl(tester), isNotNull);

      await settle(tester);
      expect(fixture.reportedPages, [2]);
    });

    testWidgets('a distant request shows the page at once', (tester) async {
      await pumpReader(tester);

      unawaited(fixture.navigation.goToPage(4));
      await tester.pump();

      expect(raster(4), findsOneWidget);
      expect(curl(tester), isNull);
      expect(fixture.reportedPages, [4]);
      await settle(tester);
    });

    testWidgets('page one can be requested after resuming on page four', (
      tester,
    ) async {
      await pumpReader(tester, initialPage: 4);

      unawaited(fixture.navigation.goToPage(1));
      await tester.pump();

      expect(raster(1), findsOneWidget);
      expect(fixture.reportedPages, [1]);
      await settle(tester);
    });
  });

  group('gesture policy', () {
    testWidgets('annotating turns page turning off', (tester) async {
      await pumpReader(tester, annotating: true);

      await dragAndRelease(tester, -500);

      expect(fixture.reportedPages, isEmpty);
      expect(raster(1), findsOneWidget);
    });

    testWidgets('every annotation tool keeps turning off', (tester) async {
      for (final tool in AnnotationTool.values) {
        await pumpReader(tester, annotating: true, tool: tool);

        await dragAndRelease(tester, -500);

        expect(fixture.reportedPages, isEmpty, reason: '$tool');
      }
    });

    testWidgets('leaving annotation mode restores turning', (tester) async {
      final harness = await pumpReader(tester, annotating: true);

      await harness.repump(tester, fixture.config());
      await dragAndRelease(tester, -500);

      expect(fixture.reportedPages, [2]);
    });

    testWidgets('tapping a page toggles the chrome', (tester) async {
      await pumpReader(tester);

      await tester.tapAt(_center);

      expect(fixture.generalTapCount, 1);
    });

    testWidgets('taps do not toggle the chrome while a turn settles', (
      tester,
    ) async {
      await pumpReader(tester);
      final gesture = await tester.startGesture(_center);
      await dragBy(gesture, -500);
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tapAt(const Offset(100, 100));

      expect(fixture.generalTapCount, 0);
      await settle(tester);
      await tester.tapAt(_center);
      expect(fixture.generalTapCount, 1);
    });

    testWidgets('links and selection are unavailable while turning', (
      tester,
    ) async {
      await pumpReader(tester);
      expect(_ignoredAncestors(PageLinkLayer), findsNothing);
      expect(_ignoredAncestors(PageTextSelectionLayer), findsNothing);

      final gesture = await tester.startGesture(_center);
      await dragBy(gesture, -300);
      await tester.pump();

      expect(_ignoredAncestors(PageLinkLayer), findsNWidgets(2));
      expect(_ignoredAncestors(PageTextSelectionLayer), findsNWidgets(2));

      await gesture.up();
      await settle(tester);
      expect(_ignoredAncestors(PageLinkLayer), findsNothing);
    });

    testWidgets('a turn clears the text selection', (tester) async {
      final text = pageTextFromLines(['hello world']);
      await pumpReader(tester, textSource: FakePageTextSource({1: text}));
      final press = screenCenterOf(tester, page: 1, text: text, index: 1);
      final gesture = await tester.startGesture(press);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();
      expect(find.byType(SelectionToolbar), findsOneWidget);

      await dragAndRelease(tester, -500);

      expect(find.byType(SelectionToolbar), findsNothing);
      expect(fixture.reportedPages, [2]);
    });
  });

  group('mode switching', () {
    testWidgets('a remount resumes on the canonical page', (tester) async {
      await pumpReader(tester);
      await dragAndRelease(tester, -500);
      await dragAndRelease(tester, -500);
      final canonical = fixture.reportedPages.last!;

      await tester.pumpWidget(const SizedBox());
      final harness = await BookFlipHarness.create(
        tester,
        config: fixture.config(initialPage: canonical),
      );
      await harness.pump(tester);

      expect(canonical, 3);
      expect(raster(3), findsOneWidget);
      expect(fixture.navigation.currentPage, 3);
      expect(fixture.reportedPages, [2, 3]);
    });

    testWidgets('search follows the mounted reader', (tester) async {
      final harness = await pumpReader(tester);
      await tester.pumpWidget(const SizedBox());
      final next = await pumpReader(tester);

      final results = fixture.searchBackend
          .search('word')
          .listen((_) {}, onError: (Object _) {});
      addTearDown(results.cancel);

      expect(harness.searchBackend.queries, isEmpty);
      expect(next.searchBackend.queries, ['word']);
    });
  });

  group('search backend', () {
    testWidgets('serves queries while mounted', (tester) async {
      final harness = await pumpReader(tester);

      final results = fixture.searchBackend
          .search('word')
          .listen((_) {}, onError: (Object _) {});
      addTearDown(results.cancel);

      expect(harness.searchBackend.queries, ['word']);
    });
  });
}

Finder _ignoredAncestors(Type layer) => find.ancestor(
  of: find.byType(layer),
  matching: find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
);
