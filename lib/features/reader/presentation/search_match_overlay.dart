import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/reader_search_highlights.dart';
import 'package:sefer/features/reader/presentation/reader_page_geometry.dart';
import 'package:sefer/features/reader/presentation/search_match_paint.dart';

class SearchMatchOverlay extends StatelessWidget {
  const SearchMatchOverlay({
    super.key,
    required this.geometry,
    required this.highlights,
    required this.matchColor,
    required this.activeMatchColor,
  });

  final ReaderPageGeometry geometry;
  final ReaderSearchHighlights highlights;
  final Color matchColor;
  final Color activeMatchColor;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: highlights,
    builder: (context, _) {
      final matches = highlights.matchesOnPage(geometry.pageNumber);
      if (matches.isEmpty) return const SizedBox.shrink();
      return IgnorePointer(
        child: CustomPaint(
          size: geometry.renderedRect.size,
          painter: _SearchMatchPainter(
            matches: matches,
            activeMatch: highlights.activeMatch,
            matchColor: matchColor,
            activeMatchColor: activeMatchColor,
          ),
        ),
      );
    },
  );
}

class _SearchMatchPainter extends CustomPainter {
  _SearchMatchPainter({
    required this.matches,
    required this.activeMatch,
    required this.matchColor,
    required this.activeMatchColor,
  });

  final List<ReaderPageMatch> matches;
  final ReaderPageMatch? activeMatch;
  final Color matchColor;
  final Color activeMatchColor;

  @override
  void paint(Canvas canvas, Size size) => paintSearchMatches(
    canvas: canvas,
    pageRect: Offset.zero & size,
    matches: matches,
    activeMatch: activeMatch,
    matchColor: matchColor,
    activeMatchColor: activeMatchColor,
  );

  @override
  bool shouldRepaint(_SearchMatchPainter oldDelegate) =>
      oldDelegate.matches != matches ||
      oldDelegate.activeMatch != activeMatch ||
      oldDelegate.matchColor != matchColor ||
      oldDelegate.activeMatchColor != activeMatchColor;
}
