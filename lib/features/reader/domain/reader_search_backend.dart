import 'package:sefer/features/reader/domain/reader_page_match.dart';

abstract interface class ReaderSearchBackend {
  /// Emits the matches of each page, in page order, as that page is scanned.
  Stream<List<ReaderPageMatch>> search(String query);

  /// Brings [match] into view. Returns false when the backend cannot place
  /// the viewer itself and the caller should navigate to the match's page.
  Future<bool> reveal(ReaderPageMatch match, {required double margin});
}
