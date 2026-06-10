import 'dart:convert';
import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import 'package:sefer/core/database/database_helper.dart';
import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_color.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/models/relative_rect_model.dart';

/// Data access object for annotation CRUD operations.
///
/// All queries filter by `is_deleted = 0` to honor soft-delete semantics.
class AnnotationDao {
  final DatabaseProvider _provider;

  /// The dependency is required so it is always explicit and injectable (#17).
  AnnotationDao({required DatabaseProvider dbHelper}) : _provider = dbHelper;

  AnnotationDao.withDatabase(Database db)
    : _provider = _DirectDatabaseProvider(db);

  Future<Database> get _db => _provider.database;

  /// Retrieves all non-deleted annotations for [pdfId] across a page range.
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

  /// Retrieves ALL non-deleted annotations for [pdfId], ordered by page.
  Future<List<Annotation>> getAllForPdf(String pdfId) async {
    final db = await _db;
    final maps = await db.query(
      'annotations',
      where: 'pdf_id = ? AND is_deleted = 0',
      whereArgs: [pdfId],
      orderBy: 'page ASC',
    );
    final result = <Annotation>[];
    for (final map in maps) {
      try {
        result.add(_fromMap(map));
      } catch (e, s) {
        developer.log(
          'Skipping malformed annotation row: $map',
          name: 'sefer.dao',
          level: 900,
          error: e,
          stackTrace: s,
        );
      }
    }
    return result;
  }

  /// Inserts or updates an annotation.
  Future<void> upsert(Annotation annotation) async {
    final db = await _db;
    await db.insert(
      'annotations',
      _toMap(annotation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Soft-deletes an annotation by setting `is_deleted = 1`.
  Future<void> softDelete(String id) async {
    final db = await _db;
    await db.update(
      'annotations',
      {'is_deleted': 1, 'updated_at': _now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  String get _now => DateTime.now().toIso8601String();

  Map<String, dynamic> _toMap(Annotation annotation) {
    return {
      'id': annotation.id,
      'pdf_id': annotation.pdfId,
      'page': annotation.page,
      'type': annotation.type.name,
      'rects': jsonEncode(
        annotation.rects.map((r) => r.toJson()).toList(),
      ),
      'selected_text': annotation.selectedText,
      'text': annotation.text,
      'label': annotation.label,
      'color': annotation.color.name,
      'is_deleted': annotation.isDeleted ? 1 : 0,
      'pdf_fingerprint': annotation.pdfFingerprint,
      'created_at': annotation.createdAt?.toIso8601String() ?? _now,
      'updated_at': _now,
    };
  }

  Annotation _fromMap(Map<String, dynamic> map) {
    final rectsJson =
        jsonDecode(map['rects'] as String? ?? '[]') as List<dynamic>;
    final rects = rectsJson
        .cast<Map<String, dynamic>>()
        .map(RelativeRectModel.fromJson)
        .toList();

    final color = AnnotationColor.values.firstWhere(
      (c) => c.name == (map['color'] as String? ?? 'yellow'),
      orElse: () => AnnotationColor.yellow,
    );

    return Annotation(
      id: map['id'] as String,
      pdfId: map['pdf_id'] as String,
      page: map['page'] as int,
      type: AnnotationType.values.byName(map['type'] as String),
      rects: rects,
      selectedText: map['selected_text'] as String?,
      text: map['text'] as String?,
      label: map['label'] as String?,
      color: color,
      isDeleted: (map['is_deleted'] as int) == 1,
      pdfFingerprint: map['pdf_fingerprint'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}

class _DirectDatabaseProvider implements DatabaseProvider {
  final Database _db;
  _DirectDatabaseProvider(this._db);

  @override
  Future<Database> get database async => _db;
}
