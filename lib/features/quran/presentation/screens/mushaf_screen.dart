import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/quran_local_datasource.dart';
import '../../data/models/ayah_model.dart';
import '../../data/models/surah_model.dart';
import '../../../../core/database/database_helper.dart';

class MushafScreen extends StatefulWidget {
  final int initialSurahId;

  const MushafScreen({super.key, this.initialSurahId = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late QuranLocalDataSource _localDataSource;
  late PageController _pageController;
  late int _currentSurahId;

  Map<int, SurahModel> _surahMap = {};

  static const int _totalSurahs = 114;

  @override
  void initState() {
    super.initState();
    _localDataSource = QuranLocalDataSource(DatabaseHelper.instance);
    _currentSurahId = widget.initialSurahId;
    // PageView index = surahId - 1 (0-indexed)
    _pageController = PageController(initialPage: widget.initialSurahId - 1);
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final surahs = await _localDataSource.getAllSurahs();
    if (mounted) {
      setState(() {
        _surahMap = {for (final s in surahs) s.id: s};
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surah = _surahMap[_currentSurahId];
    final title = surah?.nameIndonesian.isNotEmpty == true
        ? surah!.nameIndonesian
        : surah?.nameEnglish ?? 'Surah $_currentSurahId';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        reverse: true,
        itemCount: _totalSurahs,
        itemBuilder: (context, index) {
          final surahId = index + 1;
          return FutureBuilder<List<AyahModel>>(
            future: _localDataSource.getAyahsBySurahId(surahId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final ayahs = snapshot.data!;
              if (ayahs.isEmpty) {
                return const Center(child: Text('Tidak ada data'));
              }

              final surah = _surahMap[surahId];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSurahHeader(context, surah, surahId),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          if (surah?.bismillahPre ?? false)
                            _buildBismillahHeader(context),
                          for (final ayah in ayahs)
                            _buildAyahCard(context, ayah),
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
          setState(() => _currentSurahId = index + 1);
        },
      ),
    );
  }

  Widget _buildSurahHeader(BuildContext context, SurahModel? surah, int surahId) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (surah != null && surah.nameArabic.isNotEmpty)
            Text(
              surah.nameArabic,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          Text(
            surah?.nameEnglish ?? 'Surah $surahId',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          if (surah != null && surah.nameIndonesian.isNotEmpty)
            Text(
              surah.nameIndonesian,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 4),
          if (surah != null)
            Text(
              '${surah.revelationType} • ${surah.totalAyah} ayat',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  Widget _buildBismillahHeader(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        textDirection: TextDirection.rtl,
        style: TextStyle(fontSize: 20, height: 2, color: color),
      ),
    );
  }

  Widget _buildAyahCard(BuildContext context, AyahModel ayah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                ayah.ayahNumber.toString(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ayah.textIndopak,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 24, height: 1.8),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ayah.textId.isEmpty ? '-' : ayah.textId,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
