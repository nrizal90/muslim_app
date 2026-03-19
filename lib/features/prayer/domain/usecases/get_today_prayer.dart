import '../entities/prayer_time.dart';
import '../repositories/prayer_repository.dart';

class GetTodayPrayer {
  final PrayerRepository repository;

  GetTodayPrayer(this.repository);

  Future<PrayerTime> call() {
    return repository.getTodayPrayerTime();
  }
}