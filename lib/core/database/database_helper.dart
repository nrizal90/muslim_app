import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quran.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE surah ADD COLUMN revelation_type TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE surah (
        id INTEGER PRIMARY KEY,
        name_ar TEXT,
        name_en TEXT,
        name_id TEXT,
        revelation_type TEXT,
        total_ayah INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE ayah (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER,
        ayah_number INTEGER,
        page INTEGER,
        juz INTEGER,
        text_uthmani TEXT,
        text_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmark (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER,
        ayah_number INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE last_read (
        id INTEGER PRIMARY KEY,
        surah_id INTEGER,
        ayah_number INTEGER,
        page INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_page ON ayah(page)
    ''');

    await db.execute('''
      CREATE INDEX idx_surah ON ayah(surah_id)
    ''');
  }
}