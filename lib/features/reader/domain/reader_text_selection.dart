import 'package:flutter/foundation.dart';

/// A run of characters on one page, as indexes into [ReaderPageText.text].
@immutable
class ReaderTextSelection {
  const ReaderTextSelection({required this.start, required this.end})
    : assert(start >= 0 && start < end);

  /// The selection covering both characters and everything between them,
  /// whichever comes first in reading order.
  factory ReaderTextSelection.between(int first, int second) =>
      ReaderTextSelection(
        start: first < second ? first : second,
        end: (first < second ? second : first) + 1,
      );

  /// Index of the first selected character.
  final int start;

  /// Index just past the last selected character.
  final int end;

  int get lastIndex => end - 1;

  /// Grows this selection to reach [index]; an index inside it changes
  /// nothing.
  ReaderTextSelection extendedTo(int index) {
    if (index < start) return ReaderTextSelection.between(lastIndex, index);
    if (index >= end) return ReaderTextSelection.between(start, index);
    return this;
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderTextSelection && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ReaderTextSelection($start, $end)';
}
