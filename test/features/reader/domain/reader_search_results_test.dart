import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/reader_search_results.dart';
import '../support/fake_search_backend.dart';

void main() {
  test('an empty result set has no matches on any page', () {
    expect(ReaderSearchResults.empty.isEmpty, isTrue);
    expect(ReaderSearchResults.empty.onPage(1), isEmpty);
  });

  test('matches are grouped by their page, keeping document order', () {
    final results = ReaderSearchResults([
      matchOnPage(2, 'a'),
      matchOnPage(2, 'b'),
      matchOnPage(7),
    ]);

    expect(results.onPage(2).map((m) => m.excerpt.match), ['a-2', 'b-2']);
    expect(results.onPage(7), hasLength(1));
    expect(results.onPage(4), isEmpty);
  });

  test('including more matches leaves the original untouched', () {
    final original = ReaderSearchResults([matchOnPage(1)]);

    final extended = original.including([matchOnPage(3)]);

    expect(original.matches, hasLength(1));
    expect(extended.matches.map((m) => m.pageNumber), [1, 3]);
  });

  test('the match list cannot be modified', () {
    final results = ReaderSearchResults([matchOnPage(1)]);

    expect(() => results.matches.add(matchOnPage(2)), throwsUnsupportedError);
    expect(() => results.onPage(1).add(matchOnPage(2)), throwsUnsupportedError);
  });

  group('wrapping', () {
    final results = ReaderSearchResults([
      matchOnPage(1),
      matchOnPage(2),
      matchOnPage(3),
    ]);

    test('next from nothing selects the first match', () {
      expect(results.nextIndex(null), 0);
    });

    test('next after the last match wraps to the first', () {
      expect(results.nextIndex(2), 0);
    });

    test('previous from nothing selects the last match', () {
      expect(results.previousIndex(null), 2);
    });

    test('previous before the first match wraps to the last', () {
      expect(results.previousIndex(0), 2);
    });

    test('stepping inside the list moves by one', () {
      expect(results.nextIndex(0), 1);
      expect(results.previousIndex(2), 1);
    });
  });
}
