import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sefer/core/database/annotation_dao.dart';
import 'package:sefer/core/database/note_entry_dao.dart';
import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/features/reader/presentation/reader_page.dart';
import 'package:sefer/features/reader/state/providers.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

import '../../../support/library_fakes.dart';

class _MockAnnotationDao extends Mock implements AnnotationDao {}

class _MockNoteEntryDao extends Mock implements NoteEntryDao {}

class _RecordingRecents extends FakeRecentsStore {
  _RecordingRecents() : super(const []);

  final opened = <String>[];

  @override
  Future<void> recordOpened(String path, String name) async {
    opened.add(path);
  }
}

class _FixedProgress implements ReadingProgressStore {
  @override
  Future<int> getLastPage(String pdfId) async => 9;

  @override
  Future<void> saveLastPage(String pdfId, int page) async {}

  @override
  Future<void> movePage(String oldPdfId, String newPdfId) async {}

  @override
  Future<void> clear(String pdfId) async {}
}

Future<(_RecordingRecents, ProviderContainer)> _pump(
  WidgetTester tester, {
  bool recordOpened = true,
  int? initialPage,
}) async {
  SharedPreferences.setMockInitialValues({});
  final recents = _RecordingRecents();
  final dao = _MockAnnotationDao();
  when(
    () => dao.getByPdfAndPageRange(any(), any(), any()),
  ).thenAnswer((_) async => []);
  final container = ProviderContainer(
    overrides: [
      annotationDaoProvider.overrideWithValue(dao),
      noteEntryDaoProvider.overrideWithValue(_MockNoteEntryDao()),
      recentsStoreProvider.overrideWithValue(recents),
      readingProgressProvider.overrideWithValue(_FixedProgress()),
      libraryPersistenceProvider.overrideWithValue(FakeLibraryPersistence()),
      fileServiceProvider.overrideWithValue(FakeFileChecker()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReaderPage(
          pdfPath: '/missing/book.pdf',
          initialPage: initialPage,
          recordOpened: recordOpened,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return (recents, container);
}

void main() {
  testWidgets('records the document as opened by default', (tester) async {
    final (recents, _) = await _pump(tester);

    expect(recents.opened, ['/missing/book.pdf']);
  });

  testWidgets('recordOpened false suppresses recording', (tester) async {
    final (recents, _) = await _pump(tester, recordOpened: false);

    expect(recents.opened, isEmpty);
  });

  testWidgets('initialPage overrides the saved reading position', (
    tester,
  ) async {
    final (_, container) = await _pump(tester, initialPage: 4);

    expect(container.read(readerNotifierProvider).resumePage, 4);
  });

  testWidgets('falls back to the saved page without an initialPage', (
    tester,
  ) async {
    final (_, container) = await _pump(tester);

    expect(container.read(readerNotifierProvider).resumePage, 9);
  });
}
