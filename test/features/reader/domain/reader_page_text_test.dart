import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/reader_page_text.dart';
import 'package:sefer/features/reader/domain/reader_text_selection.dart';
import '../support/page_text_fixtures.dart';

void main() {
  final text = pageTextFromLines(['hello big world', 'second line']);

  Offset centerOf(int index) => text.characterBounds[index].center;

  group('characterNear', () {
    test('a point inside a character finds that character', () {
      expect(text.characterNear(centerOf(1)), 1);
    });

    test('a point between two lines finds the closer line', () {
      final nearSecondLine = Offset(centerOf(0).dx, 0.148);

      final index = text.characterNear(nearSecondLine);

      expect(text.text[index!], 's');
    });

    test('a point just past the last line picks its last character', () {
      expect(
        text.characterNear(const Offset(0.45, 0.17)),
        text.text.length - 1,
      );
    });

    test('a point above the first line clamps to the first character', () {
      expect(text.characterNear(const Offset(0.0, 0.0)), 0);
    });

    test('a point farther than maxDistance finds nothing', () {
      expect(
        text.characterNear(const Offset(0.9, 0.9), maxDistance: 0.05),
        isNull,
      );
    });

    test('a point over whitespace finds the closest letter instead', () {
      final overSpace = text.text.indexOf(' ');

      final index = text.characterNear(centerOf(overSpace));

      expect(text.text[index!].trim(), isNotEmpty);
    });

    test('text without letters finds nothing', () {
      final blank = pageTextFromLines(['   ']);

      expect(blank.characterNear(const Offset(0.15, 0.115)), isNull);
    });

    test('a page without text finds nothing', () {
      expect(
        ReaderPageText.empty.characterNear(const Offset(0.5, 0.5)),
        isNull,
      );
    });
  });

  group('wordAt', () {
    test('expands to the whole word around any of its letters', () {
      final start = text.text.indexOf('big');

      for (final offset in [0, 1, 2]) {
        expect(
          text.wordAt(start + offset),
          ReaderTextSelection(start: start, end: start + 3),
        );
      }
    });

    test('stops at a line break', () {
      final word = text.wordAt(text.text.indexOf('world'))!;

      expect(text.textOf(word), 'world');
    });

    test('a space is not part of any word', () {
      expect(text.wordAt(text.text.indexOf(' ')), isNull);
    });

    test('an index outside the text is not part of any word', () {
      expect(text.wordAt(-1), isNull);
      expect(text.wordAt(text.text.length), isNull);
    });
  });

  group('textOf', () {
    test('joins a range that spans lines in reading order', () {
      final from = text.text.indexOf('big');
      final to = text.text.indexOf('second') + 5;

      final selected = text.textOf(ReaderTextSelection.between(to, from));

      expect(selected, 'big world\nsecond');
    });

    test('drops surrounding whitespace', () {
      final selection = ReaderTextSelection.between(5, 9);

      expect(text.textOf(selection), 'big');
    });
  });

  group('lineBoundsOf', () {
    test('a range within one line is one box around its letters', () {
      final start = text.text.indexOf('big');

      final lines = text.lineBoundsOf(
        ReaderTextSelection(start: start, end: start + 3),
      );

      expect(lines, hasLength(1));
      expect(lines.single.left, closeTo(0.1 + 6 * 0.03, 1e-9));
      expect(lines.single.width, closeTo(3 * 0.03, 1e-9));
    });

    test('a range across lines is one box per line, in reading order', () {
      final lines = text.lineBoundsOf(
        ReaderTextSelection(start: text.text.indexOf('world'), end: 27),
      );

      expect(lines, hasLength(2));
      expect(lines.first.top, lessThan(lines.last.top));
    });

    test('the line break itself adds no box', () {
      final breakIndex = text.text.indexOf('\n');

      final lines = text.lineBoundsOf(
        ReaderTextSelection(start: breakIndex, end: breakIndex + 1),
      );

      expect(lines, isEmpty);
    });
  });
}
