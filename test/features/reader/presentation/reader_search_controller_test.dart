import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/presentation/reader_search_controller.dart';

void _noopPaint(Canvas canvas, Rect pageRect, PdfPage page) {}

class _FakeSearch extends ChangeNotifier implements ReaderSearchController {
  @override
  List<FindMatch> get matches => const [];

  @override
  int? get currentIndex => null;

  @override
  bool get isSearching => false;

  @override
  void startTextSearch(String query) {}

  @override
  void resetTextSearch() {}

  @override
  Future<void> goToMatchAt(int index, {required double chromeMargin}) async {}

  @override
  PdfViewerPagePaintCallback get paintCallback => _noopPaint;
}

void main() {
  test('is null before the searcher exists', () {
    expect(readerPagePaintCallbacks(null), isNull);
  });

  test('is non-empty and contains the searcher paint callback', () {
    final search = _FakeSearch();
    final callbacks = readerPagePaintCallbacks(search);
    expect(callbacks, isNotNull);
    expect(callbacks, isNotEmpty);
    expect(callbacks, contains(search.paintCallback));
  });
}
