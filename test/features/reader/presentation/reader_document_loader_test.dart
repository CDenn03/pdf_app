import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/presentation/paged_document_status.dart';
import 'package:sefer/features/reader/presentation/reader_document_loader.dart';

Widget _loader(String path) => MaterialApp(
  home: ReaderDocumentLoader(
    pdfPath: path,
    isAsset: true,
    builder: (context, document, session) => const SizedBox(),
  ),
);

PdfDocumentRef _currentRef(WidgetTester tester) => tester
    .widget<PdfDocumentViewBuilder>(find.byType(PdfDocumentViewBuilder))
    .documentRef;

void main() {
  testWidgets('shows a loading indicator until the document opens', (
    tester,
  ) async {
    await tester.pumpWidget(_loader('assets/sample.pdf'));

    expect(find.byType(PagedDocumentLoading), findsOneWidget);
  });

  testWidgets('rebuilding with the same document keeps its reference', (
    tester,
  ) async {
    await tester.pumpWidget(_loader('assets/sample.pdf'));
    final first = _currentRef(tester);

    await tester.pumpWidget(_loader('assets/sample.pdf'));

    expect(identical(first, _currentRef(tester)), isTrue);
  });

  testWidgets('a different document gets a new reference', (tester) async {
    await tester.pumpWidget(_loader('assets/sample.pdf'));
    final first = _currentRef(tester);

    await tester.pumpWidget(_loader('assets/other.pdf'));

    expect(identical(first, _currentRef(tester)), isFalse);
  });
}
