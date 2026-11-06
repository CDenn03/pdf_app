import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/reader_page_text.dart';
import 'paged_reader_harness.dart';

const _left = 0.1;
const _top = 0.1;
const _characterWidth = 0.03;
const _lineHeight = 0.03;
const _lineStep = 0.05;

/// Text laid out left to right, one line per entry; line breaks have no
/// extent, like the ones pdfrx reports.
ReaderPageText pageTextFromLines(List<String> lines) {
  final bounds = <Rect>[];
  for (final (row, line) in lines.indexed) {
    final top = _top + row * _lineStep;
    for (var column = 0; column < line.length; column++) {
      bounds.add(
        Rect.fromLTWH(
          _left + column * _characterWidth,
          top,
          _characterWidth,
          _lineHeight,
        ),
      );
    }
    if (row < lines.length - 1) {
      final end = _left + line.length * _characterWidth;
      bounds.add(Rect.fromLTRB(end, top, end, top + _lineHeight));
    }
  }
  return ReaderPageText(text: lines.join('\n'), characterBounds: bounds);
}

/// Where the character at [index] of [text] sits on the rendered page.
Offset screenCenterOf(
  WidgetTester tester, {
  required int page,
  required ReaderPageText text,
  required int index,
}) {
  final rect = tester.getRect(find.byKey(rasterKey(page)));
  final center = text.characterBounds[index].center;
  return rect.topLeft + Offset(rect.width * center.dx, rect.height * center.dy);
}
