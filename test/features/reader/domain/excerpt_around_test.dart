import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/excerpt_around.dart';
import 'package:sefer/features/reader/domain/search_excerpt.dart';

SearchExcerpt _around(String text, String needle, {int maxContext = 90}) {
  final start = text.toLowerCase().indexOf(needle.toLowerCase());
  return excerptAround(
    text,
    start,
    start + needle.length,
    maxContext: maxContext,
  );
}

void main() {
  test('prefers the containing sentence', () {
    final excerpt = _around('First one. The cat sat down. Last one.', 'cat');

    expect(excerpt.before, 'The ');
    expect(excerpt.match, 'cat');
    expect(excerpt.after, ' sat down.');
    expect(excerpt.hasLeadingEllipsis, isFalse);
    expect(excerpt.hasTrailingEllipsis, isFalse);
  });

  test('does not split on decimal points', () {
    final excerpt = _around('Pi is 3.14 roughly. Done.', 'roughly');

    expect(excerpt.before, 'Pi is 3.14 ');
  });

  test('falls back to a word-aligned window without punctuation', () {
    final text = '${'alpha ' * 40}NEEDLE${' omega' * 40}';
    final excerpt = _around(text, 'NEEDLE', maxContext: 20);

    expect(excerpt.hasLeadingEllipsis, isTrue);
    expect(excerpt.hasTrailingEllipsis, isTrue);
    expect(excerpt.before.trim().split(' ').every((w) => w == 'alpha'), isTrue);
    expect(excerpt.after.trim().split(' ').every((w) => w == 'omega'), isTrue);
    expect(excerpt.before.length, lessThanOrEqualTo(20));
    expect(excerpt.after.length, lessThanOrEqualTo(20));
  });

  test('uses a window when the sentence is too long', () {
    final text = 'x ${'word ' * 60}hit ${'tail ' * 60}end.';
    final excerpt = _around(text, 'hit', maxContext: 30);

    expect(excerpt.hasLeadingEllipsis, isTrue);
    expect(excerpt.hasTrailingEllipsis, isTrue);
  });

  test('match at the start and end of the page has no ellipsis', () {
    expect(_around('needle here', 'needle').hasLeadingEllipsis, isFalse);
    final end = _around('here needle', 'needle');
    expect(end.after, '');
    expect(end.hasTrailingEllipsis, isFalse);
  });

  test('repeated terms use the supplied offsets', () {
    const text = 'Cat one. Cat two.';
    final excerpt = excerptAround(text, 9, 12);

    expect(excerpt.before, '');
    expect(excerpt.after, ' two.');
  });

  test('collapses line breaks while keeping match boundaries', () {
    final excerpt = _around(
      'The  quick\nbrown   fox\njumps.',
      'brown fox'.replaceAll(' ', '   '),
    );

    expect(excerpt.before, 'The quick ');
    expect(excerpt.match, 'brown fox');
    expect(excerpt.after, ' jumps.');
  });

  test('double newline is a paragraph boundary', () {
    final excerpt = _around('Intro text\n\nThe needle line\n\nOutro', 'needle');

    expect(excerpt.before, 'The ');
    expect(excerpt.after, ' line');
  });

  test('de-hyphenates words split across lines', () {
    final excerpt = _around('A long-\nrunning needle appears.', 'needle');

    expect(excerpt.before, 'A longrunning ');
  });

  test('case-insensitive multi-word match keeps original text', () {
    final excerpt = _around('See The Red Fox run.', 'the red fox');

    expect(excerpt.match, 'The Red Fox');
    expect(excerpt.before, 'See ');
  });

  test('handles non-Latin text and ideographic full stops', () {
    final excerpt = _around('前の文。これは検索語です。次の文。', '検索語');

    expect(excerpt.before, 'これは');
    expect(excerpt.after, 'です。');
  });

  test('windows unspaced text exactly at the context limit', () {
    final excerpt = _around('${'あ' * 50}検索${'い' * 50}', '検索', maxContext: 5);

    expect(excerpt.before, 'あ' * 5);
    expect(excerpt.after, 'い' * 5);
    expect(excerpt.hasLeadingEllipsis, isTrue);
  });

  test('empty page text yields an empty excerpt', () {
    final excerpt = excerptAround('', 0, 0);

    expect(excerpt.fullText, '');
  });
}
