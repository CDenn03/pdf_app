import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:sefer/features/reader/data/pdf_document_link_source.dart';
import 'package:sefer/features/reader/data/pdf_document_search_adapter.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';
import '../support/pdfium_support.dart';

Future<PdfDocument> _openTwoPageDocument({bool withUriLink = false}) async {
  final document = sf.PdfDocument();
  final first = document.pages.add();
  final second = document.pages.add();
  final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 14);
  first.graphics.drawString(
    'intro needle here',
    font,
    bounds: const ui.Rect.fromLTWH(50, 100, 450, 30),
  );
  second.graphics.drawString(
    'second needle and needle',
    font,
    bounds: const ui.Rect.fromLTWH(50, 100, 450, 30),
  );
  first.annotations.add(
    sf.PdfDocumentLinkAnnotation(
      const ui.Rect.fromLTWH(50, 300, 100, 20),
      sf.PdfDestination(second, const ui.Offset(0, 0)),
    ),
  );
  if (withUriLink) {
    second.annotations.add(
      sf.PdfUriAnnotation(
        bounds: const ui.Rect.fromLTWH(50, 300, 100, 20),
        uri: 'https://example.com/docs',
      ),
    );
  }
  final bytes = Uint8List.fromList(await document.save());
  document.dispose();
  return PdfDocument.openData(bytes);
}

void main() {
  final pdfiumPath = findPdfiumLibrary();
  final skipReason = pdfiumPath == null
      ? 'pdfium native module not found'
      : null;

  setUpAll(() => Pdfrx.pdfiumModulePath = pdfiumPath);

  group('PdfDocumentSearchAdapter', () {
    test('scans every page and reports matches in page order', () async {
      final document = await _openTwoPageDocument();
      addTearDown(document.dispose);
      final adapter = PdfDocumentSearchAdapter(document: document);

      final perPage = await adapter.search('needle').toList();

      expect([for (final page in perPage) page.length], [1, 2]);
      expect(perPage[1].first.pageNumber, 2);
    });

    test('match bounds are normalized fractions of the page', () async {
      final document = await _openTwoPageDocument();
      addTearDown(document.dispose);
      final adapter = PdfDocumentSearchAdapter(document: document);

      final perPage = await adapter.search('needle').toList();

      final bounds = perPage.first.single.normalizedBounds.single;
      expect(bounds.left, inInclusiveRange(0.0, 1.0));
      expect(bounds.top, lessThan(0.5));
    });

    test('never places the viewer itself', () async {
      final document = await _openTwoPageDocument();
      addTearDown(document.dispose);
      final adapter = PdfDocumentSearchAdapter(document: document);
      final match = (await adapter.search('needle').first).first;

      expect(await adapter.reveal(match, margin: 0), isFalse);
    });
  }, skip: skipReason);

  group('PdfDocumentLinkSource', () {
    test('returns an internal link with its destination page', () async {
      final document = await _openTwoPageDocument();
      addTearDown(document.dispose);
      final source = PdfDocumentLinkSource(document: document);

      final links = await source.linksOn(1);

      expect(links.single.target, const PageLinkTarget(2));
      final bounds = links.single.normalizedBounds.single;
      expect(bounds.left, inInclusiveRange(0.0, 1.0));
      expect(bounds.bottom, inInclusiveRange(0.0, 1.0));
    });

    test('returns an external link with its URI', () async {
      final document = await _openTwoPageDocument(withUriLink: true);
      addTearDown(document.dispose);
      final source = PdfDocumentLinkSource(document: document);

      final links = await source.linksOn(2);

      expect(
        links.single.target,
        UriLinkTarget(Uri.parse('https://example.com/docs')),
      );
      expect(links.single.normalizedBounds, hasLength(1));
    });

    test('a page without links returns none', () async {
      final document = await _openTwoPageDocument();
      addTearDown(document.dispose);
      final source = PdfDocumentLinkSource(document: document);

      expect(await source.linksOn(2), isEmpty);
    });
  }, skip: skipReason);
}
