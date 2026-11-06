import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/search_excerpt.dart';
import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/reader_search_highlights.dart';
import 'package:sefer/features/reader/presentation/pdfrx_search_highlight_painter.dart';
import '../support/fake_pdfrx_page.dart';

class _FixedHighlights extends ChangeNotifier
    implements ReaderSearchHighlights {
  _FixedHighlights(this.matches, {this.activeMatch});

  final List<ReaderPageMatch> matches;

  @override
  final ReaderPageMatch? activeMatch;

  @override
  List<ReaderPageMatch> matchesOnPage(int pageNumber) => [
    for (final match in matches)
      if (match.pageNumber == pageNumber) match,
  ];
}

class _RecordingCanvas implements Canvas {
  final List<(Rect, Color)> rects = [];

  @override
  void drawRect(Rect rect, Paint paint) => rects.add((rect, paint.color));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

const _plain = Color(0x10FF0000);
const _active = Color(0x2000FF00);

ReaderPageMatch _match(int page, Rect bounds) => ReaderPageMatch(
  pageNumber: page,
  excerpt: const SearchExcerpt.plain('hit'),
  normalizedBounds: [bounds],
);

void main() {
  final page = FakePdfrxPage(width: 100, height: 200, pageNumber: 3);
  const pageRect = Rect.fromLTWH(10, 20, 100, 200);

  PdfrxSearchHighlightPainter painterFor(_FixedHighlights highlights) =>
      PdfrxSearchHighlightPainter(
        highlights: highlights,
        matchColor: _plain,
        activeMatchColor: _active,
      );

  test('a match is painted scaled into the page rectangle', () {
    final canvas = _RecordingCanvas();
    final highlights = _FixedHighlights([
      _match(3, const Rect.fromLTRB(0.1, 0.25, 0.5, 0.5)),
    ]);

    painterFor(highlights).paint(canvas, pageRect, page);

    expect(canvas.rects.single.$1, const Rect.fromLTRB(20, 70, 60, 120));
  });

  test('matches on other pages are not painted', () {
    final canvas = _RecordingCanvas();
    final highlights = _FixedHighlights([
      _match(4, const Rect.fromLTRB(0, 0, 1, 1)),
    ]);

    painterFor(highlights).paint(canvas, pageRect, page);

    expect(canvas.rects, isEmpty);
  });

  test('the active match uses the active colour and others the plain one', () {
    final canvas = _RecordingCanvas();
    final first = _match(3, const Rect.fromLTRB(0, 0, 0.5, 0.1));
    final second = _match(3, const Rect.fromLTRB(0, 0.5, 0.5, 0.6));
    final highlights = _FixedHighlights([first, second], activeMatch: second);

    painterFor(highlights).paint(canvas, pageRect, page);

    expect(canvas.rects.map((r) => r.$2.toARGB32()).toList(), [
      _plain.toARGB32(),
      _active.toARGB32(),
    ]);
  });
}
