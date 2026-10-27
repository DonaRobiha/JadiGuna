import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/location_helper.dart';

class LocationService {
  static final LocationService instance = LocationService();

  /// Check if coordinates match the Android Emulator default dummy location (Googleplex, Mountain View)
  static bool isEmulatorDefaultCoordinates(double lat, double lng) {
    return (lat - 37.422).abs() < 0.05 && (lng - (-122.084)).abs() < 0.05;
  }

  /// Get real location via network IP or saved/Indonesian default
  Future<Map<String, double>> getRealOrSavedLocation() async {
    // 1. Try saved user location if it is a valid Indonesian/non-emulator location
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble(AppConstants.keyUserLatitude);
      final savedLng = prefs.getDouble(AppConstants.keyUserLongitude);
      if (savedLat != null && savedLng != null) {
        if (!isEmulatorDefaultCoordinates(savedLat, savedLng)) {
          return {'latitude': savedLat, 'longitude': savedLng};
        }
      }
    } catch (_) {}

    // 2. Try network IP geolocation to detect user's actual Indonesian province/city
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();
          if (!isEmulatorDefaultCoordinates(lat, lon)) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble(AppConstants.keyUserLatitude, lat);
            await prefs.setDouble(AppConstants.keyUserLongitude, lon);
            return {'latitude': lat, 'longitude': lon};
          }
        }
      }
    } catch (_) {}

    // 3. Fallback to default Indonesian location (Sleman / Yogyakarta)
    return {
      'latitude': AppConstants.defaultLatitude,
      'longitude': AppConstants.defaultLongitude,
    };
  }

  /// Check and request location permission, then get current position with high accuracy
  Future<Position?> getCurrentLocation({bool highAccuracy = true}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await getLastKnownPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await getLastKnownPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await getLastKnownPosition();
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          ),
        );
      } catch (_) {
        // Fallback to last known hardware GPS position if fresh satellite fix times out
        position = await Geolocator.getLastKnownPosition();
      }

      // If position is the Android Emulator default dummy coordinate (Mountain View),
      // replace with user's real Indonesian network location
      if (position != null && isEmulatorDefaultCoordinates(position.latitude, position.longitude)) {
        final realCoords = await getRealOrSavedLocation();
        position = Position(
          latitude: realCoords['latitude']!,
          longitude: realCoords['longitude']!,
          timestamp: position.timestamp,
          accuracy: 10.0,
          altitude: position.altitude,
          altitudeAccuracy: position.altitudeAccuracy,
          heading: position.heading,
          headingAccuracy: position.headingAccuracy,
          speed: position.speed,
          speedAccuracy: position.speedAccuracy,
        );
      }

      if (position != null) {
        // Save to SharedPreferences for quick offline fallback
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(AppConstants.keyUserLatitude, position.latitude);
        await prefs.setDouble(AppConstants.keyUserLongitude, position.longitude);
      }

      return position;
    } catch (e) {
      return await getLastKnownPosition();
    }
  }

  /// Get last known saved position from hardware or SharedPreferences or default location
  Future<Map<String, double>> getLastKnownOrCoordinates() async {
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && !isEmulatorDefaultCoordinates(lastPos.latitude, lastPos.longitude)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(AppConstants.keyUserLatitude, lastPos.latitude);
        await prefs.setDouble(AppConstants.keyUserLongitude, lastPos.longitude);
        return {'latitude': lastPos.latitude, 'longitude': lastPos.longitude};
      }
    } catch (_) {}

    return getRealOrSavedLocation();
  }

  /// Get last known Position object from GPS hardware (ignoring emulator dummy)
  Future<Position?> getLastKnownPosition() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null && !isEmulatorDefaultCoordinates(pos.latitude, pos.longitude)) {
        return pos;
      }
      final real = await getRealOrSavedLocation();
      return Position(
        latitude: real['latitude']!,
        longitude: real['longitude']!,
        timestamp: DateTime.now(),
        accuracy: 15.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Real-time high-accuracy position stream
  Stream<Position> getPositionStream({LocationAccuracy accuracy = LocationAccuracy.high}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: 2,
      ),
    );
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
