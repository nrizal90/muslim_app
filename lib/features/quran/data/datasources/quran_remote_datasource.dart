import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ayah_model.dart';
import '../models/surah_model.dart';

class QuranRemoteDataSource {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const int _totalSurahs = 114;
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  /// Fetch satu URL dengan retry otomatis (max [_maxRetries] kali).
  Future<http.Response> _getWithRetry(String url) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(_timeout);

        if (response.statusCode == 200) return response;

        // Status bukan 200, retry jika masih ada kesempatan
        attempt++;
        if (attempt >= _maxRetries) {
          throw Exception('HTTP ${response.statusCode} setelah $attempt percobaan: $url');
        }
      } on SocketException {
        attempt++;
        if (attempt >= _maxRetries) rethrow;
      } on TimeoutException {
        attempt++;
        if (attempt >= _maxRetries) rethrow;
      }

      // Tunggu sebelum retry (1s, 2s, 3s)
      await Future.delayed(Duration(seconds: attempt));
    }
  }

  /// Fetch seluruh data Quran per-surah (Arabic + terjemahan Indonesia).
  /// Menggunakan [onProgress] untuk melaporkan progress (current, total).
  Future<({List<SurahModel> surahs, List<AyahModel> ayahs})> fetchAllQuranData({
    void Function(int current, int total)? onProgress,
  }) async {
    final List<SurahModel> surahs = [];
    final List<AyahModel> ayahs = [];

    for (int i = 1; i <= _totalSurahs; i++) {
      final responses = await Future.wait([
        _getWithRetry('$_baseUrl/surah/$i/quran-uthmani'),
        _getWithRetry('$_baseUrl/surah/$i/id.indonesian'),
      ]);

      final arabicData = jsonDecode(responses[0].body)['data'];
      final idAyahs = jsonDecode(responses[1].body)['data']['ayahs'] as List;

      surahs.add(SurahModel(
        id: arabicData['number'],
        nameArabic: arabicData['name'],
        nameEnglish: arabicData['englishName'],
        revelationType: arabicData['revelationType'],
        totalAyah: arabicData['numberOfAyahs'],
      ));

      final arabicAyahs = arabicData['ayahs'] as List;
      for (int j = 0; j < arabicAyahs.length; j++) {
        final ayah = arabicAyahs[j];
        final idText = j < idAyahs.length ? idAyahs[j]['text'] as String : '';

        ayahs.add(AyahModel(
          surahId: arabicData['number'],
          ayahNumber: ayah['numberInSurah'],
          page: ayah['page'],
          juz: ayah['juz'],
          textUthmani: ayah['text'],
          textId: idText,
        ));
      }

      onProgress?.call(i, _totalSurahs);
    }

    return (surahs: surahs, ayahs: ayahs);
  }
}
