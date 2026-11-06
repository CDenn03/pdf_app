import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/state/document_search_controller.dart';
import '../support/fake_search_backend.dart';
import '../support/paged_reader_harness.dart';
import '../support/reader_viewport_fixture.dart';
import '../support/recording_page_navigation.dart';

class _OtherViewport extends StatefulWidget {
  const _OtherViewport({
    required this.fixture,
    required this.navigation,
    required this.backend,
  });

  final ReaderViewportFixture fixture;
  final RecordingPageNavigation navigation;
  final FakeSearchBackend backend;

  @override
  State<_OtherViewport> createState() => _OtherViewportState();
}

class _OtherViewportState extends State<_OtherViewport> {
  @override
  void initState() {
    super.initState();
    widget.fixture.navigation.attach(this, widget.navigation);
    widget.fixture.searchBackend.attach(this, widget.backend);
  }

  @override
  void dispose() {
    widget.fixture.searchBackend.detach(this);
    widget.fixture.navigation.detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

const _typingDelayElapsed = Duration(milliseconds: 1);

void main() {
  late ReaderViewportFixture fixture;
  late PagedReaderHarness harness;
  late RecordingPageNavigation otherNavigation;
  late FakeSearchBackend otherBackend;

  setUp(() {
    fixture = ReaderViewportFixture();
    harness = PagedReaderHarness(config: fixture.config(initialPage: 2));
    otherNavigation = RecordingPageNavigation()..currentPage = 4;
    otherBackend = FakeSearchBackend();
  });

  Widget otherViewport() => _OtherViewport(
    fixture: fixture,
    navigation: otherNavigation,
    backend: otherBackend,
  );

  Future<void> switchToOtherViewport(WidgetTester tester) =>
      tester.pumpWidget(harness.wrap(otherViewport()));

  Future<void> switchToPaged(WidgetTester tester) =>
      tester.pumpWidget(harness.wrap(harness.reader()));

  group('page navigation', () {
    testWidgets('follows the viewport that replaced the paged one', (
      tester,
    ) async {
      await harness.pump(tester);

      await switchToOtherViewport(tester);

      expect(fixture.navigation.currentPage, 4);
      await fixture.navigation.goToPage(6);
      expect(otherNavigation.requestedPages, [6]);
    });

    testWidgets('is the pager again after switching back', (tester) async {
      await harness.pump(tester);
      await switchToOtherViewport(tester);

      await switchToPaged(tester);
      unawaited(fixture.navigation.goToPage(4));
      await tester.pumpAndSettle();

      expect(find.byKey(rasterKey(4)), findsOneWidget);
      expect(otherNavigation.requestedPages, isEmpty);
    });
  });

  group('search', () {
    late DocumentSearchController search;

    setUp(() {
      search = DocumentSearchController(
        backend: fixture.searchBackend,
        navigation: fixture.navigation,
        typingDelay: Duration.zero,
      );
    });

    tearDown(() => search.dispose());

    Future<void> findOnPagesAndSelectSecond(WidgetTester tester) async {
      search.startTextSearch('needle');
      await tester.pump(_typingDelayElapsed);
      harness.searchBackend.latestScan
        ..add([matchOnPage(2)])
        ..add([matchOnPage(5)])
        ..add([matchOnPage(7)]);
      await tester.pump(_typingDelayElapsed);
      unawaited(search.goToMatchAt(1, chromeMargin: 0));
      await tester.pumpAndSettle();
    }

    testWidgets('keeps the results and the active match across a switch', (
      tester,
    ) async {
      await harness.pump(tester);
      await findOnPagesAndSelectSecond(tester);

      await switchToOtherViewport(tester);
      search.rerunQuery();
      await tester.pump(_typingDelayElapsed);
      otherBackend.latestScan
        ..add([matchOnPage(2)])
        ..add([matchOnPage(5)])
        ..add([matchOnPage(7)]);
      await tester.pump(_typingDelayElapsed);

      expect(otherBackend.queries, ['needle']);
      expect([for (final m in search.matches) m.page], [2, 5, 7]);
      expect(search.currentIndex, 1);
    });

    testWidgets('selecting a result in the paged reader opens its page', (
      tester,
    ) async {
      await harness.pump(tester);
      await findOnPagesAndSelectSecond(tester);

      expect(fixture.navigation.currentPage, 5);
      expect(find.byKey(rasterKey(5)), findsOneWidget);
    });

    testWidgets('queries go to the paged backend only while it is mounted', (
      tester,
    ) async {
      await harness.pump(tester);
      await switchToOtherViewport(tester);

      search.startTextSearch('needle');
      await tester.pump(_typingDelayElapsed);

      expect(harness.searchBackend.queries, isEmpty);
      expect(otherBackend.queries, ['needle']);
    });
  });
}
