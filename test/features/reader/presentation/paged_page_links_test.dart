import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/reader_page_link.dart';
import '../support/fake_page_link_source.dart';
import '../support/paged_reader_harness.dart';
import '../support/reader_viewport_fixture.dart';

const _linkBounds = Rect.fromLTRB(0.1, 0.1, 0.4, 0.2);

const _linkToPage3 = ReaderPageLink(
  target: PageLinkTarget(3),
  normalizedBounds: [_linkBounds],
);

final _externalUri = Uri.parse('https://example.com/docs');

final _linkToWebsite = ReaderPageLink(
  target: UriLinkTarget(_externalUri),
  normalizedBounds: const [_linkBounds],
);

class _FailingLinkSource implements ReaderPageLinkSource {
  @override
  Future<List<ReaderPageLink>> linksOn(int pageNumber) =>
      Future.error(StateError('no links'));
}

void main() {
  late ReaderViewportFixture fixture;

  setUp(() => fixture = ReaderViewportFixture());

  Future<void> pumpReader(
    WidgetTester tester, {
    ReaderPageLinkSource? source,
    bool annotating = false,
  }) async {
    final harness = PagedReaderHarness(
      config: fixture.config(annotating: annotating),
      linkSource:
          source ??
          FakePageLinkSource({
            1: [_linkToPage3],
          }),
    );
    await harness.pump(tester);
    await tester.pump();
  }

  Offset inPage(WidgetTester tester, int page, Offset fraction) {
    final rect = tester.getRect(find.byKey(rasterKey(page)));
    return rect.topLeft +
        Offset(rect.width * fraction.dx, rect.height * fraction.dy);
  }

  testWidgets('tapping an internal link opens its destination page', (
    tester,
  ) async {
    await pumpReader(tester);

    await tester.tapAt(inPage(tester, 1, const Offset(0.25, 0.15)));
    await tester.pumpAndSettle();

    expect(fixture.reportedPages, [3]);
    expect(find.byKey(rasterKey(3)), findsOneWidget);
  });

  testWidgets('tapping an external link hands its URI to the opener', (
    tester,
  ) async {
    await pumpReader(
      tester,
      source: FakePageLinkSource({
        1: [_linkToWebsite],
      }),
    );

    await tester.tapAt(inPage(tester, 1, const Offset(0.25, 0.15)));
    await tester.pumpAndSettle();

    expect(fixture.linkOpener.opened, [_externalUri]);
    expect(fixture.reportedPages, isEmpty);
    expect(fixture.generalTapCount, 0);
  });

  testWidgets('links are announced with their destination', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpReader(
      tester,
      source: FakePageLinkSource({
        1: [
          _linkToPage3,
          ReaderPageLink(
            target: UriLinkTarget(_externalUri),
            normalizedBounds: const [Rect.fromLTRB(0.5, 0.5, 0.8, 0.6)],
          ),
        ],
      }),
    );

    expect(find.bySemanticsLabel('Go to page 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Open link example.com'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a tap that misses every link toggles the chrome', (
    tester,
  ) async {
    await pumpReader(tester);

    await tester.tapAt(inPage(tester, 1, const Offset(0.8, 0.8)));
    await tester.pumpAndSettle();

    expect(fixture.generalTapCount, 1);
    expect(fixture.reportedPages, isEmpty);
  });

  testWidgets('a link tap does not toggle the chrome', (tester) async {
    await pumpReader(tester);

    await tester.tapAt(inPage(tester, 1, const Offset(0.25, 0.15)));
    await tester.pumpAndSettle();

    expect(fixture.generalTapCount, 0);
  });

  testWidgets('links belong to the page that declares them', (tester) async {
    await pumpReader(tester);
    unawaited(fixture.navigation.goToPage(2));
    await tester.pumpAndSettle();
    fixture.reportedPages.clear();

    await tester.tapAt(inPage(tester, 2, const Offset(0.25, 0.15)));
    await tester.pumpAndSettle();

    expect(fixture.reportedPages, isEmpty);
    expect(fixture.generalTapCount, 1);
  });

  testWidgets('annotating keeps link taps from navigating', (tester) async {
    await pumpReader(tester, annotating: true);

    await tester.tapAt(inPage(tester, 1, const Offset(0.25, 0.15)));
    await tester.pumpAndSettle();

    expect(fixture.reportedPages, isEmpty);
  });

  testWidgets('annotating keeps external link taps from opening', (
    tester,
  ) async {
    await pumpReader(
      tester,
      annotating: true,
      source: FakePageLinkSource({
        1: [_linkToWebsite],
      }),
    );

    await tester.tapAt(inPage(tester, 1, const Offset(0.25, 0.15)));
    await tester.pumpAndSettle();

    expect(fixture.linkOpener.opened, isEmpty);
  });

  testWidgets('a page whose links fail to load is still readable', (
    tester,
  ) async {
    await pumpReader(tester, source: _FailingLinkSource());

    await tester.tapAt(inPage(tester, 1, const Offset(0.25, 0.15)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(fixture.generalTapCount, 1);
  });
}
