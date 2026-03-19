import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/prayer_repository_impl.dart';
import '../../domain/usecases/get_today_prayer.dart';
import '../../domain/entities/prayer_time.dart';
import '../../../../core/services/location_service.dart';

final locationServiceProvider = Provider((ref) {
  return LocationService();
});

final prayerRepositoryProvider = Provider((ref) {
  final locationService = ref.read(locationServiceProvider);
  return PrayerRepositoryImpl(locationService);
});

final getTodayPrayerProvider = Provider((ref) {
  final repository = ref.read(prayerRepositoryProvider);
  return GetTodayPrayer(repository);
});

final prayerTimeProvider = FutureProvider<PrayerTime>((ref) async {
  final usecase = ref.read(getTodayPrayerProvider);
  return usecase();
});