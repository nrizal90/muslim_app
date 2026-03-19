import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ayah_model.dart';
import '../models/surah_model.dart';

class QuranRemoteDataSource {

  Future<List<AyahModel>> fetchAllAyahs() async {
    final response = await http.get(
      Uri.parse("https://api.alquran.cloud/v1/quran/quran-uthmani"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final surahs = data['data']['surahs'];

      List<AyahModel> ayahs = [];

      for (var surah in surahs) {
        List<SurahModel> surahList = [];
        
        surahList.add(
          SurahModel(
            id: surah['number'],
            nameArabic: surah['name'],
            nameEnglish: surah['englishName'],
            revelationType: surah['revelationType'],
            totalAyah: surah['numberOfAyahs'],
          ),
        );

        for (var ayah in surah['ayahs']) {
          ayahs.add(
            AyahModel(
              surahId: surah['number'],
              ayahNumber: ayah['numberInSurah'],
              page: ayah['page'],
              juz: ayah['juz'],
              textUthmani: ayah['text'],
              textId: "", // nanti kita isi terjemahan
            ),
          );
        }
      }

      return ayahs;
    } else {
      throw Exception("Gagal fetch Quran");
    }
  }
}