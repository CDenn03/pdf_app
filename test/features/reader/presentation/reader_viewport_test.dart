import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/theme/reader_layout_mode.dart';
import 'package:sefer/features/reader/presentation/book_flip_reader_viewport.dart';
import 'package:sefer/features/reader/presentation/continuous_reader_viewport.dart';
import 'package:sefer/features/reader/presentation/paged_reader_viewport.dart';
import 'package:sefer/features/reader/presentation/pdfrx_reader_viewport.dart';
import 'package:sefer/features/reader/presentation/reader_viewport.dart';
import '../support/fake_search_backend.dart';
import '../support/reader_viewport_fixture.dart';

void main() {
  late ReaderViewportFixture fixture;

  setUp(() => fixture = ReaderViewportFixture());

  Future<void> pumpViewport(WidgetTester tester, ReaderLayoutMode mode) =>
      tester.pumpWidget(
        MaterialApp(
          home: ReaderViewport(layoutMode: mode, config: fixture.config()),
        ),
      );

  group('dispatcher', () {
    testWidgets('continuous mode builds the continuous viewport', (
      tester,
    ) async {
      await pumpViewport(tester, ReaderLayoutMode.continuous);

      expect(find.byType(ContinuousReaderViewport), findsOneWidget);
      expect(find.byType(BookFlipReaderViewport), findsNothing);
    });

    testWidgets('paged mode builds the swipe pages viewport', (tester) async {
      await pumpViewport(tester, ReaderLayoutMode.paged);

      expect(find.byType(PagedReaderViewport), findsOneWidget);
      expect(find.byType(BookFlipReaderViewport), findsNothing);
      expect(find.byType(PdfrxReaderViewport), findsNothing);
    });

    testWidgets('book flip mode builds the book flip viewport', (tester) async {
      await pumpViewport(tester, ReaderLayoutMode.bookFlip);

      expect(find.byType(BookFlipReaderViewport), findsOneWidget);
      expect(find.byType(PagedReaderViewport), findsNothing);
      expect(find.byType(PdfrxReaderViewport), findsNothing);
    });
  });

  group('adapters', () {
    late FakeSearchBackend earlierTarget;

    setUp(() {
      earlierTarget = FakeSearchBackend();
      fixture.searchBackend.attach('earlier', earlierTarget);
    });

    void searchForWord() => fixture.searchBackend.search('word').listen((_) {});

    testWidgets('a mounted viewport takes over search from the prior target', (
      tester,
    ) async {
      await pumpViewport(tester, ReaderLayoutMode.continuous);

      searchForWord();

      expect(earlierTarget.queries, isEmpty);
    });

    testWidgets('switching modes leaves the new viewport serving search', (
      tester,
    ) async {
      await pumpViewport(tester, ReaderLayoutMode.continuous);
      await pumpViewport(tester, ReaderLayoutMode.bookFlip);

      searchForWord();

      expect(earlierTarget.queries, isEmpty);
    });
  });
}
