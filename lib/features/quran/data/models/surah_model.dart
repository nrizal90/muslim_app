class SurahModel {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String nameIndonesian;
  final String revelationType;
  final int totalAyah;
  final bool bismillahPre;

  SurahModel({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameIndonesian,
    required this.revelationType,
    required this.totalAyah,
    required this.bismillahPre,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ar': nameArabic,
      'name_en': nameEnglish,
      'name_id': nameIndonesian,
      'revelation_type': revelationType,
      'total_ayah': totalAyah,
      'bismillah_pre': bismillahPre ? 1 : 0,
    };
  }
}
