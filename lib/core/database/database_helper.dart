import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

abstract class DatabaseProvider {
  Future<Database> get database;
}

/// SQLite database helper.
///
/// The singleton pattern has been removed so Riverpod can own the lifetime
/// (see databaseHelperProvider in providers.dart). Using static state caused
/// the database handle to leak across tests and hot-restarts.
class DatabaseHelper implements DatabaseProvider {
  // Instance field — not static — so each ProviderScope gets its own handle.
  Database? _database;

  @override
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pdf_navigator.db');

    return openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('CREATE INDEX idx_pdf_page ON annotations(pdf_id, page)');

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
      'CREATE INDEX idx_note_entries_annotation ON note_entries(annotation_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE annotations ADD COLUMN color TEXT NOT NULL DEFAULT 'yellow'",
      );
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE annotations ADD COLUMN label TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE annotations ADD COLUMN selected_text TEXT');
      await db.execute(
        'ALTER TABLE annotations ADD COLUMN text_run_start INTEGER',
      );
      await db.execute(
        'ALTER TABLE annotations ADD COLUMN text_run_end INTEGER',
      );
      await db.execute(
        'ALTER TABLE annotations ADD COLUMN coordinate_version INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        "ALTER TABLE annotations ADD COLUMN created_at TEXT NOT NULL DEFAULT (datetime('now'))",
      );
      await db.execute(
        "ALTER TABLE annotations ADD COLUMN updated_at TEXT NOT NULL DEFAULT (datetime('now'))",
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE annotations ADD COLUMN rects TEXT NOT NULL DEFAULT '[]'",
      );
      await db.execute('''
        UPDATE annotations
        SET rects = json_array(
          json_object(
            'top',    CAST(rect_top    AS REAL),
            'left',   CAST(rect_left   AS REAL),
            'bottom', CAST(rect_bottom AS REAL),
            'right',  CAST(rect_right  AS REAL)
          )
        )
        WHERE rect_top IS NOT NULL
      ''');
      await db.execute(
        'ALTER TABLE annotations ADD COLUMN pdf_fingerprint TEXT',
      );
    }
    if (oldVersion < 6) {
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
        'CREATE INDEX idx_note_entries_annotation ON note_entries(annotation_id)',
      );
    }
  }
}
