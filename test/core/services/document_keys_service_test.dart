import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sefer/core/database/annotation_dao.dart';
import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/models/relative_rect_model.dart';
import 'package:sefer/core/services/document_keys_service.dart';
import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/core/services/recents_service.dart';

const _rect = RelativeRectModel(top: 0.1, left: 0.1, bottom: 0.2, right: 0.9);

void main() {
  late Database db;
  late AnnotationDao dao;
  late ReadingProgressService progress;
  late RecentsService recents;
  late DocumentKeyService keys;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
          await db.execute('''
            CREATE TABLE note_entries (
              id TEXT PRIMARY KEY,
              annotation_id TEXT NOT NULL,
              text TEXT NOT NULL,
              created_at TEXT NOT NULL DEFAULT (datetime('now')),
              FOREIGN KEY (annotation_id) REFERENCES annotations(id)
            )
          ''');
        },
      ),
    );
    dao = AnnotationDao.withDatabase(db);
    progress = ReadingProgressService();
    recents = RecentsService();
    keys = DocumentKeyService(
      annotationDao: dao,
      progress: progress,
      recents: recents,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Annotation highlight(String id, String pdfId) => Annotation(
    id: id,
    pdfId: pdfId,
    page: 1,
    type: AnnotationType.highlight,
    rects: const [_rect],
  );

  Future<void> insertNote(String id, String annotationId) async {
    await db.insert('note_entries', {
      'id': id,
      'annotation_id': annotationId,
      'text': 'note',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> noteCount(String annotationId) async =>
      (await db.query(
        'note_entries',
        where: 'annotation_id = ?',
        whereArgs: [annotationId],
      )).length;

  group('moveDocument', () {
    test('reaches all three stores', () async {
      const oldPath = '/old.pdf';
      const newPath = '/new.pdf';
      await dao.upsert(highlight('a1', oldPath));
      await progress.saveLastPage(oldPath, 8);
      await recents.recordOpened(oldPath, 'Old');
      final openedAt = (await recents.load()).single.openedAt;

      await keys.moveDocument(
        oldPath: oldPath,
        newPath: newPath,
        newName: 'New',
      );

      expect((await dao.getAllForPdf(oldPath)), isEmpty);
      expect((await dao.getAllForPdf(newPath)).single.id, 'a1');

      expect(await progress.getLastPage(newPath), 8);
      expect(await progress.getLastPage(oldPath), 1);

      final after = await recents.load();
      expect(after.single.path, newPath);
      expect(after.single.name, 'New');
      expect(after.single.openedAt, openedAt);
    });

    test('is a safe no-op for a path with nothing stored', () async {
      await keys.moveDocument(
        oldPath: '/missing.pdf',
        newPath: '/new.pdf',
        newName: 'New',
      );

      expect(await dao.getAllForPdf('/new.pdf'), isEmpty);
      expect(await progress.getLastPage('/new.pdf'), 1);
      expect(await recents.load(), isEmpty);
    });
  });

  group('purgeDocument', () {
    test('reaches all three stores and does not orphan notes', () async {
      const path = '/gone.pdf';
      await dao.upsert(highlight('a1', path));
      await insertNote('n1', 'a1');
      await progress.saveLastPage(path, 4);
      await recents.recordOpened(path, 'Gone');

      await keys.purgeDocument(path);

      final rows = await db.query(
        'annotations',
        where: 'pdf_id = ?',
        whereArgs: [path],
      );
      expect(rows, isEmpty);
      expect(await noteCount('a1'), 0);
      expect(await progress.getLastPage(path), 1);
      expect(await recents.load(), isEmpty);
    });

    test('is a safe no-op for a path with nothing stored', () async {
      await recents.recordOpened('/keep.pdf', 'Keep');

      await keys.purgeDocument('/missing.pdf');

      expect((await recents.load()).single.path, '/keep.pdf');
      expect(await progress.getLastPage('/missing.pdf'), 1);
    });
  });
}
