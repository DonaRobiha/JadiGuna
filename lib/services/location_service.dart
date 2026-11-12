import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/location_helper.dart';

class ResolvedLocationAddress {
  final double latitude;
  final double longitude;
  final String title;
  final String subtitle;
  final String shortCity;
  final String fullAddress;

  const ResolvedLocationAddress({
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.subtitle,
    required this.shortCity,
    required this.fullAddress,
  });
}

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
            accuracy: highAccuracy ? LocationAccuracy.best : LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 12),
          ),
        );
      } catch (_) {
        // Retry with medium accuracy before falling back to last known position
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          );
        } catch (_) {
          position = await Geolocator.getLastKnownPosition();
        }
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
  Stream<Position> getPositionStream({LocationAccuracy accuracy = LocationAccuracy.best}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: 2,
      ),
    );
  }

  /// Reverse-geocode coordinates into a detailed Indonesian street/area/city address
  Future<ResolvedLocationAddress> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=id',
      );
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'JadiGunaApp/1.0 (https://jadiguna.id)',
          'Accept-Language': 'id',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = (data['address'] as Map<String, dynamic>?) ?? {};

        String? pickFirst(List<String> keys) {
          for (final k in keys) {
            final v = addr[k]?.toString().trim();
            if (v != null && v.isNotEmpty) return v;
          }
          return null;
        }

        final road = pickFirst(['road', 'pedestrian', 'residential', 'footway', 'path']);
        final houseNum = pickFirst(['house_number']);
        final roadFull = road != null
            ? (houseNum != null ? '$road No. $houseNum' : road)
            : null;
        final place = pickFirst(['amenity', 'building', 'shop', 'tourism', 'leisure', 'neighbourhood', 'hamlet']);
        final village = pickFirst(['village', 'quarter', 'suburb']);
        final rawDistrict = pickFirst(['city_district', 'district', 'subdistrict', 'suburb']);
        final district = rawDistrict != null &&
                !rawDistrict.toLowerCase().startsWith('kec')
            ? 'Kec. $rawDistrict'
            : rawDistrict;
        final city = pickFirst(['city', 'town', 'county', 'regency', 'municipality']);
        final state = pickFirst(['state', 'region']);

        final titleParts = <String>[];
        void addTitlePart(String? val) {
          if (val == null || val.isEmpty) return;
          if (!titleParts.any((e) => e.toLowerCase() == val.toLowerCase())) {
            titleParts.add(val);
          }
        }

        addTitlePart(place ?? roadFull);
        if (place != null && roadFull != null) {
          addTitlePart(roadFull);
        } else {
          addTitlePart(village);
        }

        final subtitleParts = <String>[];
        void addSubPart(String? val) {
          if (val == null || val.isEmpty) return;
          if (!subtitleParts.any((e) => e.toLowerCase() == val.toLowerCase()) &&
              !titleParts.any((e) => e.toLowerCase() == val.toLowerCase())) {
            subtitleParts.add(val);
          }
        }

        addSubPart(district);
        addSubPart(city);
        addSubPart(state);

        String title = titleParts.join(', ');
        if (title.isEmpty) {
          final displayName = data['display_name']?.toString() ?? '';
          if (displayName.isNotEmpty) {
            final split = displayName.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            title = split.take(2).join(', ');
          }
        }
        if (title.isEmpty) {
          title = 'Titik Lokasi (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
        }

        final subtitle = subtitleParts.isNotEmpty
            ? subtitleParts.join(', ')
            : 'Koordinat ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

        final shortParts = <String>[];
        if (rawDistrict != null && rawDistrict.isNotEmpty) {
          shortParts.add(rawDistrict);
        } else if (village != null && village.isNotEmpty) {
          shortParts.add(village);
        }
        if (city != null && city.isNotEmpty && !shortParts.any((e) => e.toLowerCase() == city.toLowerCase())) {
          shortParts.add(city);
        } else if (state != null && state.isNotEmpty && shortParts.isEmpty) {
          shortParts.add(state);
        }
        final shortCity = shortParts.isNotEmpty ? shortParts.join(', ') : title;
        final fullAddress = subtitleParts.isNotEmpty ? '$title, $subtitle' : title;

        return ResolvedLocationAddress(
          latitude: lat,
          longitude: lng,
          title: title,
          subtitle: subtitle,
          shortCity: shortCity,
          fullAddress: fullAddress,
        );
      }
    } catch (_) {}

    final coordLabel = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    return ResolvedLocationAddress(
      latitude: lat,
      longitude: lng,
      title: 'Lokasi GPS ($coordLabel)',
      subtitle: 'Koordinat Satelit Aktif',
      shortCity: 'GPS ($coordLabel)',
      fullAddress: 'Lokasi GPS ($coordLabel)',
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
