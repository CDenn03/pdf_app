import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/reader_search_highlights.dart';

class FakeSearchHighlights extends ChangeNotifier
    implements ReaderSearchHighlights {
  List<ReaderPageMatch> _matches = const [];
  ReaderPageMatch? _activeMatch;

  @override
  ReaderPageMatch? get activeMatch => _activeMatch;

  @override
  List<ReaderPageMatch> matchesOnPage(int pageNumber) => [
    for (final match in _matches)
      if (match.pageNumber == pageNumber) match,
  ];

  void show(List<ReaderPageMatch> matches, {ReaderPageMatch? active}) {
    _matches = matches;
    _activeMatch = active;
    notifyListeners();
  }

  void change() => notifyListeners();
}
