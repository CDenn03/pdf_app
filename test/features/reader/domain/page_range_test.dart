import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/page_range.dart';

void main() {
  const range = PageRange(10);

  group('clamp', () {
    test('keeps an in-range page unchanged', () {
      expect(range.clamp(4), 4);
    });

    test('raises pages below the first page to page 1', () {
      expect(range.clamp(0), 1);
      expect(range.clamp(-5), 1);
    });

    test('lowers pages beyond the last page to the last page', () {
      expect(range.clamp(11), 10);
      expect(range.clamp(999), 10);
    });

    test('a single-page document always resolves to page 1', () {
      expect(const PageRange(1).clamp(7), 1);
    });
  });

  group('page and index conversion', () {
    test('page 1 is index 0 and the last page is the last index', () {
      expect(range.indexOf(1), 0);
      expect(range.indexOf(10), 9);
    });

    test('index 0 is page 1 and the last index is the last page', () {
      expect(range.pageNumberAt(0), 1);
      expect(range.pageNumberAt(9), 10);
    });

    test('out-of-range inputs resolve to the nearest valid value', () {
      expect(range.indexOf(0), 0);
      expect(range.indexOf(50), 9);
      expect(range.pageNumberAt(-3), 1);
      expect(range.pageNumberAt(50), 10);
    });

    test('converting page to index and back returns the same page', () {
      for (var page = 1; page <= 10; page++) {
        expect(range.pageNumberAt(range.indexOf(page)), page);
      }
    });
  });

  test('ranges with the same page count are equal', () {
    expect(const PageRange(3), const PageRange(3));
    expect(const PageRange(3), isNot(const PageRange(4)));
  });
}
