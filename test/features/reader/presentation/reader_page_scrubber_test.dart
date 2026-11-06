import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/presentation/reader_page_scrubber.dart';

const _height = 448.0;
const _thumbFinder = ValueKey('page-scrubber-thumb');

Future<void> _pump(
  WidgetTester tester, {
  required List<int> requests,
  int currentPage = 1,
  int totalPages = 11,
  VoidCallback? onUnderlyingTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              right: kScrubberGutterWidth,
              top: 100,
              width: 40,
              height: 40,
              child: GestureDetector(
                key: const ValueKey('note-marker'),
                onTap: onUnderlyingTap,
                child: const ColoredBox(color: Colors.yellow),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              height: _height,
              child: ReaderPageScrubber(
                currentPage: currentPage,
                totalPages: totalPages,
                readingMode: ReadingMode.light,
                onPageRequested: requests.add,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

SemanticsNode _scrubberNode(WidgetTester tester) =>
    tester.getSemantics(find.bySemanticsLabel('Page scrubber'));

void main() {
  testWidgets('drags immediately and maps first/middle/last pages', (
    tester,
  ) async {
    final requests = <int>[];
    await _pump(tester, requests: requests);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_thumbFinder)),
    );
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    expect(requests, isNotEmpty);
    expect(requests.last, inInclusiveRange(2, 10));

    await gesture.moveBy(const Offset(0, 1000));
    await gesture.up();
    await tester.pump();
    expect(requests.last, 11);

    final back = await tester.startGesture(
      tester.getCenter(find.byKey(_thumbFinder)),
    );
    await back.moveBy(const Offset(0, -2000));
    await back.up();
    await tester.pump();
    expect(requests.last, 1);
  });

  testWidgets('dedupes and throttles requests, final one on release', (
    tester,
  ) async {
    final requests = <int>[];
    await _pump(tester, requests: requests, totalPages: 101);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_thumbFinder)),
    );
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(0, 8));
    }
    expect(requests.length, 1);

    await tester.pump(kScrubberRequestInterval);
    expect(requests.length, 2);

    await gesture.moveBy(const Offset(0, 30));
    await gesture.up();
    await tester.pump();
    expect(requests.length, 3);
    expect(requests.toSet().length, requests.length);
    await tester.pump(kScrubberRequestInterval * 2);
    expect(requests.length, 3);
  });

  testWidgets('cancel does not request and shows current page again', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final requests = <int>[];
    await _pump(tester, requests: requests, currentPage: 3);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_thumbFinder)),
    );
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();
    final requestsBeforeCancel = requests.length;
    await gesture.cancel();
    await tester.pump(kScrubberRequestInterval * 2);

    expect(requests.length, requestsBeforeCancel);
    expect(_scrubberNode(tester).value, 'Page 3 of 11');
    handle.dispose();
  });

  testWidgets('exposes slider semantics with +/-1 actions', (tester) async {
    final handle = tester.ensureSemantics();
    final requests = <int>[];
    await _pump(tester, requests: requests, currentPage: 4);

    final node = _scrubberNode(tester);
    expect(node.value, 'Page 4 of 11');
    expect(node.flagsCollection.isSlider, isTrue);

    tester.semantics.performAction(
      find.semantics.byLabel('Page scrubber'),
      SemanticsAction.increase,
    );
    tester.semantics.performAction(
      find.semantics.byLabel('Page scrubber'),
      SemanticsAction.decrease,
    );
    expect(requests, [5, 3]);
    handle.dispose();
  });

  testWidgets('is hidden for a single page', (tester) async {
    await _pump(tester, requests: [], totalPages: 1);
    expect(find.byKey(_thumbFinder), findsNothing);
  });

  testWidgets('taps outside the gutter reach the widget underneath', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, requests: [], onUnderlyingTap: () => taps++);

    await tester.tap(find.byKey(const ValueKey('note-marker')));
    expect(taps, 1);
  });
}
