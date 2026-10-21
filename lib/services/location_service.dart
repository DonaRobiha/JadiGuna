import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/location_helper.dart';

class LocationService {
  /// Check and request location permission, then get current position
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // Save to SharedPreferences for quick offline fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(AppConstants.keyUserLatitude, position.latitude);
      await prefs.setDouble(AppConstants.keyUserLongitude, position.longitude);

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Get last known saved position or default location (Yogyakarta)
  Future<Map<String, double>> getLastKnownOrCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.keyUserLatitude) ?? AppConstants.defaultLatitude;
    final lng = prefs.getDouble(AppConstants.keyUserLongitude) ?? AppConstants.defaultLongitude;
    return {'latitude': lat, 'longitude': lng};
  }

  /// Calculate distance from user's current location to a listing
  Future<double?> calculateDistanceFromUser(double? targetLat, double? targetLng) async {
    if (targetLat == null || targetLng == null) return null;
    final coords = await getLastKnownOrCoordinates();
    return LocationHelper.calculateDistanceInMeters(
      coords['latitude']!,
      coords['longitude']!,
      targetLat,
      targetLng,
    );
  }
}
