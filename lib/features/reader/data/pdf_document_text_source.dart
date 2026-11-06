import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/pdfrx_page_bounds.dart';
import 'package:sefer/features/reader/domain/reader_page_text.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';

class PdfDocumentTextSource implements ReaderPageTextSource {
  PdfDocumentTextSource({required PdfDocument document}) : _document = document;

  final PdfDocument _document;

  @override
  Future<ReaderPageText> textOn(int pageNumber) async {
    final page = _document.pages[pageNumber - 1];
    final structured = await page.loadStructuredText();
    return ReaderPageText(
      text: structured.fullText,
      characterBounds: [
        for (final rect in structured.charRects)
          normalizePageBounds(rect, page),
      ],
    );
  }
}
