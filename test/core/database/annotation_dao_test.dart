import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sefer/core/database/annotation_dao.dart';
import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/models/relative_rect_model.dart';

const _rect = RelativeRectModel(top: 0.1, left: 0.1, bottom: 0.2, right: 0.9);

void main() {
  late Database db;
  late AnnotationDao dao;

  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE annotations (
              id TEXT PRIMARY KEY,
              pdf_id TEXT NOT NULL,
              page INTEGER NOT NULL,
              type TEXT NOT NULL,
              rects TEXT NOT NULL DEFAULT '[]',
              selected_text TEXT,
              text TEXT,
              label TEXT,
              color TEXT NOT NULL DEFAULT 'yellow',
              is_deleted INTEGER NOT NULL DEFAULT 0,
              pdf_fingerprint TEXT,
              created_at TEXT NOT NULL DEFAULT (datetime('now')),
              updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_pdf_page ON annotations(pdf_id, page)',
          );
        },
      ),
    );
    dao = AnnotationDao.withDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  Annotation makeHighlight({
    String id = 'test-uuid-1',
    String pdfId = 'pdf-1',
    int page = 1,
  }) {
    return Annotation(
      id: id,
      pdfId: pdfId,
      page: page,
      type: AnnotationType.highlight,
      rects: const [_rect],
    );
  }

  group('AnnotationDao', () {
    test('insert and retrieve by page range', () async {
      final annotation = makeHighlight();
      await dao.upsert(annotation);

      final results = await dao.getByPdfAndPageRange('pdf-1', 1, 1);

      expect(results.length, 1);
      expect(results.first.id, 'test-uuid-1');
      expect(results.first.type, AnnotationType.highlight);
      expect(results.first.rects.length, 1);
      expect(results.first.rects.first.top, closeTo(0.1, 0.001));
    });

    test('retrieve by page range', () async {
      await dao.upsert(makeHighlight(id: 'a1', page: 1));
      await dao.upsert(makeHighlight(id: 'a2', page: 2));
      await dao.upsert(makeHighlight(id: 'a3', page: 3));
      await dao.upsert(makeHighlight(id: 'a4', page: 5));

      final results = await dao.getByPdfAndPageRange('pdf-1', 1, 3);

      expect(results.length, 3);
    });

    test('soft delete hides annotation from queries', () async {
      await dao.upsert(makeHighlight());

      await dao.softDelete('test-uuid-1');

      final results = await dao.getByPdfAndPageRange('pdf-1', 1, 1);
      expect(results, isEmpty);
    });

    test('upsert updates existing annotation', () async {
      await dao.upsert(makeHighlight());

      final updated = makeHighlight().copyWith(
        rects: const [
          RelativeRectModel(top: 0.5, left: 0.5, bottom: 0.6, right: 0.7),
        ],
      );
      await dao.upsert(updated);

      final results = await dao.getByPdfAndPageRange('pdf-1', 1, 1);
      expect(results.length, 1);
      expect(results.first.rects.first.top, closeTo(0.5, 0.001));
    });

    test('bookmark annotation has empty rects', () async {
      const bookmark = Annotation(
        id: 'bookmark-1',
        pdfId: 'pdf-1',
        page: 3,
        type: AnnotationType.bookmark,
      );
      await dao.upsert(bookmark);

      final results = await dao.getByPdfAndPageRange('pdf-1', 3, 3);
      expect(results.length, 1);
      expect(results.first.rects, isEmpty);
      expect(results.first.type, AnnotationType.bookmark);
    });

    test('note annotation has rects and text', () async {
      const note = Annotation(
        id: 'note-1',
        pdfId: 'pdf-1',
        page: 2,
        type: AnnotationType.note,
        rects: [
          RelativeRectModel(top: 0.3, left: 0.2, bottom: 0.35, right: 0.25),
        ],
        text: 'Important point here',
      );
      await dao.upsert(note);

      final results = await dao.getByPdfAndPageRange('pdf-1', 2, 2);
      expect(results.length, 1);
      expect(results.first.text, 'Important point here');
      expect(results.first.rects.length, 1);
    });

    test('different pdf_ids are isolated', () async {
      await dao.upsert(makeHighlight(id: 'a1', pdfId: 'pdf-1'));
      await dao.upsert(makeHighlight(id: 'a2', pdfId: 'pdf-2'));

      final pdf1Results = await dao.getByPdfAndPageRange('pdf-1', 1, 1);
      final pdf2Results = await dao.getByPdfAndPageRange('pdf-2', 1, 1);

      expect(pdf1Results.length, 1);
      expect(pdf2Results.length, 1);
      expect(pdf1Results.first.id, 'a1');
      expect(pdf2Results.first.id, 'a2');
    });
  });
}
