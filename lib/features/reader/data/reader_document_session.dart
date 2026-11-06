import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/pdf_document_link_source.dart';
import 'package:sefer/features/reader/data/pdf_document_search_adapter.dart';
import 'package:sefer/features/reader/data/pdf_document_text_source.dart';
import 'package:sefer/features/reader/domain/caching_page_link_source.dart';
import 'package:sefer/features/reader/domain/caching_page_text_source.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';
import 'package:sefer/features/reader/domain/reader_search_backend.dart';

class ReaderDocumentSession {
  ReaderDocumentSession({required this.document})
    : searchBackend = PdfDocumentSearchAdapter(document: document),
      linkSource = CachingPageLinkSource(
        source: PdfDocumentLinkSource(document: document),
      ),
      textSource = CachingPageTextSource(
        source: PdfDocumentTextSource(document: document),
      );

  final PdfDocument document;
  final ReaderSearchBackend searchBackend;
  final ReaderPageLinkSource linkSource;
  final ReaderPageTextSource textSource;

  int get pageCount => document.pages.length;
}
