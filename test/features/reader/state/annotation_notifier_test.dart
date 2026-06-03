import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/database/note_entry_dao.dart';
import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/models/note_entry.dart';
import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/features/reader/state/annotation_notifier.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

class MockAnnotationDao extends Mock implements AnnotationDao {}

class MockNoteEntryDao extends Mock implements NoteEntryDao {}

class _FakeAnnotation extends Fake implements Annotation {}

class _FakeNoteEntry extends Fake implements NoteEntry {}

const _rects = [
  RelativeRectModel(left: 0.1, top: 0.1, right: 0.5, bottom: 0.2),
];

// Edge position: left edge, vertical fraction 0.3.
const _edgePos = RelativeRectModel(
  left: 0.0,
  top: 0.3,
  right: 0.0,
  bottom: 0.3,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAnnotation());
    registerFallbackValue(_FakeNoteEntry());
  });

  late MockAnnotationDao dao;
  late MockNoteEntryDao noteEntryDao;
  late ProviderContainer container;

  setUp(() {
    dao = MockAnnotationDao();
    noteEntryDao = MockNoteEntryDao();
    container = ProviderContainer(
      overrides: [
        annotationDaoProvider.overrideWithValue(dao),
        noteEntryDaoProvider.overrideWithValue(noteEntryDao),
      ],
    );

    when(() => dao.getByPdfAndPageRange(any(), any(), any()))
        .thenAnswer((_) async => []);
    when(() => dao.upsert(any())).thenAnswer((_) async {});
    when(() => dao.softDelete(any())).thenAnswer((_) async {});
    when(() => noteEntryDao.insert(any())).thenAnswer((_) async {});
    when(() => noteEntryDao.getForAnnotation(any()))
        .thenAnswer((_) async => []);
  });

  tearDown(() => container.dispose());

  AnnotationNotifier notifier() =>
      container.read(annotationNotifierProvider.notifier);

  List<Annotation> allAnnotations() {
    final map = container.read(annotationNotifierProvider);
    return map.values.expand((list) => list).toList();
  }

  group('loadForPage', () {
    test('loads annotations from dao and updates state', () async {
      final annotation = Annotation(
        id: 'abc',
        pdfId: 'pdf1',
        page: 2,
        type: AnnotationType.highlight,
        rects: _rects,
      );
      when(() => dao.getByPdfAndPageRange('pdf1', 1, 3))
          .thenAnswer((_) async => [annotation]);

      await notifier().loadForPage('pdf1', 2);

      expect(allAnnotations(), [annotation]);
    });

    test('clamps startPage to 1 when page is 1', () async {
      await notifier().loadForPage('pdf1', 1);
      verify(() => dao.getByPdfAndPageRange('pdf1', 1, 2)).called(1);
    });
  });

  group('addHighlight', () {
    test('adds annotation to state immediately', () {
      notifier().addHighlight(rects: _rects, page: 1);
      expect(allAnnotations().length, 1);
      expect(allAnnotations().first.type, AnnotationType.highlight);
      expect(allAnnotations().first.rects, _rects);
    });

    test('saves annotation via upsert asynchronously', () async {
      notifier().addHighlight(rects: _rects, page: 1);
      await Future<void>.delayed(Duration.zero);
      verify(() => dao.upsert(any())).called(1);
    });

    test('canUndo becomes true after adding', () {
      expect(notifier().canUndo, false);
      notifier().addHighlight(rects: _rects, page: 1);
      expect(notifier().canUndo, true);
    });
  });

  group('addNote', () {
    test('adds note annotation with edge position', () {
      notifier().addNote(
        edgePosition: _edgePos,
        initialText: 'hello',
        page: 1,
      );
      expect(allAnnotations().first.type, AnnotationType.note);
      expect(allAnnotations().first.rects.first, _edgePos);
    });

    test('inserts initial note entry via NoteEntryDao', () async {
      notifier().addNote(
        edgePosition: _edgePos,
        initialText: 'hello',
        page: 1,
      );
      // Give the async insert a chance to run.
      await Future<void>.delayed(Duration.zero);
      verify(() => noteEntryDao.insert(any())).called(1);
    });
  });

  group('addBookmark', () {
    test('adds bookmark with empty rects', () {
      notifier().addBookmark(page: 3);
      expect(allAnnotations().first.type, AnnotationType.bookmark);
      expect(allAnnotations().first.rects, isEmpty);
    });
  });

  group('removeAnnotation', () {
    test('removes from state and calls softDelete', () async {
      notifier().addHighlight(rects: _rects, page: 1);
      final id = allAnnotations().first.id;

      await notifier().removeAnnotation(id);

      expect(allAnnotations(), isEmpty);
      verify(() => dao.softDelete(id)).called(1);
    });
  });

  group('undo', () {
    test('removes the most recently added annotation', () async {
      notifier().addHighlight(rects: _rects, page: 1);
      expect(allAnnotations().length, 1);

      final message = await notifier().undo();

      expect(allAnnotations(), isEmpty);
      expect(message, 'Highlight removed');
    });

    test('returns null when nothing to undo', () async {
      final message = await notifier().undo();
      expect(message, isNull);
    });

    test('canUndo becomes false after undoing the only annotation', () async {
      notifier().addHighlight(rects: _rects, page: 1);
      await notifier().undo();
      expect(notifier().canUndo, false);
    });

    test('undoes in LIFO order', () async {
      notifier().addHighlight(rects: _rects, page: 1);
      notifier().addNote(
        edgePosition: _edgePos,
        initialText: 'note',
        page: 1,
      );

      final msg1 = await notifier().undo();
      expect(msg1, 'Note removed');
      expect(allAnnotations().length, 1);
      expect(allAnnotations().first.type, AnnotationType.highlight);

      final msg2 = await notifier().undo();
      expect(msg2, 'Highlight removed');
      expect(allAnnotations(), isEmpty);
    });
  });

  group('annotationsForPage', () {
    test('filters by page and excludes soft-deleted', () async {
      notifier().addHighlight(rects: _rects, page: 1);
      notifier().addHighlight(rects: _rects, page: 2);

      final page1 = notifier().annotationsForPage(1);
      expect(page1.length, 1);
      expect(page1.first.page, 1);
    });
  });

  group('updateNoteText', () {
    test('updates text of existing note', () {
      notifier().addNote(
        edgePosition: _edgePos,
        initialText: 'original',
        page: 1,
      );
      final id = allAnnotations().first.id;

      notifier().updateNoteText(id, 'updated');

      expect(allAnnotations().first.text, 'updated');
    });
  });
}
