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
        batch.insert(
          'ayah',
          ayah.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  Future<List<AyahModel>> getAyahsByPage(int page) async {
    final db = await _db;

    final result = await db.query(
      'ayah',
      where: 'page = ?',
      whereArgs: [page],
      orderBy: 'ayah_number ASC',
    );

    return result.map((map) => AyahModel.fromMap(map)).toList();
  }

  Future<bool> isAyahTableEmpty() async {
    final db = await _db;

    final result = await db.rawQuery('SELECT COUNT(*) FROM ayah');

    final count = Sqflite.firstIntValue(result) ?? 0;

    return count == 0;
  }

  Future<void> insertSurahs(List<SurahModel> surahs) async {
    final db = await _db;

    final batch = db.batch();

    for (var surah in surahs) {
      batch.insert(
        'surah',
        surah.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<SurahModel>> getAllSurahs() async {
    final db = await _db;
    final result = await db.query('surah', orderBy: 'id ASC');
    return result.map((row) => SurahModel(
      id: row['id'] as int,
      nameArabic: row['name_ar'] as String,
      nameEnglish: row['name_en'] as String,
      revelationType: row['revelation_type'] as String? ?? '',
      totalAyah: row['total_ayah'] as int,
    )).toList();
  }

  Future<int> getFirstPageBySurahId(int surahId) async {
    final db = await _db;
    final result = await db.query(
      'ayah',
      columns: ['page'],
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['page'] as int : 1;
  }

  Future<SurahModel?> getSurahById(int id) async {
    final db = await _db;

    final result = await db.query(
      'surah',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return SurahModel(
        id: result.first['id'] as int,
        nameArabic: result.first['name_ar'] as String,
        nameEnglish: result.first['name_en'] as String,
        revelationType: result.first['revelation_type'] as String? ?? '',
        totalAyah: result.first['total_ayah'] as int,
      );
    }

    return null;
  }
}