import 'package:sqflite/sqflite.dart';

import 'package:pdf_app/core/database/database_helper.dart';
import 'package:pdf_app/core/models/note_entry.dart';

/// Data access object for [NoteEntry] CRUD operations.
class NoteEntryDao {
  NoteEntryDao({required DatabaseProvider dbHelper}) : _provider = dbHelper;

  final DatabaseProvider _provider;

  Future<Database> get _db => _provider.database;

  /// Returns all entries for [annotationId], oldest first.
  Future<List<NoteEntry>> getForAnnotation(String annotationId) async {
    final db = await _db;
    final maps = await db.query(
      'note_entries',
      where: 'annotation_id = ?',
      whereArgs: [annotationId],
      orderBy: 'created_at ASC',
    );
    return maps.map(_fromMap).toList();
  }

  /// Inserts a new entry; returns the inserted entry.
  Future<void> insert(NoteEntry entry) async {
    final db = await _db;
    await db.insert('note_entries', {
      'id': entry.id,
      'annotation_id': entry.annotationId,
      'text': entry.text,
      'created_at': entry.createdAt.toIso8601String(),
    });
  }

  NoteEntry _fromMap(Map<String, dynamic> map) => NoteEntry(
    id: map['id'] as String,
    annotationId: map['annotation_id'] as String,
    text: map['text'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
