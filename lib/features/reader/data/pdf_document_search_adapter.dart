import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/pdfrx_page_scan.dart';
import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/reader_search_backend.dart';

/// Searches a loaded [PdfDocument] directly, for viewers that have no
/// pdfrx viewer controller. It never places a viewer, so callers navigate to
/// the match's page.
class PdfDocumentSearchAdapter implements ReaderSearchBackend {
  PdfDocumentSearchAdapter({required PdfDocument document})
    : _document = document;

  final PdfDocument _document;

  @override
  Stream<List<ReaderPageMatch>> search(String query) => scanPages(
    pageCount: _document.pages.length,
    matchesOn: (pageNumber) =>
        findMatchesOnPage(_document.pages[pageNumber - 1], query),
  );

  @override
  Future<bool> reveal(ReaderPageMatch match, {required double margin}) async =>
      false;
}
