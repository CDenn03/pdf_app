import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

/// A single search hit as the find bar needs it: the page it is on and a
/// short snippet of the matched text. Decouples the UI from pdfrx's
/// [PdfPageTextRange] so the find bar can be tested with plain data.
@immutable
class FindMatch {
  const FindMatch({required this.page, required this.snippet});

  final int page;
  final String snippet;
}

/// Search surface the find bar depends on, so the bar can be driven by a fake
/// in tests without a live [PdfTextSearcher] (which needs a ready controller).
abstract class ReaderSearchController implements Listenable {
  List<FindMatch> get matches;
  int? get currentIndex;
  bool get isSearching;

  void startTextSearch(String query);
  void resetTextSearch();

  /// Jumps to the match at [index] and makes it visible clear of the find
  /// chrome. [chromeMargin] is the space to keep around the match.
  Future<void> goToMatchAt(int index, {required double chromeMargin});

  /// The pdfrx paint callback that draws matches; registered in
  /// [PdfViewerParams.pagePaintCallbacks].
  PdfViewerPagePaintCallback get paintCallback;
}

/// The `pagePaintCallbacks` list the reader hands pdfrx: the searcher's paint
/// callback once the searcher exists, or null before the viewer is ready.
List<PdfViewerPagePaintCallback>? readerPagePaintCallbacks(
  ReaderSearchController? search,
) =>
    search == null ? null : [search.paintCallback];

/// Production adapter wrapping a real [PdfTextSearcher].
class PdfTextSearcherController implements ReaderSearchController {
  PdfTextSearcherController(this._searcher, this._controller);

  final PdfTextSearcher _searcher;
  final PdfViewerController _controller;

  @override
  List<FindMatch> get matches => [
        for (final m in _searcher.matches)
          FindMatch(page: m.pageNumber, snippet: m.text),
      ];

  @override
  int? get currentIndex => _searcher.currentIndex;

  @override
  bool get isSearching => _searcher.isSearching;

  @override
  void startTextSearch(String query) => _searcher.startTextSearch(query);

  @override
  void resetTextSearch() => _searcher.resetTextSearch();

  @override
  Future<void> goToMatchAt(int index, {required double chromeMargin}) async {
    final all = _searcher.matches;
    if (index < 0 || index >= all.length) return;
    final match = all[index];
    unawaited(_searcher.goToMatch(match));
    await _controller.ensureVisible(
      _controller.calcRectForRectInsidePage(
        pageNumber: match.pageNumber,
        rect: match.bounds,
      ),
      margin: chromeMargin,
    );
  }

  @override
  PdfViewerPagePaintCallback get paintCallback =>
      _searcher.pageTextMatchPaintCallback;

  @override
  void addListener(VoidCallback listener) => _searcher.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _searcher.removeListener(listener);

  void dispose() => _searcher.dispose();
}
