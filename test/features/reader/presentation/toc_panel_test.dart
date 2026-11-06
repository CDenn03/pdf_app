import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:sefer/features/reader/domain/auxiliary_document_status.dart';
import 'package:sefer/features/reader/presentation/toc_panel.dart';

PdfDocument _documentWithChapterOnPage(int pageNumber) {
  final document = PdfDocument();
  for (var i = 0; i < pageNumber; i++) {
    document.pages.add();
  }
  document.bookmarks.add('Chapter One').destination = PdfDestination(
    document.pages[pageNumber - 1],
    const Offset(0, 0),
  );
  return document;
}

void main() {
  testWidgets('selecting a chapter reports its one-based page number', (
    tester,
  ) async {
    final selectedPages = <int>[];
    final document = _documentWithChapterOnPage(3);
    addTearDown(document.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTocPanel(
              context: context,
              onPageSelected: selectedPages.add,
              document: document,
              documentStatus: AuxiliaryDocumentStatus.ready,
              pdfId: 'toc-test',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chapter One'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(selectedPages, [3]);
    expect(find.text('Chapter One'), findsNothing);
  });

  group('without a document', () {
    Future<void> openPanel(
      WidgetTester tester,
      AuxiliaryDocumentStatus status,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTocPanel(
                context: context,
                onPageSelected: (_) {},
                document: null,
                documentStatus: status,
                pdfId: 'toc-test',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a failed load is reported as unavailable, not empty', (
      tester,
    ) async {
      await openPanel(tester, AuxiliaryDocumentStatus.failed);

      expect(find.textContaining('could not be loaded'), findsOneWidget);
      expect(find.text('No chapters found.'), findsNothing);
    });

    testWidgets('a pending load is reported as still loading', (tester) async {
      await openPanel(tester, AuxiliaryDocumentStatus.loading);

      expect(find.textContaining('still loading'), findsOneWidget);
      expect(find.text('No chapters found.'), findsNothing);
    });
  });
}
