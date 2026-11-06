import 'dart:ui';

import 'package:sefer/features/reader/domain/reader_page_match.dart';

void paintSearchMatches({
  required Canvas canvas,
  required Rect pageRect,
  required List<ReaderPageMatch> matches,
  required ReaderPageMatch? activeMatch,
  required Color matchColor,
  required Color activeMatchColor,
}) {
  for (final match in matches) {
    final paint = Paint()
      ..color = match == activeMatch ? activeMatchColor : matchColor;
    for (final bounds in match.normalizedBounds) {
      canvas.drawRect(_inPage(bounds, pageRect), paint);
    }
  }
}

Rect _inPage(Rect normalized, Rect pageRect) => Rect.fromLTRB(
  pageRect.left + normalized.left * pageRect.width,
  pageRect.top + normalized.top * pageRect.height,
  pageRect.left + normalized.right * pageRect.width,
  pageRect.top + normalized.bottom * pageRect.height,
);
