import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/pdfrx_page_bounds.dart';
import 'package:sefer/features/reader/data/pdfrx_page_scan.dart';
import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/reader_search_backend.dart';

class PdfrxSearchAdapter implements ReaderSearchBackend {
  PdfrxSearchAdapter({required PdfViewerController viewer}) : _viewer = viewer;

  final PdfViewerController _viewer;

  @override
  Stream<List<ReaderPageMatch>> search(String query) => scanPages(
    pageCount: _viewer.isReady ? _viewer.pageCount : 0,
    matchesOn: (pageNumber) => _matchesOnPage(query, pageNumber),
  );

  @override
  Future<bool> reveal(ReaderPageMatch match, {required double margin}) async {
    if (!_viewer.isReady || match.normalizedBounds.isEmpty) return false;
    final page = _viewer.document.pages[match.pageNumber - 1];
    final pdfBounds = pageBoundsFromNormalized(
      match.normalizedBounds.first,
      page,
    );
    await _viewer.ensureVisible(
      _viewer.calcRectForRectInsidePage(
        pageNumber: match.pageNumber,
        rect: pdfBounds,
      ),
      margin: margin,
    );
    _viewer.setCurrentPageNumber(match.pageNumber);
    _viewer.invalidate();
    return true;
  }

  void invalidate() {
    if (_viewer.isReady) _viewer.invalidate();
  }

  Future<List<ReaderPageMatch>> _matchesOnPage(
    String query,
    int pageNumber,
  ) async {
    final matches = await _viewer.useDocument(
      (document) => findMatchesOnPage(document.pages[pageNumber - 1], query),
    );
    return matches ?? const [];
  }
}
