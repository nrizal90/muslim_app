import 'dart:math';

class GetQiblaDirection {
  double call(double userLat, double userLng) {
    const double kaabaLat = 21.4225;
    const double kaabaLng = 39.8262;

    final lat1 = userLat * (pi / 180);
    final lon1 = userLng * (pi / 180);
    final lat2 = kaabaLat * (pi / 180);
    final lon2 = kaabaLng * (pi / 180);

    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) -
        sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x);

    return (bearing * 180 / pi + 360) % 360;
  }
}