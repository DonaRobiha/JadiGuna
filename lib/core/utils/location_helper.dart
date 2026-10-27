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

  /// Calculate initial bearing (forward azimuth) from coordinate 1 to coordinate 2 in degrees [0, 360)
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double phi1 = _degToRad(lat1);
    final double phi2 = _degToRad(lat2);
    final double deltaLambda = _degToRad(lon2 - lon1);

    final double y = math.sin(deltaLambda) * math.cos(phi2);
    final double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final double bearingRad = math.atan2(y, x);
    final double bearingDeg = (bearingRad * 180.0 / math.pi + 360.0) % 360.0;
    return bearingDeg;
  }

  /// Get Indonesian cardinal direction name for degrees [0, 360)
  static String getCardinalDirection(double degrees) {
    final normalized = (degrees % 360.0 + 360.0) % 360.0;
    if (normalized >= 337.5 || normalized < 22.5) return 'Utara (U)';
    if (normalized >= 22.5 && normalized < 67.5) return 'Timur Laut (TL)';
    if (normalized >= 67.5 && normalized < 112.5) return 'Timur (T)';
    if (normalized >= 112.5 && normalized < 157.5) return 'Tenggara (TG)';
    if (normalized >= 157.5 && normalized < 202.5) return 'Selatan (S)';
    if (normalized >= 202.5 && normalized < 247.5) return 'Barat Daya (BD)';
    if (normalized >= 247.5 && normalized < 292.5) return 'Barat (B)';
    return 'Barat Laut (BL)';
  }

  /// Short cardinal code (e.g. U, TL, T, TG, S, BD, B, BL)
  static String getCardinalCode(double degrees) {
    final normalized = (degrees % 360.0 + 360.0) % 360.0;
    if (normalized >= 337.5 || normalized < 22.5) return 'U';
    if (normalized >= 22.5 && normalized < 67.5) return 'TL';
    if (normalized >= 67.5 && normalized < 112.5) return 'T';
    if (normalized >= 112.5 && normalized < 157.5) return 'TG';
    if (normalized >= 157.5 && normalized < 202.5) return 'S';
    if (normalized >= 202.5 && normalized < 247.5) return 'BD';
    if (normalized >= 247.5 && normalized < 292.5) return 'B';
    return 'BL';
  }

  /// Calculate relative angle between destination bearing and device heading in range [-180, +180]
  /// Positive value means turn right (clockwise), negative value means turn left (counter-clockwise)
  static double calculateRelativeAngle(double targetBearing, double deviceHeading) {
    double diff = (targetBearing - deviceHeading + 360.0) % 360.0;
    if (diff > 180.0) {
      diff -= 360.0;
    }
    return diff;
  }

  /// Get natural Indonesian directional instruction based on relative angle
  static String getRelativeDirectionInstruction(double targetBearing, double deviceHeading) {
    final diff = calculateRelativeAngle(targetBearing, deviceHeading);
    final absDiff = diff.abs().round();

    if (absDiff <= 15) {
      return 'Lurus ke depan (Tepat di depan Anda)';
    } else if (diff > 15 && diff <= 60) {
      return 'Serong ke kanan ($absDiff°)';
    } else if (diff > 60 && diff <= 120) {
      return 'Belok ke kanan ($absDiff°)';
    } else if (diff > 120 && diff <= 165) {
      return 'Serong ke kanan belakang ($absDiff°)';
    } else if (absDiff > 165) {
      return 'Putar balik (Tujuan di belakang Anda)';
    } else if (diff < -120 && diff >= -165) {
      return 'Serong ke kiri belakang ($absDiff°)';
    } else if (diff < -60 && diff >= -120) {
      return 'Belok ke kiri ($absDiff°)';
    } else {
      return 'Serong ke kiri ($absDiff°)';
    }
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
