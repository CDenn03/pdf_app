import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/presentation/pdf_viewer_page_navigation.dart';

class _FakeViewerController extends PdfViewerController {
  _FakeViewerController({this.totalPages = 10});

  bool ready = true;
  final int totalPages;
  int? visiblePage = 1;
  final List<int> viewerRequests = [];

  @override
  bool get isReady => ready;

  @override
  int get pageCount => totalPages;

  @override
  int? get pageNumber => visiblePage;

  @override
  Future<void> goToPage({
    required int pageNumber,
    PdfPageAnchor? anchor,
    Duration duration = const Duration(milliseconds: 200),
  }) async {
    viewerRequests.add(pageNumber);
    visiblePage = pageNumber;
  }
}

void main() {
  late _FakeViewerController viewer;
  late PdfViewerPageNavigation navigation;

  setUp(() {
    viewer = _FakeViewerController();
    navigation = PdfViewerPageNavigation(controller: viewer);
  });

  group('goToPage', () {
    test('forwards an in-range one-based page number to the viewer', () async {
      await navigation.goToPage(4);

      expect(viewer.viewerRequests, [4]);
    });

    test('clamps a page below the first page to page 1', () async {
      await navigation.goToPage(0);

      expect(viewer.viewerRequests, [1]);
    });

    test('clamps a page beyond the last page to the last page', () async {
      await navigation.goToPage(99);

      expect(viewer.viewerRequests, [10]);
    });

    test('does nothing while the viewer is not attached', () async {
      viewer.ready = false;

      await navigation.goToPage(4);

      expect(viewer.viewerRequests, isEmpty);
    });

    test('does nothing for a document without pages', () async {
      final empty = _FakeViewerController(totalPages: 0);

      await PdfViewerPageNavigation(controller: empty).goToPage(1);

      expect(empty.viewerRequests, isEmpty);
    });
  });

  group('currentPage', () {
    test('reports the page the viewer shows', () {
      viewer.visiblePage = 6;

      expect(navigation.currentPage, 6);
    });

    test('reports page 1 while the viewer is not attached', () {
      viewer
        ..ready = false
        ..visiblePage = 6;

      expect(navigation.currentPage, 1);
    });

    test('reports page 1 when the viewer has no page yet', () {
      viewer.visiblePage = null;

      expect(navigation.currentPage, 1);
    });
  });

  test('a real unattached controller is safe to navigate', () async {
    final unattached = PdfViewerPageNavigation(
      controller: PdfViewerController(),
    );

    await unattached.goToPage(3);

    expect(unattached.currentPage, 1);
  });
}
