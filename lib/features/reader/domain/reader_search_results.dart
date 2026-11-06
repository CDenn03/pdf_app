import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/domain/reader_page_match.dart';

@immutable
class ReaderSearchResults {
  ReaderSearchResults(Iterable<ReaderPageMatch> matches)
    : matches = List.unmodifiable(matches),
      _matchesByPage = _groupByPage(matches);

  static final empty = ReaderSearchResults(const []);

  final List<ReaderPageMatch> matches;
  final Map<int, List<ReaderPageMatch>> _matchesByPage;

  bool get isEmpty => matches.isEmpty;

  List<ReaderPageMatch> onPage(int pageNumber) =>
      _matchesByPage[pageNumber] ?? const [];

  ReaderSearchResults including(Iterable<ReaderPageMatch> more) =>
      ReaderSearchResults([...matches, ...more]);

  int nextIndex(int? activeIndex) =>
      activeIndex == null ? 0 : (activeIndex + 1) % matches.length;

  int previousIndex(int? activeIndex) => activeIndex == null || activeIndex <= 0
      ? matches.length - 1
      : activeIndex - 1;

  static Map<int, List<ReaderPageMatch>> _groupByPage(
    Iterable<ReaderPageMatch> matches,
  ) {
    final grouped = <int, List<ReaderPageMatch>>{};
    for (final match in matches) {
      grouped.putIfAbsent(match.pageNumber, () => []).add(match);
    }
    return Map.unmodifiable({
      for (final entry in grouped.entries)
        entry.key: List<ReaderPageMatch>.unmodifiable(entry.value),
    });
  }
}
