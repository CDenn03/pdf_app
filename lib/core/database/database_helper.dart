import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Abstract interface for providing a [Database] instance.
///
/// Allows [AnnotationDao] to depend on an abstraction rather than the
/// concrete [DatabaseHelper], making it testable without a real database.
abstract class DatabaseProvider {
  Future<Database> get database;
}

/// Singleton SQLite database helper for the PDF Navigator app.
///
/// Manages database creation, schema migrations, and provides
/// a single [Database] instance throughout the app lifecycle.
class DatabaseHelper implements DatabaseProvider {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Returns the singleton [Database] instance, creating it if necessary.
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
      version: 3,
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
        text TEXT,
        label TEXT,
        color TEXT NOT NULL DEFAULT 'yellow',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Required index per architecture spec: indexed (pdf_id, page) queries
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
  }
}
