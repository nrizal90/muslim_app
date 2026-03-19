import '../entities/prayer_time.dart';

abstract class PrayerRepository {
  Future<PrayerTime> getTodayPrayerTime();
}