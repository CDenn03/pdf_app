import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/reader/presentation/reader_more_sheet.dart';
import 'package:sefer/features/reader/state/open_document_rename_coordinator.dart';

import '../../../support/library_fakes.dart';

class _Host implements OpenDocumentRenameHost {
  @override
  int get currentPage => 1;

  @override
  Future<void> flushProgress() async {}

  @override
  Future<void> flushAnnotations() async {}

  @override
  void cancelSearch() {}

  @override
  Future<void> suspendViewport() async {}

  @override
  void resumeViewport() {}
}

Future<void> _openSheet(
  WidgetTester tester, {
  required OpenDocumentRenameCoordinator? coordinator,
  List<PersistedEntry> entries = const [],
  List<PdfCollection> collections = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fileServiceProvider.overrideWithValue(FakeFileChecker()),
        libraryPersistenceProvider.overrideWithValue(
          FakeLibraryPersistence(initial: entries),
        ),
        collectionsServiceProvider.overrideWithValue(
          FakeCollectionsService(collections),
        ),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => showReaderMoreSheet(
              context,
              ref,
              pdfPath: '/docs/a.pdf',
              renameCoordinator: coordinator,
              onAnnotations: () {},
              onAddToCollection: () {},
              onPanelClosed: () {},
            ),
            child: const Text('more'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('more'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Rename is hidden when no coordinator is given (assets)', (
    tester,
  ) async {
    await _openSheet(tester, coordinator: null);

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Add to collection'), findsOneWidget);
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('Rename is offered for a local file', (tester) async {
    final coordinator = OpenDocumentRenameCoordinator(
      host: _Host(),
      rename: ({required path, required newName}) => throw UnimplementedError(),
    );
    addTearDown(coordinator.dispose);

    await _openSheet(tester, coordinator: coordinator);

    expect(find.text('Rename'), findsOneWidget);
  });

  testWidgets('lists collections the open book belongs to', (tester) async {
    await _openSheet(
      tester,
      coordinator: null,
      entries: const [
        PersistedEntry(
          id: 'a',
          name: 'a.pdf',
          path: '/docs/a.pdf',
          collectionIds: {'c1', 'c2'},
        ),
      ],
      collections: const [
        PdfCollection(id: 'c1', name: 'Papers'),
        PdfCollection(id: 'c2', name: 'Novels'),
      ],
    );

    expect(find.text('Show in "Papers"'), findsOneWidget);
    expect(find.text('Show in "Novels"'), findsOneWidget);
    expect(find.text('Add to collection'), findsOneWidget);
  });
}
