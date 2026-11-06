import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/search_backend_detached_exception.dart';
import 'package:sefer/features/reader/state/document_search_controller.dart';
import '../support/fake_search_backend.dart';
import '../support/recording_page_navigation.dart';

void main() {
  late FakeSearchBackend backend;
  late RecordingPageNavigation navigation;
  late DocumentSearchController search;

  setUp(() {
    backend = FakeSearchBackend();
    navigation = RecordingPageNavigation();
    search = DocumentSearchController(
      backend: backend,
      navigation: navigation,
      typingDelay: Duration.zero,
    );
  });

  tearDown(() => search.dispose());

  Future<void> searchFor(String query) async {
    search.startTextSearch(query);
    await pumpEventQueue();
  }

  Future<void> deliver(List<int> pages) async {
    for (final page in pages) {
      backend.latestScan.add([matchOnPage(page)]);
    }
    await pumpEventQueue();
  }

  group('results', () {
    test('a new search reports searching until the scan completes', () async {
      await searchFor('needle');
      expect(search.isSearching, isTrue);

      await backend.latestScan.close();
      await pumpEventQueue();

      expect(search.isSearching, isFalse);
    });

    test('matches arrive page by page in document order', () async {
      await searchFor('needle');

      await deliver([2, 5, 5]);

      expect([for (final m in search.matches) m.page], [2, 5, 5]);
    });

    test('matches are grouped by page', () async {
      await searchFor('needle');
      backend.latestScan
        ..add([matchOnPage(2)])
        ..add([matchOnPage(5, 'a'), matchOnPage(5, 'b')]);
      await pumpEventQueue();

      expect(search.matchesOnPage(5).map((m) => m.excerpt.match), [
        'a-5',
        'b-5',
      ]);
      expect(search.matchesOnPage(3), isEmpty);
    });

    test('an empty page adds nothing', () async {
      await searchFor('needle');
      backend.latestScan.add([]);
      await pumpEventQueue();

      expect(search.matches, isEmpty);
      expect(search.currentIndex, isNull);
    });

    test('resetting clears the query, results and active match', () async {
      await searchFor('needle');
      await deliver([2]);

      search.resetTextSearch();

      expect(search.matches, isEmpty);
      expect(search.currentIndex, isNull);
      expect(search.isSearching, isFalse);
    });

    test('an empty query resets instead of searching', () async {
      await searchFor('needle');
      await deliver([2]);

      await searchFor('');

      expect(search.matches, isEmpty);
      expect(backend.queries, ['needle']);
    });

    test('repeating the same query does not restart the scan', () async {
      await searchFor('needle');
      await searchFor('needle');

      expect(backend.queries, ['needle']);
    });

    test('a failed scan stops searching and keeps earlier matches', () async {
      await searchFor('needle');
      await deliver([2]);

      backend.latestScan.addError(StateError('pdf closed'));
      await pumpEventQueue();

      expect(search.isSearching, isFalse);
      expect(search.matches, hasLength(1));
    });
  });

  group('stale results', () {
    test('matches from a superseded query are discarded', () async {
      await searchFor('old');
      await searchFor('new');

      backend.scans.first.add([matchOnPage(1)]);
      await deliver([7]);

      expect([for (final m in search.matches) m.page], [7]);
    });

    test('a scan finishing for a superseded query keeps searching', () async {
      await searchFor('old');
      await searchFor('new');

      await backend.scans.first.close();
      await pumpEventQueue();

      expect(search.isSearching, isTrue);
    });

    test('matches arriving after a reset are discarded', () async {
      await searchFor('needle');
      search.resetTextSearch();

      backend.scans.first.add([matchOnPage(4)]);
      await pumpEventQueue();

      expect(search.matches, isEmpty);
    });

    test(
      'typing again before the delay elapses runs only the last query',
      () async {
        final delayed = DocumentSearchController(
          backend: backend,
          navigation: navigation,
          typingDelay: const Duration(milliseconds: 20),
        );
        addTearDown(delayed.dispose);

        delayed.startTextSearch('ne');
        delayed.startTextSearch('needle');
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(backend.queries, ['needle']);
      },
    );
  });

  group('active match', () {
    test('the first match becomes active and is revealed', () async {
      await searchFor('needle');
      await deliver([3, 6]);

      expect(search.currentIndex, 0);
      expect(backend.revealed.map((m) => m.pageNumber), [3]);
    });

    test('later matches do not steal the active match', () async {
      await searchFor('needle');
      await deliver([3]);
      await search.goToMatchAt(0, chromeMargin: 10);
      await deliver([6]);

      expect(search.currentIndex, 0);
      expect(search.activeMatch?.pageNumber, 3);
    });

    test('selecting a match makes it active and reveals it', () async {
      await searchFor('needle');
      await deliver([3, 6, 9]);

      await search.goToMatchAt(2, chromeMargin: 120);

      expect(search.currentIndex, 2);
      expect(backend.revealed.last.pageNumber, 9);
    });

    test('selecting an index outside the results does nothing', () async {
      await searchFor('needle');
      await deliver([3]);

      await search.goToMatchAt(5, chromeMargin: 120);

      expect(search.currentIndex, 0);
    });

    test(
      'a match the viewer cannot place is shown by page navigation',
      () async {
        backend.canPlaceViewer = false;
        await searchFor('needle');
        await deliver([3, 6]);

        await search.goToMatchAt(1, chromeMargin: 120);

        expect(navigation.requestedPages, contains(6));
      },
    );

    test('a match the viewer placed does not navigate by page', () async {
      await searchFor('needle');
      await deliver([3, 6]);

      await search.goToMatchAt(1, chromeMargin: 120);

      expect(navigation.requestedPages, isEmpty);
    });
  });

  group('next and previous', () {
    Future<void> withThreeMatches() async {
      await searchFor('needle');
      await deliver([2, 5, 9]);
    }

    test('next advances to the following match', () async {
      await withThreeMatches();

      await search.goToNextMatch(chromeMargin: 120);

      expect(search.currentIndex, 1);
    });

    test('next wraps from the last match to the first', () async {
      await withThreeMatches();
      await search.goToMatchAt(2, chromeMargin: 120);

      await search.goToNextMatch(chromeMargin: 120);

      expect(search.currentIndex, 0);
    });

    test('previous steps back to the preceding match', () async {
      await withThreeMatches();
      await search.goToMatchAt(2, chromeMargin: 120);

      await search.goToPreviousMatch(chromeMargin: 120);

      expect(search.currentIndex, 1);
    });

    test('previous wraps from the first match to the last', () async {
      await withThreeMatches();

      await search.goToPreviousMatch(chromeMargin: 120);

      expect(search.currentIndex, 2);
    });

    test('next and previous do nothing without results', () async {
      await search.goToNextMatch(chromeMargin: 120);
      await search.goToPreviousMatch(chromeMargin: 120);

      expect(search.currentIndex, isNull);
    });
  });

  group('surviving a viewer change', () {
    test('rerunning the query rescans without moving the viewer', () async {
      await searchFor('needle');
      await deliver([4]);
      backend.revealed.clear();

      search.rerunQuery();
      await pumpEventQueue();
      await deliver([4]);

      expect(backend.queries, ['needle', 'needle']);
      expect(search.matches, hasLength(1));
      expect(backend.revealed, isEmpty);
    });

    test('rerunning keeps the active match once it is found again', () async {
      await searchFor('needle');
      await deliver([2, 4, 6]);
      await search.goToMatchAt(1, chromeMargin: 0);

      search.rerunQuery();
      await pumpEventQueue();
      await deliver([2, 4, 6]);

      expect(search.currentIndex, 1);
      expect(search.activeMatch, matchOnPage(4));
    });

    test(
      'a rescan that loses the active match falls back to the first',
      () async {
        await searchFor('needle');
        await deliver([2, 4]);
        await search.goToMatchAt(1, chromeMargin: 0);

        search.rerunQuery();
        await pumpEventQueue();
        await deliver([2]);
        await backend.latestScan.close();
        await pumpEventQueue();

        expect(search.currentIndex, 0);
        expect(search.isSearching, isFalse);
      },
    );

    test('rerunning without a query does nothing', () {
      search.rerunQuery();

      expect(backend.queries, isEmpty);
    });
  });

  group('a backend detached mid-scan', () {
    test('keeps the partial results but never reports them complete', () async {
      await searchFor('needle');
      await deliver([2]);

      backend.latestScan.addError(const SearchBackendDetachedException());
      await pumpEventQueue();

      expect([for (final m in search.matches) m.page], [2]);
      expect(search.isSearching, isTrue);
    });

    test('a rerun afterwards replaces the partial results', () async {
      await searchFor('needle');
      await deliver([2]);
      backend.latestScan.addError(const SearchBackendDetachedException());
      await pumpEventQueue();

      search.rerunQuery();
      await deliver([4]);
      await backend.latestScan.close();
      await pumpEventQueue();

      expect([for (final m in search.matches) m.page], [4]);
      expect(search.isSearching, isFalse);
    });
  });

  group('disposal', () {
    test('a reveal already in flight at dispose does not navigate', () async {
      backend.canPlaceViewer = false;
      final local = DocumentSearchController(
        backend: backend,
        navigation: navigation,
        typingDelay: Duration.zero,
      );
      local.startTextSearch('needle');
      await pumpEventQueue();
      backend.latestScan.add([matchOnPage(2)]);
      await pumpEventQueue();
      navigation.requestedPages.clear();
      final revealing = local.goToMatchAt(0, chromeMargin: 10);
      local.dispose();

      await revealing;

      expect(navigation.requestedPages, isEmpty);
    });
  });
}
