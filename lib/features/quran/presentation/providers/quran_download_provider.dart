import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/quran_local_datasource.dart';
import '../../data/datasources/quran_remote_datasource.dart';
import '../../../../core/database/database_helper.dart';

class QuranDownloadState {
  final bool isReady;
  final bool isDownloading;
  final double progress; // 0.0 - 1.0
  final String? error;

  const QuranDownloadState({
    this.isReady = false,
    this.isDownloading = false,
    this.progress = 0,
    this.error,
  });

  QuranDownloadState copyWith({
    bool? isReady,
    bool? isDownloading,
    double? progress,
    String? error,
  }) =>
      QuranDownloadState(
        isReady: isReady ?? this.isReady,
        isDownloading: isDownloading ?? this.isDownloading,
        progress: progress ?? this.progress,
        error: error,
      );
}

class QuranDownloadNotifier extends Notifier<QuranDownloadState> {
  @override
  QuranDownloadState build() {
    _checkAndDownloadIfNeeded();
    return const QuranDownloadState();
  }

  Future<void> _checkAndDownloadIfNeeded() async {
    final local = QuranLocalDataSource(DatabaseHelper.instance);
    final isEmpty = await local.isAyahTableEmpty();

    if (!isEmpty) {
      state = state.copyWith(isReady: true);
      return;
    }

    await download();
  }

  Future<void> download() async {
    state = state.copyWith(isDownloading: true, progress: 0);

    try {
      final local = QuranLocalDataSource(DatabaseHelper.instance);
      final result = await QuranRemoteDataSource().fetchAllQuranData(
        onProgress: (current, total) {
          state = state.copyWith(progress: current / total);
        },
      );

      await local.insertSurahs(result.surahs);
      await local.insertAyahs(result.ayahs);

      state = state.copyWith(isReady: true, isDownloading: false, progress: 1);
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: e.toString());
    }
  }
}

final quranDownloadProvider =
    NotifierProvider<QuranDownloadNotifier, QuranDownloadState>(
  QuranDownloadNotifier.new,
);
