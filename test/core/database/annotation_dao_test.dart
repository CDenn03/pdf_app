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
          await db.execute('''
            CREATE TABLE note_entries (
              id TEXT PRIMARY KEY,
              annotation_id TEXT NOT NULL,
              text TEXT NOT NULL,
              created_at TEXT NOT NULL DEFAULT (datetime('now')),
              FOREIGN KEY (annotation_id) REFERENCES annotations(id)
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_note_entries_annotation '
            'ON note_entries(annotation_id)',
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

  Future<void> insertNote(String id, String annotationId) async {
    await db.insert('note_entries', {
      'id': id,
      'annotation_id': annotationId,
      'text': 'note $id',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> noteCount(String annotationId) async {
    final rows = await db.query(
      'note_entries',
      where: 'annotation_id = ?',
      whereArgs: [annotationId],
    );
    return rows.length;
  }

  group('reassignPdfId', () {
    test('moves only one document and leaves others alone', () async {
      await dao.upsert(makeHighlight(id: 'a1', pdfId: '/old.pdf', page: 1));
      await dao.upsert(makeHighlight(id: 'a2', pdfId: '/old.pdf', page: 2));
      await dao.upsert(makeHighlight(id: 'b1', pdfId: '/other.pdf'));

      await dao.reassignPdfId('/old.pdf', '/new.pdf');

      expect(await dao.getAllForPdf('/old.pdf'), isEmpty);
      final moved = await dao.getAllForPdf('/new.pdf');
      expect(moved.map((a) => a.id), containsAll(['a1', 'a2']));
      final other = await dao.getAllForPdf('/other.pdf');
      expect(other.single.id, 'b1');
    });

    test('is a no-op when no rows match', () async {
      await dao.upsert(makeHighlight(id: 'b1', pdfId: '/other.pdf'));

      await dao.reassignPdfId('/missing.pdf', '/new.pdf');

      expect(await dao.getAllForPdf('/new.pdf'), isEmpty);
      expect((await dao.getAllForPdf('/other.pdf')).single.id, 'b1');
    });
  });

  group('purgeForPdf', () {
    test('hard-deletes annotations AND their note entries, '
        'leaving a different document untouched', () async {
      await dao.upsert(makeHighlight(id: 'a1', pdfId: '/gone.pdf', page: 1));
      await dao.upsert(makeHighlight(id: 'a2', pdfId: '/gone.pdf', page: 2));
      await dao.upsert(makeHighlight(id: 'b1', pdfId: '/keep.pdf'));
      await insertNote('n1', 'a1');
      await insertNote('n2', 'a1');
      await insertNote('n3', 'a2');
      await insertNote('k1', 'b1');

      await dao.purgeForPdf('/gone.pdf');

      final goneRows = await db.query(
        'annotations',
        where: 'pdf_id = ?',
        whereArgs: ['/gone.pdf'],
      );
      expect(goneRows, isEmpty, reason: 'hard delete, not soft');
      expect(await noteCount('a1'), 0, reason: 'notes must not orphan');
      expect(await noteCount('a2'), 0);

      final keepRows = await db.query(
        'annotations',
        where: 'pdf_id = ?',
        whereArgs: ['/keep.pdf'],
      );
      expect(keepRows.length, 1);
      expect(await noteCount('b1'), 1);
    });

    test('is a no-op when the document has nothing stored', () async {
      await dao.upsert(makeHighlight(id: 'b1', pdfId: '/keep.pdf'));
      await insertNote('k1', 'b1');

      await dao.purgeForPdf('/missing.pdf');

      expect((await dao.getAllForPdf('/keep.pdf')).single.id, 'b1');
      expect(await noteCount('b1'), 1);
    });
  });
}
