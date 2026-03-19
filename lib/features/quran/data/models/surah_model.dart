class SurahModel {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String revelationType;
  final int totalAyah;

  SurahModel({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.revelationType,
    required this.totalAyah,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ar': nameArabic,
      'name_en': nameEnglish,
      'revelation_type': revelationType,
      'total_ayah': totalAyah,
    };
  }
}