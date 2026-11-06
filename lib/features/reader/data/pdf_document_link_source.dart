import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/pdfrx_page_bounds.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';

class PdfDocumentLinkSource implements ReaderPageLinkSource {
  PdfDocumentLinkSource({required PdfDocument document}) : _document = document;

  final PdfDocument _document;

  @override
  Future<List<ReaderPageLink>> linksOn(int pageNumber) async {
    final page = _document.pages[pageNumber - 1];
    final links = await page.loadLinks();
    return [
      for (final link in links)
        if (_targetOf(link) case final target?)
          ReaderPageLink(
            target: target,
            normalizedBounds: [
              for (final rect in link.rects) normalizePageBounds(rect, page),
            ],
          ),
    ];
  }

  ReaderLinkTarget? _targetOf(PdfLink link) {
    final destination = link.dest;
    if (destination != null) return PageLinkTarget(destination.pageNumber);
    final uri = link.url;
    return uri == null ? null : UriLinkTarget(uri);
  }
}
