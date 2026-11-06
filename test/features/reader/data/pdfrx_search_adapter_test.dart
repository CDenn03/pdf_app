import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:sefer/features/reader/data/pdfrx_page_bounds.dart';
import 'package:sefer/features/reader/data/pdfrx_page_scan.dart';
import '../support/pdfium_support.dart';

Future<PdfDocument> _openDocumentWithText(String text) async {
  final document = sf.PdfDocument();
  document.pages.add().graphics.drawString(
    text,
    sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 14),
    bounds: const ui.Rect.fromLTWH(50, 100, 450, 30),
  );
  final bytes = Uint8List.fromList(await document.save());
  document.dispose();
  return PdfDocument.openData(bytes);
}

/// Learning test for pdfrx 2.4.8 text bounds. It needs the pdfium native
/// library that the pdfrx build hook downloads into `.dart_tool`; without it
/// the tests are skipped and the fake-page tests in
/// page_bounds_normalization_test.dart still cover the conversion.
void main() {
  final pdfiumPath = findPdfiumLibrary();
  final skipReason = pdfiumPath == null
      ? 'pdfium native module not found'
      : null;

  setUpAll(() => Pdfrx.pdfiumModulePath = pdfiumPath);

  test('pdfrx text search yields page-relative bounds for a match', () async {
    final document = await _openDocumentWithText('one needle two');
    addTearDown(document.dispose);
    final text = await document.pages.first.loadStructuredText();

    final matches = await text.allMatches('needle').toList();

    expect(matches, hasLength(1));
    expect(matches.first.bounds.isEmpty, isFalse);
  }, skip: skipReason);

  test('real match bounds normalize into the page and round-trip', () async {
    final document = await _openDocumentWithText('one needle two');
    addTearDown(document.dispose);
    final page = document.pages.first;
    final text = await page.loadStructuredText();
    final match = await text.allMatches('needle').first;

    final normalized = normalizePageBounds(match.bounds, page);
    final restored = pageBoundsFromNormalized(normalized, page);

    expect(normalized.left, inInclusiveRange(0.0, 1.0));
    expect(normalized.top, inInclusiveRange(0.0, 1.0));
    expect(normalized.right, inInclusiveRange(0.0, 1.0));
    expect(normalized.bottom, inInclusiveRange(0.0, 1.0));
    expect(restored.left, closeTo(match.bounds.left, 0.01));
    expect(restored.top, closeTo(match.bounds.top, 0.01));
    expect(restored.right, closeTo(match.bounds.right, 0.01));
    expect(restored.bottom, closeTo(match.bounds.bottom, 0.01));
  }, skip: skipReason);

  test(
    'a match drawn near the top of the page has a small top fraction',
    () async {
      final document = await _openDocumentWithText('one needle two');
      addTearDown(document.dispose);
      final page = document.pages.first;
      final text = await page.loadStructuredText();
      final match = await text.allMatches('needle').first;

      final normalized = normalizePageBounds(match.bounds, page);

      expect(normalized.top, lessThan(0.25));
    },
    skip: skipReason,
  );

  test('pdfrx match offsets index into the page fullText', () async {
    final document = await _openDocumentWithText('one needle two');
    addTearDown(document.dispose);
    final text = await document.pages.first.loadStructuredText();
    final match = await text.allMatches('NEEDLE', caseInsensitive: true).first;

    expect(identical(match.pageText, text), isTrue);
    expect(text.fullText.substring(match.start, match.end), 'needle');
  }, skip: skipReason);

  test('findMatchesOnPage builds a contextual excerpt', () async {
    final document = await _openDocumentWithText('one needle two');
    addTearDown(document.dispose);

    final found = await findMatchesOnPage(document.pages.first, 'needle');

    expect(found.single.excerpt.match, 'needle');
    expect(found.single.excerpt.before, 'one ');
    expect(found.single.excerpt.after, ' two');
  }, skip: skipReason);
}
