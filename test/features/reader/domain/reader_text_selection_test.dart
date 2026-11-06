import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/reader_text_selection.dart';

void main() {
  group('ReaderTextSelection.between', () {
    test('orders a reversed drag so start precedes end', () {
      final selection = ReaderTextSelection.between(9, 3);

      expect(selection.start, 3);
      expect(selection.end, 10);
    });

    test('keeps a forward drag as given', () {
      final selection = ReaderTextSelection.between(3, 9);

      expect(selection.start, 3);
      expect(selection.end, 10);
    });
  });

  group('extendedTo', () {
    test('grows forward past the current end', () {
      final selection = ReaderTextSelection.between(2, 4).extendedTo(8);

      expect(selection, ReaderTextSelection.between(2, 8));
    });

    test('grows backward past the current start', () {
      final selection = ReaderTextSelection.between(4, 6).extendedTo(1);

      expect(selection, ReaderTextSelection.between(1, 6));
    });

    test('an index already inside the selection changes nothing', () {
      final selection = ReaderTextSelection.between(2, 8);

      expect(selection.extendedTo(5), selection);
    });
  });
}
