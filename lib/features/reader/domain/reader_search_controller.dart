import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/domain/search_excerpt.dart';

@immutable
class FindMatch {
  const FindMatch({required this.page, required this.excerpt});

  final int page;
  final SearchExcerpt excerpt;
}

abstract interface class ReaderSearchController implements Listenable {
  List<FindMatch> get matches;
  int? get currentIndex;
  bool get isSearching;

  void startTextSearch(String query);
  void resetTextSearch();

  Future<void> goToMatchAt(int index, {required double chromeMargin});
  Future<void> goToNextMatch({required double chromeMargin});
  Future<void> goToPreviousMatch({required double chromeMargin});
}
