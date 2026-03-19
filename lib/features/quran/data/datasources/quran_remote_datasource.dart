import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ayah_model.dart';
import '../models/surah_model.dart';

class QuranRemoteDataSource {
  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static const int _totalSurahs = 114;
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  // Translation ID 33 = Kemenag RI (Indonesian)
  static const int _indonesianTranslationId = 33;

  Future<http.Response> _getWithRetry(String url) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(_timeout);
        if (response.statusCode == 200) return response;

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
      await Future.delayed(Duration(seconds: attempt));
    }
  }

  /// Fetch semua data chapter (surah) dari quran.com API v4.
  Future<List<SurahModel>> _fetchChapters() async {
    final response = await _getWithRetry('$_baseUrl/chapters?language=id');
    final chapters = jsonDecode(response.body)['chapters'] as List;

    return chapters.map((c) {
      final translatedName = c['translated_name'];
      return SurahModel(
        id: c['id'],
        nameArabic: c['name_arabic'] ?? '',
        nameEnglish: c['name_simple'] ?? '',
        nameIndonesian: translatedName != null ? translatedName['name'] ?? '' : '',
        revelationType: _capitalizeFirst(c['revelation_place'] ?? ''),
        totalAyah: c['verses_count'],
        bismillahPre: c['bismillah_pre'] ?? false,
      );
    }).toList();
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Fetch seluruh data Quran (surah + ayat) dari quran.com API v4.
  /// [onProgress] melaporkan progress (surah ke-N dari 114).
  Future<({List<SurahModel> surahs, List<AyahModel> ayahs})> fetchAllQuranData({
    void Function(int current, int total)? onProgress,
  }) async {
    final surahs = await _fetchChapters();
    final List<AyahModel> ayahs = [];

    for (int i = 1; i <= _totalSurahs; i++) {
      final url = '$_baseUrl/verses/by_chapter/$i'
          '?fields=text_indopak'
          '&translations=$_indonesianTranslationId'
          '&per_page=300';

      final response = await _getWithRetry(url);
      final verses = jsonDecode(response.body)['verses'] as List;

      for (final verse in verses) {
        final translations = verse['translations'] as List?;
        final textId = translations != null && translations.isNotEmpty
            ? _stripHtmlTags(translations.first['text'] as String? ?? '')
            : '';

        ayahs.add(AyahModel(
          surahId: i,
          ayahNumber: verse['verse_number'],
          page: verse['page_number'],
          juz: verse['juz_number'],
          textIndopak: verse['text_indopak'] ?? '',
          textId: textId,
        ));
      }

      onProgress?.call(i, _totalSurahs);
    }

    return (surahs: surahs, ayahs: ayahs);
  }

  // Terjemahan dari quran.com kadang mengandung tag HTML <sup> dll
  String _stripHtmlTags(String text) =>
      text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
