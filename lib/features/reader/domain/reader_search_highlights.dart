import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/domain/reader_page_match.dart';

abstract interface class ReaderSearchHighlights implements Listenable {
  List<ReaderPageMatch> matchesOnPage(int pageNumber);

  ReaderPageMatch? get activeMatch;
}
