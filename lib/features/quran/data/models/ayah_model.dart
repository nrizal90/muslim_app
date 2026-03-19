class AyahModel {
  final int? id;
  final int surahId;
  final int ayahNumber;
  final int page;
  final int juz;
  final String textIndopak;
  final String textId;

  AyahModel({
    this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.page,
    required this.juz,
    required this.textIndopak,
    required this.textId,
  });

  factory AyahModel.fromMap(Map<String, dynamic> map) {
    return AyahModel(
      id: map['id'],
      surahId: map['surah_id'],
      ayahNumber: map['ayah_number'],
      page: map['page'],
      juz: map['juz'],
      textIndopak: map['text_indopak'],
      textId: map['text_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'page': page,
      'juz': juz,
      'text_indopak': textIndopak,
      'text_id': textId,
    };
  }
}
