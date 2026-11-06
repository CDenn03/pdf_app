import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/paged_document_status.dart';
import 'package:sefer/features/reader/presentation/paged_reader_viewport.dart';
import '../support/reader_viewport_fixture.dart';

void main() {
  testWidgets('shows a loading indicator until the document opens', (
    tester,
  ) async {
    final fixture = ReaderViewportFixture();

    await tester.pumpWidget(
      MaterialApp(home: PagedReaderViewport(config: fixture.config())),
    );

    expect(find.byType(PagedDocumentLoading), findsOneWidget);
    expect(fixture.navigation.currentPage, 1);
  });

  testWidgets('the error view tells the reader the document failed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PagedDocumentError(
          path: 'missing.pdf',
          error: StateError('unreadable'),
        ),
      ),
    );

    expect(find.text('This document could not be opened.'), findsOneWidget);
  });
}
