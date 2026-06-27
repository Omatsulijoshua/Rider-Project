import 'dart:math';

class MapUtils {
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(endLatitude - startLatitude);
    final dLng = _toRadians(endLongitude - startLongitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLatitude)) *
            cos(_toRadians(endLatitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double estimatePrice(double distanceKm) {
    const baseFare = 1000.0;
    const perKmRate = 250.0;
    return baseFare + (distanceKm * perKmRate);
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
