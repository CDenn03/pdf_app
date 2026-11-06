import 'dart:math' as math;
import 'dart:ui';

import 'package:sefer/features/reader/domain/reader_text_selection.dart';

/// One page's text in reading order, with each character's box.
class ReaderPageText {
  ReaderPageText({required this.text, required this.characterBounds})
    : assert(text.length == characterBounds.length);

  static final empty = ReaderPageText(text: '', characterBounds: const []);

  final String text;

  /// Fractions (0..1) of the upright page's width and height, with the origin
  /// at the page's top-left corner and y growing downwards. A character with
  /// no extent, such as a line break, has an empty rect.
  final List<Rect> characterBounds;

  /// The selectable character closest to [point] (same fractional space as
  /// [characterBounds]), or null when none lies within [maxDistance].
  int? characterNear(Offset point, {double maxDistance = double.infinity}) {
    int? nearest;
    var nearestDistance = double.infinity;
    for (var index = 0; index < text.length; index++) {
      if (!_isSelectable(index)) continue;
      final distance = _distanceToRect(point, characterBounds[index]);
      if (distance <= maxDistance && distance < nearestDistance) {
        nearest = index;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  /// The run of non-whitespace characters containing [index].
  ReaderTextSelection? wordAt(int index) {
    if (index < 0 || index >= text.length || _isWhitespace(index)) return null;
    var start = index;
    var end = index + 1;
    while (start > 0 && !_isWhitespace(start - 1)) {
      start--;
    }
    while (end < text.length && !_isWhitespace(end)) {
      end++;
    }
    return ReaderTextSelection(start: start, end: end);
  }

  String textOf(ReaderTextSelection selection) =>
      text.substring(selection.start, selection.end).trim();

  /// One box per visual line the selection covers, in reading order.
  List<Rect> lineBoundsOf(ReaderTextSelection selection) {
    final lines = <Rect>[];
    for (var index = selection.start; index < selection.end; index++) {
      final bounds = characterBounds[index];
      if (bounds.isEmpty) continue;
      if (lines.isNotEmpty && _sharesLine(lines.last, bounds)) {
        lines.last = lines.last.expandToInclude(bounds);
      } else {
        lines.add(bounds);
      }
    }
    return lines;
  }

  bool _isSelectable(int index) =>
      !_isWhitespace(index) && !characterBounds[index].isEmpty;

  bool _isWhitespace(int index) => text[index].trim().isEmpty;

  static bool _sharesLine(Rect line, Rect character) {
    final overlap =
        math.min(line.bottom, character.bottom) -
        math.max(line.top, character.top);
    return overlap > 0.5 * math.min(line.height, character.height);
  }

  static double _distanceToRect(Offset point, Rect rect) {
    final dx = math.max(
      math.max(rect.left - point.dx, point.dx - rect.right),
      0,
    );
    final dy = math.max(
      math.max(rect.top - point.dy, point.dy - rect.bottom),
      0,
    );
    return math.sqrt(dx * dx + dy * dy);
  }
}
