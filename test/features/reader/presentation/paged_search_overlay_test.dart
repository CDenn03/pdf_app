import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/search_excerpt.dart';
import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/search_backend_detached_exception.dart';
import 'package:sefer/features/reader/presentation/search_match_overlay.dart';
import '../support/paged_reader_harness.dart';
import '../support/reader_viewport_fixture.dart';

ReaderPageMatch _match(int page, Rect bounds, [String snippet = 'hit']) =>
    ReaderPageMatch(
      pageNumber: page,
      excerpt: SearchExcerpt.plain(snippet),
      normalizedBounds: [bounds],
    );

const _first = Rect.fromLTRB(0.1, 0.2, 0.5, 0.3);
const _second = Rect.fromLTRB(0.2, 0.6, 0.6, 0.7);

void main() {
  late ReaderViewportFixture fixture;
  final mode = ReadingMode.values.first;

  setUp(() => fixture = ReaderViewportFixture());

  Future<PagedReaderHarness> pumpReader(
    WidgetTester tester, {
    List<Size> pageSizes = defaultPageSizes,
  }) async {
    final harness = PagedReaderHarness(
      config: fixture.config(),
      pageSizes: pageSizes,
    );
    await harness.pump(tester);
    return harness;
  }

  Finder overlayPaint() => find.descendant(
    of: find.byType(SearchMatchOverlay),
    matching: find.byType(CustomPaint),
  );

  Rect inRaster(WidgetTester tester, int page, Rect normalized) {
    final size = tester.getSize(find.byKey(rasterKey(page)));
    return Rect.fromLTRB(
      normalized.left * size.width,
      normalized.top * size.height,
      normalized.right * size.width,
      normalized.bottom * size.height,
    );
  }

  group('search backend', () {
    testWidgets('serves searches while the reader is mounted', (tester) async {
      final harness = await pumpReader(tester);

      fixture.searchBackend.search('word').listen((_) {}, onError: (_) {});

      expect(harness.searchBackend.queries, ['word']);
    });

    testWidgets('ignores searches once the reader is removed', (tester) async {
      final harness = await pumpReader(tester);

      await tester.pumpWidget(const SizedBox());
      fixture.searchBackend.search('word').listen((_) {});

      expect(harness.searchBackend.queries, isEmpty);
    });

    testWidgets('a scan running when the reader is removed is reported as '
        'detached, not finished', (tester) async {
      final harness = await pumpReader(tester);
      final outcome = <Object>[];
      fixture.searchBackend
          .search('word')
          .listen(
            (_) {},
            onError: outcome.add,
            onDone: () => outcome.add('done'),
          );

      await tester.pumpWidget(const SizedBox());
      unawaited(harness.searchBackend.latestScan.close());
      await tester.pump();

      expect(outcome, [isA<SearchBackendDetachedException>()]);
    });
  });

  group('match painting', () {
    testWidgets('a match is painted inside the rendered page', (tester) async {
      await pumpReader(tester);

      fixture.highlights.show([_match(1, _first)]);
      await tester.pump();

      expect(
        tester.renderObject(overlayPaint()),
        paints..rect(
          rect: inRaster(tester, 1, _first),
          color: mode.searchMatchColor,
        ),
      );
    });

    testWidgets('a match lines up with a landscape page', (tester) async {
      await pumpReader(tester, pageSizes: const [landscapePage, landscapePage]);

      fixture.highlights.show([_match(1, _first)]);
      await tester.pump();

      expect(
        tester.renderObject(overlayPaint()),
        paints..rect(
          rect: inRaster(tester, 1, _first),
          color: mode.searchMatchColor,
        ),
      );
    });

    testWidgets('only the active match uses the active colour', (tester) async {
      await pumpReader(tester);
      final active = _match(1, _second, 'active');

      fixture.highlights.show([_match(1, _first), active], active: active);
      await tester.pump();

      expect(
        tester.renderObject(overlayPaint()),
        paints
          ..rect(
            rect: inRaster(tester, 1, _first),
            color: mode.searchMatchColor,
          )
          ..rect(
            rect: inRaster(tester, 1, _second),
            color: mode.searchActiveMatchColor,
          ),
      );
    });

    testWidgets('changing the active match recolours the matches', (
      tester,
    ) async {
      await pumpReader(tester);
      final first = _match(1, _first, 'a');
      final second = _match(1, _second, 'b');
      fixture.highlights.show([first, second], active: first);
      await tester.pump();

      fixture.highlights.show([first, second], active: second);
      await tester.pump();

      expect(
        tester.renderObject(overlayPaint()),
        paints
          ..rect(color: mode.searchMatchColor)
          ..rect(color: mode.searchActiveMatchColor),
      );
    });

    testWidgets('matches on other pages are not painted', (tester) async {
      await pumpReader(tester);

      fixture.highlights.show([_match(3, _first)]);
      await tester.pump();

      expect(overlayPaint(), findsNothing);
    });

    testWidgets('clearing the results removes the highlights', (tester) async {
      await pumpReader(tester);
      fixture.highlights.show([_match(1, _first)]);
      await tester.pump();

      fixture.highlights.show(const []);
      await tester.pump();

      expect(overlayPaint(), findsNothing);
    });
  });

  group('revealing a match', () {
    testWidgets('navigating to its page shows the active match there', (
      tester,
    ) async {
      await pumpReader(tester);
      final active = _match(4, _second, 'far');
      fixture.highlights.show([_match(1, _first), active], active: active);

      unawaited(fixture.navigation.goToPage(active.pageNumber));
      await tester.pumpAndSettle();

      expect(
        tester.renderObject(overlayPaint()),
        paints..rect(
          rect: inRaster(tester, 4, _second),
          color: mode.searchActiveMatchColor,
        ),
      );
    });
  });
}
