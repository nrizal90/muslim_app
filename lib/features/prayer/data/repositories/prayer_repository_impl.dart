import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/prayer_time.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../../../../core/services/location_service.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  final LocationService locationService;

  PrayerRepositoryImpl(this.locationService);

  @override
  Future<PrayerTime> getTodayPrayerTime() async {
    Position position = await locationService.getCurrentLocation();

    final coordinates =
        Coordinates(position.latitude, position.longitude);

    final params = CalculationMethod.singapore.getParameters();
    params.fajrAngle = 20.0;
    // final params = CalculationParameters(
    //   method: CalculationMethod.other,
    //   fajrAngle: 20.0,
    //   ishaAngle: 18.0,
    // );

    params.madhab = Madhab.shafi;
    // biar aman
    params.adjustments.fajr = 2;
    params.adjustments.dhuhr = 2;
    params.adjustments.asr = 2;
    params.adjustments.maghrib = 2;
    params.adjustments.isha = 2;

    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );

    return PrayerTime(
      fajr: prayerTimes.fajr,
      syuruq: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
  }
}