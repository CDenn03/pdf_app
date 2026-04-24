import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/core/utils/debounce.dart';
import 'package:pdf_app/features/reader/state/annotation_notifier.dart';

class MockAnnotationDao extends Mock implements AnnotationDao {}

class _FakeAnnotation extends Fake implements Annotation {}

const _rect = RelativeRectModel(left: 0.1, top: 0.1, right: 0.5, bottom: 0.2);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAnnotation());
  });

  late MockAnnotationDao dao;
  late AnnotationNotifier notifier;

  setUp(() {
    dao = MockAnnotationDao();
    // Use a very long debounce so saves don't fire during tests
    notifier = AnnotationNotifier(
      dao: dao,
      debounce: Debounce(duration: const Duration(seconds: 60)),
    );

    when(
      () => dao.getByPdfAndPageRange(any(), any(), any()),
    ).thenAnswer((_) async => []);
    when(() => dao.upsert(any())).thenAnswer((_) async {});
    when(() => dao.softDelete(any())).thenAnswer((_) async {});
  });

  tearDown(() => notifier.dispose());

  group('loadForPage', () {
    test('loads annotations from dao and updates state', () async {
      final annotation = Annotation(
        id: 'abc',
        pdfId: 'pdf1',
        page: 2,
        type: AnnotationType.highlight,
        rect: _rect,
      );
      when(
        () => dao.getByPdfAndPageRange('pdf1', 1, 3),
      ).thenAnswer((_) async => [annotation]);

      await notifier.loadForPage('pdf1', 2);

      expect(notifier.state, [annotation]);
    });

    test('clamps startPage to 1 when page is 1', () async {
      await notifier.loadForPage('pdf1', 1);
      verify(() => dao.getByPdfAndPageRange('pdf1', 1, 2)).called(1);
    });
  });

  group('addHighlight', () {
    test('adds annotation to state immediately', () {
      notifier.addHighlight(rect: _rect, page: 1);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.type, AnnotationType.highlight);
      expect(notifier.state.first.rect, _rect);
    });

    test('does not call dao.upsert immediately (debounced)', () {
      notifier.addHighlight(rect: _rect, page: 1);
      verifyNever(() => dao.upsert(any()));
    });
  });

  group('addNote', () {
    test('adds note annotation with text', () {
      notifier.addNote(rect: _rect, text: 'hello', page: 1);
      expect(notifier.state.first.type, AnnotationType.note);
      expect(notifier.state.first.text, 'hello');
    });
  });

  group('addBookmark', () {
    test('adds bookmark with no rect', () {
      notifier.addBookmark(page: 3);
      expect(notifier.state.first.type, AnnotationType.bookmark);
      expect(notifier.state.first.rect, isNull);
    });
  });

  group('removeAnnotation', () {
    test('removes from state and calls softDelete', () async {
      notifier.addHighlight(rect: _rect, page: 1);
      final id = notifier.state.first.id;

      await notifier.removeAnnotation(id);

      expect(notifier.state, isEmpty);
      verify(() => dao.softDelete(id)).called(1);
    });
  });

  group('annotationsForPage', () {
    test('filters by page and excludes soft-deleted', () async {
      notifier.addHighlight(rect: _rect, page: 1);
      notifier.addHighlight(rect: _rect, page: 2);

      final page1 = notifier.annotationsForPage(1);
      expect(page1.length, 1);
      expect(page1.first.page, 1);
    });
  });

  group('updateNoteText', () {
    test('updates text of existing note', () {
      notifier.addNote(rect: _rect, text: 'original', page: 1);
      final id = notifier.state.first.id;

      notifier.updateNoteText(id, 'updated');

      expect(notifier.state.first.text, 'updated');
    });
  });
}
