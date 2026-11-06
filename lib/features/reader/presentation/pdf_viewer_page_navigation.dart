import 'package:pdfrx/pdfrx.dart' show PdfViewerController;

import 'package:sefer/features/reader/domain/page_range.dart';
import 'package:sefer/features/reader/domain/reader_page_navigation.dart';

class PdfViewerPageNavigation implements ReaderPageNavigation {
  PdfViewerPageNavigation({required PdfViewerController controller})
    : _controller = controller;

  final PdfViewerController _controller;

  @override
  int get currentPage => _controller.isReady ? _controller.pageNumber ?? 1 : 1;

  @override
  Future<void> goToPage(int pageNumber) async {
    if (!_controller.isReady || _controller.pageCount < 1) return;
    final target = PageRange(_controller.pageCount).clamp(pageNumber);
    await _controller.goToPage(pageNumber: target);
  }
}
