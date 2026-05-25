import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

abstract class DatabaseProvider {
  Future<Database> get database;
}

/// Singleton SQLite database helper.
///
/// Schema version history:
///   v1 — initial schema
///   v2 — added color column
///   v3 — added label column
///   v4 — added selected_text, text_run_start, text_run_end,
///         coordinate_version, created_at, updated_at columns
class DatabaseHelper implements DatabaseProvider {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  @override
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pdf_navigator.db');

    return await openDatabase(
      path,
      version: 4,
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
        rect_top REAL,
        rect_left REAL,
        rect_bottom REAL,
        rect_right REAL,
        selected_text TEXT,
        text_run_start INTEGER,
        text_run_end INTEGER,
        text TEXT,
        label TEXT,
        color TEXT NOT NULL DEFAULT 'yellow',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        coordinate_version INTEGER NOT NULL DEFAULT 2,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('CREATE INDEX idx_pdf_page ON annotations(pdf_id, page)');
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
      await db.execute('ALTER TABLE annotations ADD COLUMN text_run_start INTEGER');
      await db.execute('ALTER TABLE annotations ADD COLUMN text_run_end INTEGER');
      // Existing rows get coordinate_version = 1 (legacy broken coordinates).
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
  }
}
