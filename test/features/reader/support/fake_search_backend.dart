import 'dart:async';

import 'package:sefer/features/reader/domain/search_excerpt.dart';
import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/reader_search_backend.dart';

class FakeSearchBackend implements ReaderSearchBackend {
  final List<String> queries = [];
  final List<StreamController<List<ReaderPageMatch>>> scans = [];
  final List<ReaderPageMatch> revealed = [];
  bool canPlaceViewer = true;

  StreamController<List<ReaderPageMatch>> get latestScan => scans.last;

  @override
  Stream<List<ReaderPageMatch>> search(String query) {
    queries.add(query);
    final scan = StreamController<List<ReaderPageMatch>>();
    scans.add(scan);
    return scan.stream;
  }

  @override
  Future<bool> reveal(ReaderPageMatch match, {required double margin}) async {
    revealed.add(match);
    return canPlaceViewer;
  }
}

ReaderPageMatch matchOnPage(int pageNumber, [String snippet = 'hit']) =>
    ReaderPageMatch(
      pageNumber: pageNumber,
      excerpt: SearchExcerpt.plain('$snippet-$pageNumber'),
      normalizedBounds: const [],
    );
