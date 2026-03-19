import 'package:flutter/material.dart';
import '../../data/datasources/quran_local_datasource.dart';
import '../../data/models/ayah_model.dart';
import '../../../../core/database/database_helper.dart';

class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late QuranLocalDataSource localDataSource;
  late PageController _pageController;

  int currentPage = 1;
  List<AyahModel> ayahs = [];

  @override
  void initState() {
    super.initState();
    localDataSource = QuranLocalDataSource(DatabaseHelper.instance);
    _pageController = PageController(initialPage: 603);
    loadPage(currentPage);
  }

  Future<void> loadPage(int page) async {
    final data = await localDataSource.getAyahsByPage(page);

    setState(() {
      ayahs = data;
      currentPage = page;
    });
  }

  String buildMushafText(List<AyahModel> ayahs) {
    String result = "";

    for (var ayah in ayahs) {
      result += "${ayah.textUthmani} ۝${ayah.ayahNumber} ";
    }

    return result;
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
              final surah = await localDataSource.getSurahById(firstAyah.surahId);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🔥 HEADER SURAH
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Surah ${firstAyah.surahId}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Page $pageNumber",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔥 LIST AYAT
                    Expanded(
                      child: ListView.separated(
                        itemCount: pageAyahs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          final ayah = pageAyahs[index];

                          return Container(
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
                                  ayah.textUthmani,
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
                          );
                        },
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