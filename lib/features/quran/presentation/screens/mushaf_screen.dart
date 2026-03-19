import 'package:flutter/material.dart';
import '../../data/datasources/quran_local_datasource.dart';
import '../../data/models/ayah_model.dart';
import '../../../../core/database/database_helper.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;

  const MushafScreen({super.key, this.initialPage = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late QuranLocalDataSource localDataSource;
  late PageController _pageController;

  late int currentPage;

  // Prefix Bismillah yang disertakan API di teks ayah 1 setiap surah
  static const _bismillahPrefix = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  String _stripBismillah(String text) {
    if (text.startsWith(_bismillahPrefix)) {
      return text.substring(_bismillahPrefix.length).trimLeft();
    }
    return text;
  }

  @override
  void initState() {
    super.initState();
    localDataSource = QuranLocalDataSource(DatabaseHelper.instance);
    currentPage = widget.initialPage;
    // PageView index = page - 1, reverse: true jadi index 0 = halaman terakhir
    // Kita harus hitung index yang benar untuk reverse PageView
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mushaf - Page $currentPage"),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        reverse: true,
        // itemCount: 604,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;

          return FutureBuilder<List<AyahModel>>(
            future: localDataSource.getAyahsByPage(pageNumber),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final pageAyahs = snapshot.data!;
              final firstAyah = pageAyahs.first;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🔥 HEADER SURAH
                    FutureBuilder(
                      future: localDataSource.getSurahById(firstAyah.surahId),
                      builder: (context, surahSnapshot) {
                        final surahName = surahSnapshot.data?.nameEnglish ?? "Surah ${firstAyah.surahId}";
                        final surahArabic = surahSnapshot.data?.nameArabic ?? "";

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              if (surahArabic.isNotEmpty)
                                Text(
                                  surahArabic,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                surahName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Halaman $pageNumber",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // 🔥 LIST AYAT
                    Expanded(
                      child: ListView(
                        children: [
                          for (final ayah in pageAyahs) ...[
                            // Bismillah di awal tiap surah kecuali Al-Fatihah (1) dan At-Tawbah (9)
                            if (ayah.ayahNumber == 1 &&
                                ayah.surahId != 1 &&
                                ayah.surahId != 9) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontSize: 20,
                                    height: 2,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Nomor ayat
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.grey.shade200,
                                      child: Text(
                                        ayah.ayahNumber.toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Arab
                                  Text(
                                    (ayah.ayahNumber == 1 && ayah.surahId != 1 && ayah.surahId != 9)
                                        ? _stripBismillah(ayah.textUthmani)
                                        : ayah.textUthmani,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      height: 1.8,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Terjemahan
                                  Text(
                                    ayah.textId.isEmpty ? "-" : ayah.textId,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        onPageChanged: (index) {
          setState(() {
            currentPage = index + 1;
          });
        },
      ),
    );
  }
}