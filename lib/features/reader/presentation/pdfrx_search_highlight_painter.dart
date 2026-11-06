import 'dart:ui';

import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/domain/reader_search_highlights.dart';
import 'package:sefer/features/reader/presentation/search_match_paint.dart';

class PdfrxSearchHighlightPainter {
  PdfrxSearchHighlightPainter({
    required ReaderSearchHighlights highlights,
    required Color matchColor,
    required Color activeMatchColor,
  }) : _highlights = highlights,
       _matchColor = matchColor,
       _activeMatchColor = activeMatchColor;

  final ReaderSearchHighlights _highlights;
  final Color _matchColor;
  final Color _activeMatchColor;

  void paint(Canvas canvas, Rect pageRect, PdfPage page) => paintSearchMatches(
    canvas: canvas,
    pageRect: pageRect,
    matches: _highlights.matchesOnPage(page.pageNumber),
    activeMatch: _highlights.activeMatch,
    matchColor: _matchColor,
    activeMatchColor: _activeMatchColor,
  );
}
