import 'package:sqflite/sqflite.dart';

import 'package:pdf_app/core/database/database_helper.dart';
import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/models/relative_rect_model.dart';

/// Data access object for annotation CRUD operations.
///
/// All queries filter by `is_deleted = 0` to honor soft-delete semantics.
/// Never performs hard deletes per architecture spec.
class AnnotationDao {
  final DatabaseProvider _provider;

  AnnotationDao({DatabaseHelper? dbHelper})
    : _provider = dbHelper ?? DatabaseHelper();

  /// Test-only constructor that accepts a raw [Database] instance.
  AnnotationDao.withDatabase(Database db)
    : _provider = _DirectDatabaseProvider(db);

  Future<Database> get _db => _provider.database;

  /// Retrieves all non-deleted annotations for a given [pdfId] across
  /// a range of pages. Used for currentPage ± 1 loading.
  Future<List<Annotation>> getByPdfAndPageRange(
    String pdfId,
    int startPage,
    int endPage,
  ) async {
    final db = await _db;
    final maps = await db.query(
      'annotations',
      where: 'pdf_id = ? AND page >= ? AND page <= ? AND is_deleted = 0',
      whereArgs: [pdfId, startPage, endPage],
    );
    return maps.map(_fromMap).toList();
  }

  /// Inserts or updates an annotation.
  ///
  /// Uses `ConflictAlgorithm.replace` so that if an annotation with the
  /// same UUID already exists, it is updated in place.
  Future<void> upsert(Annotation annotation) async {
    final db = await _db;
    await db.insert(
      'annotations',
      _toMap(annotation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Soft-deletes an annotation by setting `is_deleted = 1`.
  /// Never hard-deletes per architecture spec.
  Future<void> softDelete(String id) async {
    final db = await _db;
    await db.update(
      'annotations',
      {'is_deleted': 1, 'updated_at': _now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Mapping helpers ---

  String get _now => DateTime.now().toIso8601String();

  Map<String, dynamic> _toMap(Annotation annotation) {
    return {
      'id': annotation.id,
      'pdf_id': annotation.pdfId,
      'page': annotation.page,
      'type': annotation.type.name,
      'rect_top': annotation.rect?.top,
      'rect_left': annotation.rect?.left,
      'rect_bottom': annotation.rect?.bottom,
      'rect_right': annotation.rect?.right,
      'text': annotation.text,
      'is_deleted': annotation.isDeleted ? 1 : 0,
      'updated_at': _now,
    };
  }

  Annotation _fromMap(Map<String, dynamic> map) {
    RelativeRectModel? rect;
    if (map['rect_top'] != null &&
        map['rect_left'] != null &&
        map['rect_bottom'] != null &&
        map['rect_right'] != null) {
      rect = RelativeRectModel(
        top: (map['rect_top'] as num).toDouble(),
        left: (map['rect_left'] as num).toDouble(),
        bottom: (map['rect_bottom'] as num).toDouble(),
        right: (map['rect_right'] as num).toDouble(),
      );
    }

    return Annotation(
      id: map['id'] as String,
      pdfId: map['pdf_id'] as String,
      page: map['page'] as int,
      type: AnnotationType.values.byName(map['type'] as String),
      rect: rect,
      text: map['text'] as String?,
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }
}

/// A [DatabaseProvider] that wraps an already-open [Database].
///
/// Used by [AnnotationDao.withDatabase] to allow tests to inject an
/// in-memory database without the nullable field branching.
class _DirectDatabaseProvider implements DatabaseProvider {
  final Database _db;

  _DirectDatabaseProvider(this._db);

  @override
  Future<Database> get database async => _db;
}
