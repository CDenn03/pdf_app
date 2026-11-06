import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/book_curl_frame.dart';
import 'package:sefer/features/reader/presentation/book_flip_interaction.dart';
import 'package:sefer/features/reader/presentation/book_flip_stage.dart';
import 'package:sefer/features/reader/presentation/book_page_curl_painter.dart';
import '../support/book_flip_harness.dart';
import '../support/reader_viewport_fixture.dart';

const _wideStrip = Size(1200, 300);
const _columns = 32;
const _rows = 20;

void main() {
  late ReaderViewportFixture fixture;

  setUp(() => fixture = ReaderViewportFixture());

  Future<void> pumpReader(
    WidgetTester tester, {
    List<Size>? pageSizes,
    TextDirection direction = TextDirection.ltr,
  }) async {
    final harness = await BookFlipHarness.create(
      tester,
      config: fixture.config(),
      pageSizes: pageSizes ?? List.filled(5, const Size(612, 792)),
    );
    await tester.pumpWidget(
      harness.wrap(harness.reader(), direction: direction),
    );
    await tester.pump();
  }

  Rect pageRect(WidgetTester tester) {
    final finder = find.byType(BookFlipStage);
    return tester
        .widget<BookFlipStage>(finder)
        .pageRect
        .shift(tester.getTopLeft(finder));
  }

  BookFlipPose pose(WidgetTester tester) =>
      tester.widget<BookFlipStage>(find.byType(BookFlipStage)).turn!.pose;

  BookCurlFrame frame(WidgetTester tester) {
    for (final paint in tester.widgetList<CustomPaint>(
      find.byType(CustomPaint),
    )) {
      final painter = paint.foregroundPainter;
      if (painter is BookPageCurlPainter) return painter.frame;
    }
    throw StateError('no curl is painted');
  }

  Offset at(Rect rect, double dx, double dy) =>
      Offset(rect.left + rect.width * dx, rect.top + rect.height * dy);

  double cornerLift(BookCurlFrame frame, {required bool top}) {
    final row = top ? 0 : _rows;
    return frame.vertices[row * (_columns + 1) + _columns].depth;
  }

  Future<BookCurlFrame> dragFrom(WidgetTester tester, double dy) async {
    final rect = pageRect(tester);
    final gesture = await tester.startGesture(at(rect, 0.85, dy));
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.moveBy(Offset(-rect.width * 0.4, 0));
    await tester.pump();
    final result = frame(tester);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    return result;
  }

  group('touch point', () {
    testWidgets('a top grab lifts the top corner more than the bottom', (
      tester,
    ) async {
      await pumpReader(tester);

      final result = await dragFrom(tester, 0.1);

      expect(
        cornerLift(result, top: true),
        greaterThan(cornerLift(result, top: false)),
      );
    });

    testWidgets('a bottom grab mirrors a top grab', (tester) async {
      await pumpReader(tester);

      final result = await dragFrom(tester, 0.9);

      expect(
        cornerLift(result, top: false),
        greaterThan(cornerLift(result, top: true)),
      );
    });

    testWidgets('a centre grab lifts both corners almost evenly', (
      tester,
    ) async {
      await pumpReader(tester);

      final top = cornerLift(await dragFrom(tester, 0.1), top: true);
      final lift = await dragFrom(tester, 0.5);

      final imbalance =
          (cornerLift(lift, top: true) - cornerLift(lift, top: false)).abs();
      expect(imbalance, lessThan(top * 0.25));
    });

    testWidgets('the finger keeps steering vertically after the turn starts', (
      tester,
    ) async {
      await pumpReader(tester);
      final rect = pageRect(tester);
      final gesture = await tester.startGesture(at(rect, 0.85, 0.3));
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      final before = pose(tester).current.dy;

      for (var step = 0; step < 6; step++) {
        await gesture.moveBy(Offset(0, rect.height * 0.05));
        await tester.pump();
      }

      expect(pose(tester).current.dy, closeTo(before + 0.3, 0.08));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('the grab is measured inside a letterboxed page', (
      tester,
    ) async {
      await pumpReader(tester, pageSizes: List.filled(5, _wideStrip));
      final rect = pageRect(tester);
      expect(rect.top, greaterThan(0));

      final gesture = await tester.startGesture(at(rect, 0.9, 0.25));
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();

      expect(pose(tester).start.dy, closeTo(0.25, 1e-6));
      expect(pose(tester).start.dx, closeTo(0.9, 1e-6));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('a swipe in the letterbox bars does not turn', (tester) async {
      await pumpReader(tester, pageSizes: List.filled(5, _wideStrip));
      final rect = pageRect(tester);

      final gesture = await tester.startGesture(
        Offset(rect.center.dx, rect.top / 2),
      );
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.moveBy(const Offset(-300, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(seconds: 2));

      expect(
        find.byType(BookPageCurlPainter, skipOffstage: false),
        findsNothing,
      );
      expect(fixture.reportedPages, isEmpty);
    });
  });
}
