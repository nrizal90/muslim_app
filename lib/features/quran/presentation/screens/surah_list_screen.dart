import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/quran_local_datasource.dart';
import '../../data/models/surah_model.dart';
import '../../../../core/database/database_helper.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final _localDataSource = QuranLocalDataSource(DatabaseHelper.instance);
  late Future<List<SurahModel>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = _localDataSource.getAllSurahs();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Al-Qur'an"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SurahModel>>(
        future: _surahsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final surahs = snapshot.data!;

          return ListView.separated(
            itemCount: surahs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return ListTile(
                onTap: () => context.push('/quran/mushaf', extra: surah.id),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    surah.id.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text(
                  surah.nameIndonesian.isNotEmpty
                      ? surah.nameIndonesian
                      : surah.nameEnglish,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "${surah.nameEnglish} • ${surah.revelationType} • ${surah.totalAyah} ayat",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  surah.nameArabic,
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
