import 'dart:math' as math;

class LocationHelper {
  /// Calculate distance in meters between two lat/lng coordinates using Haversine formula
  static double calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000.0;

    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degToRad(double deg) {
    return deg * (math.pi / 180.0);
  }

  /// Format distance into human-friendly string (e.g. "850 m", "3.2 km")
  static String formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return 'Jarak tidak diketahui';

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m dari Anda';
    } else {
      final km = distanceInMeters / 1000.0;
      return '${km.toStringAsFixed(1)} km dari Anda';
    }
  }
}
