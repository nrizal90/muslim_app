import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/ayah_model.dart';
import '../models/surah_model.dart';

class QuranLocalDataSource {
  final DatabaseHelper dbHelper;

  QuranLocalDataSource(this.dbHelper);

  Future<Database> get _db async => await dbHelper.database;

  Future<void> insertAyahs(List<AyahModel> ayahs) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var ayah in ayahs) {
        batch.insert('ayah', ayah.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> insertSurahs(List<SurahModel> surahs) async {
    final db = await _db;
    final batch = db.batch();
    for (var surah in surahs) {
      batch.insert('surah', surah.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<bool> isAyahTableEmpty() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) FROM ayah');
    return (Sqflite.firstIntValue(result) ?? 0) == 0;
  }

  Future<List<AyahModel>> getAyahsByPage(int page) async {
    final db = await _db;
    final result = await db.query(
      'ayah',
      where: 'page = ?',
      whereArgs: [page],
      orderBy: 'surah_id ASC, ayah_number ASC',
    );
    return result.map((map) => AyahModel.fromMap(map)).toList();
  }

  Future<List<SurahModel>> getAllSurahs() async {
    final db = await _db;
    final result = await db.query('surah', orderBy: 'id ASC');
    return result.map((row) => _surahFromRow(row)).toList();
  }

  Future<SurahModel?> getSurahById(int id) async {
    final db = await _db;
    final result = await db.query('surah', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? _surahFromRow(result.first) : null;
  }

  Future<List<AyahModel>> getAyahsBySurahId(int surahId) async {
    final db = await _db;
    final result = await db.query(
      'ayah',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
    );
    return result.map((map) => AyahModel.fromMap(map)).toList();
  }

  SurahModel _surahFromRow(Map<String, dynamic> row) {
    return SurahModel(
      id: row['id'] as int,
      nameArabic: row['name_ar'] as String? ?? '',
      nameEnglish: row['name_en'] as String? ?? '',
      nameIndonesian: row['name_id'] as String? ?? '',
      revelationType: row['revelation_type'] as String? ?? '',
      totalAyah: row['total_ayah'] as int? ?? 0,
      bismillahPre: (row['bismillah_pre'] as int? ?? 0) == 1,
    );
  }
}
