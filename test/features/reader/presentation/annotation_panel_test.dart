import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/features/reader/presentation/annotation_panel.dart';
import 'package:sefer/features/reader/state/providers.dart';
import '../support/fake_annotation_daos.dart';

void main() {
  testWidgets('selecting an annotation reports its page and closes', (
    tester,
  ) async {
    final selectedPages = <int>[];
    final dao = FakeAnnotationDao(
      stored: const [
        Annotation(
          id: 'bookmark-1',
          pdfId: 'doc',
          page: 5,
          type: AnnotationType.bookmark,
          label: 'Start of part two',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          annotationDaoProvider.overrideWithValue(dao),
          noteEntryDaoProvider.overrideWithValue(FakeNoteEntryDao()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAnnotationPanel(
                context: context,
                pdfId: 'doc',
                onPageSelected: selectedPages.add,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start of part two'));
    await tester.pumpAndSettle();

    expect(selectedPages, [5]);
    expect(find.text('Start of part two'), findsNothing);
  });
}
