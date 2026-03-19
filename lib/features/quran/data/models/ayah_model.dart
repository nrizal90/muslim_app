class AyahModel {
  final int? id;
  final int surahId;
  final int ayahNumber;
  final int page;
  final int juz;
  final String textUthmani;
  final String textId;

  AyahModel({
    this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.page,
    required this.juz,
    required this.textUthmani,
    required this.textId,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      surahId: json['surah_number'],
      ayahNumber: json['number_in_surah'],
      page: json['page'],
      juz: json['juz'],
      textUthmani: json['text_uthmani'],
      textId: json['translation'],
    );
  }

  factory AyahModel.fromMap(Map<String, dynamic> map) {
    return AyahModel(
      id: map['id'],
      surahId: map['surah_id'],
      ayahNumber: map['ayah_number'],
      page: map['page'],
      juz: map['juz'],
      textUthmani: map['text_uthmani'],
      textId: map['text_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'page': page,
      'juz': juz,
      'text_uthmani': textUthmani,
      'text_id': textId,
    };
  }
}