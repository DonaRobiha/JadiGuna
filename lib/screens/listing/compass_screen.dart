import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/listing_model.dart';
import '../../services/compass_service.dart';
import '../../services/location_service.dart';
import '../../core/utils/location_helper.dart';

/// Full-screen compass navigator for navigating toward a listing's pickup location
/// or for general orientation and magnetic heading exploration.
class CompassScreen extends StatefulWidget {
  final ListingModel? listing;

  const CompassScreen({super.key, this.listing});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  final CompassService _compassService = CompassService();

  CompassReading? _reading;
  double _deviceHeading = 0.0;
  double _unwrappedHeading = 0.0;
  double _lastRawHeading = 0.0;
  bool _hasFirstReading = false;

  // Toggle True North vs Magnetic North
  bool _useTrueNorth = false;

  double _targetBearing = 0.0;
  double _distanceMeters = 0.0;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _locationError;

  bool get _hasValidDestination =>
      widget.listing != null &&
      widget.listing!.latitude != null &&
      widget.listing!.longitude != null;

  @override
  void initState() {
    super.initState();
    _initCompassAndLocation();
  }

  Future<void> _initCompassAndLocation() async {
    try {
      final position = await LocationService.instance.getCurrentLocation();
      _currentPosition = position;

      if (position != null) {
        _compassService.updateLocation(position.latitude, position.longitude);

        if (_hasValidDestination) {
          _distanceMeters = LocationHelper.calculateDistanceInMeters(
            position.latitude,
            position.longitude,
            widget.listing!.latitude!,
            widget.listing!.longitude!,
          );
          _targetBearing = LocationHelper.calculateBearing(
            position.latitude,
            position.longitude,
            widget.listing!.latitude!,
            widget.listing!.longitude!,
          );
        }
      }
    } catch (e) {
      _locationError = 'Tidak dapat mendeteksi lokasi: $e';
    }

    _compassService.startListening(
      userLatitude: _currentPosition?.latitude,
      userLongitude: _currentPosition?.longitude,
      onReadingUpdate: (reading) {
        if (!mounted) return;
        final activeHeading = _useTrueNorth ? reading.trueHeading : reading.heading;

        setState(() {
          _reading = reading;
          if (!_hasFirstReading) {
            _unwrappedHeading = activeHeading;
            _lastRawHeading = activeHeading;
            _deviceHeading = activeHeading;
            _hasFirstReading = true;
          } else {
            // Continuous unwrap to guarantee butter-smooth rotation without 360-to-0 jumping
            double diff = activeHeading - _lastRawHeading;
            if (diff > 180.0) diff -= 360.0;
            if (diff < -180.0) diff += 360.0;

            _unwrappedHeading += diff;
            _lastRawHeading = activeHeading;
            _deviceHeading = activeHeading;
          }
        });
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _compassService.stopListening();
    super.dispose();
  }

  void _toggleTrueNorth() {
    setState(() {
      _useTrueNorth = !_useTrueNorth;
      if (_reading != null) {
        final newHeading = _useTrueNorth ? _reading!.trueHeading : _reading!.heading;
        double diff = newHeading - _lastRawHeading;
        if (diff > 180.0) diff -= 360.0;
        if (diff < -180.0) diff += 360.0;
        _unwrappedHeading += diff;
        _lastRawHeading = newHeading;
        _deviceHeading = newHeading;
      }
    });

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _useTrueNorth
              ? 'Mode: Utara Sejati (Geografis) Aktif • Deklinasi: ${_reading?.declination.toStringAsFixed(1) ?? "0.0"}°'
              : 'Mode: Utara Magnetik (Sensor Fisik) Aktif',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E2820),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openGoogleMapsRoute() async {
    if (!_hasValidDestination) return;

    final lat = widget.listing!.latitude!;
    final lng = widget.listing!.longitude!;
    final cleanLabel = Uri.encodeComponent(widget.listing!.locationName);

    final googleNavUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final googleMapsDirUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$cleanLabel&travelmode=driving',
    );
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($cleanLabel)');

    try {
      if (await canLaunchUrl(googleNavUri)) {
        await launchUrl(googleNavUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(googleMapsDirUrl)) {
        await launchUrl(googleMapsDirUrl, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(googleMapsDirUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka Google Maps: $e')),
        );
      }
    }
  }

  void _showCalibrationGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D241F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final field = _reading?.fieldStrength ?? 42.0;
        final accuracy = _reading?.accuracy ?? CompassAccuracy.high;
        final accuracyLabel = accuracy == CompassAccuracy.high
            ? 'Optimal / Tinggi'
            : (accuracy == CompassAccuracy.medium ? 'Cukup Baik' : 'Perlu Kalibrasi');

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF22C55E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kalibrasi & Akurasi Kompas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Petunjuk akurasi sensor magnetik perangkat',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _buildMetricRow('Kekuatan Medan Magnet', '${field.toStringAsFixed(1)} µT (Normal: 25 - 65 µT)'),
                    const Divider(height: 16, color: Colors.white12),
                    _buildMetricRow('Status Kalibrasi', accuracyLabel),
                    const Divider(height: 16, color: Colors.white12),
                    _buildMetricRow('Kemiringan Pitch / Roll', '${_reading?.pitch.toStringAsFixed(1) ?? "0.0"}° / ${_reading?.roll.toStringAsFixed(1) ?? "0.0"}°'),
                    const Divider(height: 16, color: Colors.white12),
                    _buildMetricRow('Deklinasi Magnetik', '${(_reading?.declination ?? 0) >= 0 ? "+" : ""}${_reading?.declination.toStringAsFixed(1) ?? "0.0"}°'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.all_inclusive_rounded, color: Color(0xFF86EFAC), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cara Kalibrasi: Gerakkan ponsel Anda di udara membentuk pola angka 8 (delapan) sebanyak 2-3 kali secara perlahan. Jauhkan dari benda berbahan logam tebal atau casing bermagnet.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: const Color(0xFF0F291B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final unwrappedDialTurns = -_unwrappedHeading / 360.0;
    final unwrappedArrowTurns = (_targetBearing - _unwrappedHeading) / 360.0;
    final isNavigating = _hasValidDestination && _currentPosition != null;

    final directionInstruction = isNavigating
        ? LocationHelper.getRelativeDirectionInstruction(_targetBearing, _deviceHeading)
        : null;

    final isLevel = _reading?.isLevel ?? true;
    final pitch = _reading?.pitch ?? 0.0;
    final roll = _reading?.roll ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF161C17), // Deep luxury dark forest background
      appBar: AppBar(
        backgroundColor: const Color(0xFF161C17),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.listing != null ? 'Kompas Menuju Lokasi' : 'Kompas Digital',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16.5,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              widget.listing != null
                  ? (widget.listing!.title)
                  : (_useTrueNorth ? 'Utara Sejati (Koreksi Deklinasi)' : 'Utara Magnetik (Sensor Fisik)'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // True North toggle button
          IconButton(
            onPressed: _toggleTrueNorth,
            tooltip: _useTrueNorth ? 'Beralih ke Utara Magnetik' : 'Beralih ke Utara Sejati',
            icon: Icon(
              _useTrueNorth ? Icons.public_rounded : Icons.explore_outlined,
              color: _useTrueNorth ? const Color(0xFF34D399) : Colors.white70,
              size: 22,
            ),
          ),
          // Calibration info button
          IconButton(
            onPressed: _showCalibrationGuide,
            tooltip: 'Kalibrasi & Akurasi Kompas',
            icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 22),
          ),
          if (_hasValidDestination)
            IconButton(
              onPressed: _openGoogleMapsRoute,
              tooltip: 'Buka Rute di Google Maps',
              icon: const Icon(Icons.near_me_rounded, color: Color(0xFF34D399), size: 22),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF22C55E)),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 680;
                  final dialSize = math.min(
                    280.0,
                    math.min(constraints.maxWidth * 0.72, constraints.maxHeight * 0.38),
                  ).clamp(160.0, 280.0);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        // 1. Heading Degree & Cardinal Direction Badge
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_deviceHeading.round()}°',
                              style: TextStyle(
                                fontSize: isCompact ? 44 : 54,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: -2,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                // Cardinal Direction badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: _compassService.hasMagnetometer
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFFEAB308),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        LocationHelper.getCardinalDirection(_deviceHeading).toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // True / Magnetic North toggle chip
                                InkWell(
                                  onTap: _toggleTrueNorth,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _useTrueNorth
                                          ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _useTrueNorth
                                            ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                                            : Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _useTrueNorth ? Icons.public : Icons.explore_outlined,
                                          size: 13,
                                          color: _useTrueNorth ? const Color(0xFF86EFAC) : Colors.white70,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _useTrueNorth ? 'Utara Sejati' : 'Utara Magnet',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: _useTrueNorth ? const Color(0xFF86EFAC) : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Level indicator pill
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isLevel
                                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLevel
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLevel ? Icons.check_circle_outline_rounded : Icons.screen_rotation_rounded,
                                size: 12,
                                color: isLevel ? const Color(0xFF22C55E) : Colors.white54,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isLevel
                                    ? 'Posisi Datar • Akurasi Optimal'
                                    : 'Kemiringan: ${pitch.abs().round()}° • Tahan Datar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isLevel ? FontWeight.w700 : FontWeight.w500,
                                  color: isLevel ? const Color(0xFF86EFAC) : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Direction instruction pill if navigating to destination
                        if (directionInstruction != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.navigation_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    directionInstruction,
                                    style: const TextStyle(
                                      color: Color(0xFF86EFAC),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: isCompact ? 10 : 16),

                        // 2. Ultra-Smooth Vector Compass Dial with Active Inclinometer Level
                        Center(
                          child: SizedBox(
                            width: dialSize,
                            height: dialSize,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: 320,
                                height: 320,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Rotating Vector Dial
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: unwrappedDialTurns, end: unwrappedDialTurns),
                                      duration: const Duration(milliseconds: 60),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, turns, child) {
                                        return Transform.rotate(
                                          angle: turns * 2 * math.pi,
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        width: 320,
                                        height: 320,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black,
                                        ),
                                        child: CustomPaint(
                                          size: const Size(320, 320),
                                          painter: _SmoothCompassDialPainter(),
                                        ),
                                      ),
                                    ),

                                    // Dynamic Level Bubble & Center Reticle Crosshairs
                                    IgnorePointer(
                                      child: CustomPaint(
                                        size: const Size(140, 140),
                                        painter: _LevelBubbleReticlePainter(
                                          pitch: pitch,
                                          roll: roll,
                                          isLevel: isLevel,
                                        ),
                                      ),
                                    ),

                                    // Rotating Target Pointer Arrow (only when destination exists)
                                    if (isNavigating)
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: unwrappedArrowTurns, end: unwrappedArrowTurns),
                                        duration: const Duration(milliseconds: 60),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, turns, child) {
                                          return Transform.rotate(
                                            angle: turns * 2 * math.pi,
                                            child: child,
                                          );
                                        },
                                        child: SizedBox(
                                          width: 320,
                                          height: 320,
                                          child: CustomPaint(
                                            size: const Size(320, 320),
                                            painter: _TargetArrowPainter(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 12 : 18),

                        // 3. Bottom Information Card (Destination Mode vs General Mode)
                        if (widget.listing != null)
                          _buildDestinationCard(isCompact, isNavigating)
                        else
                          _buildGeneralSensorInfoCard(isCompact),

                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// Card shown when viewing a specific listing destination
  Widget _buildDestinationCard(bool isCompact, bool isNavigating) {
    final listing = widget.listing!;

    if (!_hasValidDestination) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF232B25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Koordinat Belum Tersedia',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pemilik barang belum menandai koordinat GPS persis untuk iklan ini. Kompas beroperasi sebagai penunjuk arah mata angin umum.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF232B25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 9 : 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF22C55E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _currentPosition != null
                          ? 'Jarak: ${_formatDistance(_distanceMeters)} • Sudut: ${_targetBearing.round()}°'
                          : 'Mencari sinyal GPS perangkat...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Titik temu: ${listing.locationName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11.5,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 10 : 14),

          // Google Maps Navigation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openGoogleMapsRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: const Color(0xFF0F291B),
                padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.near_me_rounded, size: 18),
              label: const Text(
                'Buka Rute di Google Maps',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card shown when opened standalone from Sensors Screen
  Widget _buildGeneralSensorInfoCard(bool isCompact) {
    final accuracy = _reading?.accuracy ?? CompassAccuracy.high;
    final accuracyText = accuracy == CompassAccuracy.high
        ? 'Akurasi Tinggi'
        : (accuracy == CompassAccuracy.medium ? 'Akurasi Sedang' : 'Perlu Kalibrasi');
    final accuracyColor = accuracy == CompassAccuracy.high
        ? const Color(0xFF22C55E)
        : (accuracy == CompassAccuracy.medium ? const Color(0xFFEAB308) : const Color(0xFFEF4444));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF232B25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sensor Magnetik & Orientasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Calibration status badge
              InkWell(
                onTap: _showCalibrationGuide,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accuracyColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accuracyColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        accuracyText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: accuracyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Coordinate / Location info
          Row(
            children: [
              const Icon(Icons.my_location_rounded, size: 14, color: AppColors.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _currentPosition != null
                      ? 'GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}°, ${_currentPosition!.longitude.toStringAsFixed(4)}° • Elevasi: ${_currentPosition!.altitude.round()} m'
                      : (_locationError ?? 'Mendeteksi sinyal GPS perangkat...'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Declination & Sensor Telemetry
          Row(
            children: [
              const Icon(Icons.radar_rounded, size: 14, color: Color(0xFF34D399)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Medan: ${_reading?.fieldStrength.toStringAsFixed(1) ?? "45.0"} µT • Deklinasi: ${(_reading?.declination ?? 0) >= 0 ? "+" : ""}${_reading?.declination.toStringAsFixed(1) ?? "0.0"}°',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_outlined, size: 14, color: Color(0xFF86EFAC)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tips: Pegang ponsel secara datar (level) agar akurasi maksimal. Gerakkan membentuk angka 8 jika sensor memerlukan kalibrasi.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Custom Painters ────────────────────────────────────────────────────────

/// Anti-aliased, pixel-perfect iOS/Android Compass Dial Painter
class _SmoothCompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final majorTickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final mediumTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final minorTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final northPaint = Paint()
      ..color = const Color(0xFFEF4444) // Vibrant Red North
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (int deg = 0; deg < 360; deg += 2) {
      final rad = deg * math.pi / 180.0;
      final isNorth = deg == 0;
      final isCardinal = deg == 90 || deg == 180 || deg == 270;
      final isMajor = deg % 30 == 0 && !isCardinal && !isNorth;
      final isMedium = deg % 10 == 0 && !isMajor && !isCardinal && !isNorth;

      double tickLength;
      Paint paintToUse;

      if (isNorth) {
        tickLength = 16.0;
        paintToUse = northPaint;
      } else if (isCardinal) {
        tickLength = 14.0;
        paintToUse = majorTickPaint;
      } else if (isMajor) {
        tickLength = 10.0;
        paintToUse = mediumTickPaint;
      } else if (isMedium) {
        tickLength = 7.0;
        paintToUse = mediumTickPaint;
      } else {
        tickLength = 4.0;
        paintToUse = minorTickPaint;
      }

      final p1 = Offset(
        center.dx + (radius - 12) * math.sin(rad),
        center.dy - (radius - 12) * math.cos(rad),
      );
      final p2 = Offset(
        center.dx + (radius - 12 - tickLength) * math.sin(rad),
        center.dy - (radius - 12 - tickLength) * math.cos(rad),
      );

      canvas.drawLine(p1, p2, paintToUse);

      if (isNorth) {
        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'N',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final offset = Offset(
          center.dx + (radius - 46) * math.sin(rad) - (textPainter.width / 2),
          center.dy - (radius - 46) * math.cos(rad) - (textPainter.height / 2),
        );
        textPainter.paint(canvas, offset);
      } else if (isCardinal) {
        final label = deg == 90 ? 'E' : (deg == 180 ? 'S' : 'W');
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final offset = Offset(
          center.dx + (radius - 46) * math.sin(rad) - (textPainter.width / 2),
          center.dy - (radius - 46) * math.cos(rad) - (textPainter.height / 2),
        );
        textPainter.paint(canvas, offset);
      } else if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: deg.toString(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final offset = Offset(
          center.dx + (radius - 40) * math.sin(rad) - (textPainter.width / 2),
          center.dy - (radius - 40) * math.cos(rad) - (textPainter.height / 2),
        );
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dynamic Level Bubble Reticle Painter (Inclinometer / Gimbal Level)
/// Moves based on pitch & roll. Snaps & turns emerald green when phone is held level.
class _LevelBubbleReticlePainter extends CustomPainter {
  final double pitch;
  final double roll;
  final bool isLevel;

  _LevelBubbleReticlePainter({
    required this.pitch,
    required this.roll,
    required this.isLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer reference ring
    final outerRingPaint = Paint()
      ..color = isLevel
          ? const Color(0xFF22C55E).withValues(alpha: 0.45)
          : Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLevel ? 1.5 : 1.0
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, outerRingPaint);

    // Fixed center reference crosshairs
    final refCrossPaint = Paint()
      ..color = isLevel
          ? const Color(0xFF22C55E).withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.drawLine(Offset(center.dx - 14, center.dy), Offset(center.dx - 6, center.dy), refCrossPaint);
    canvas.drawLine(Offset(center.dx + 6, center.dy), Offset(center.dx + 14, center.dy), refCrossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 14), Offset(center.dx, center.dy - 6), refCrossPaint);
    canvas.drawLine(Offset(center.dx, center.dy + 6), Offset(center.dx, center.dy + 14), refCrossPaint);

    // Dynamic bubble displacement based on pitch & roll
    final maxOffset = radius * 0.72;
    final bubbleDx = (-roll.clamp(-25.0, 25.0) / 25.0) * maxOffset;
    final bubbleDy = (pitch.clamp(-25.0, 25.0) / 25.0) * maxOffset;
    final bubblePos = Offset(center.dx + bubbleDx, center.dy + bubbleDy);

    // Dynamic floating bubble ring
    final bubbleRingPaint = Paint()
      ..color = isLevel
          ? const Color(0xFF22C55E)
          : Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLevel ? 2.0 : 1.2
      ..isAntiAlias = true;

    canvas.drawCircle(bubblePos, 13.0, bubbleRingPaint);

    // Center dot inside bubble
    final bubbleDotPaint = Paint()
      ..color = isLevel ? const Color(0xFF22C55E) : Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(bubblePos, isLevel ? 5.0 : 3.5, bubbleDotPaint);

    // Subtle cross inside the bubble
    final innerCrossPaint = Paint()
      ..color = isLevel
          ? const Color(0xFF22C55E).withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.drawLine(Offset(bubblePos.dx - 5, bubblePos.dy), Offset(bubblePos.dx + 5, bubblePos.dy), innerCrossPaint);
    canvas.drawLine(Offset(bubblePos.dx, bubblePos.dy - 5), Offset(bubblePos.dx, bubblePos.dy + 5), innerCrossPaint);
  }

  @override
  bool shouldRepaint(covariant _LevelBubbleReticlePainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.roll != roll ||
        oldDelegate.isLevel != isLevel;
  }
}

/// Vector Painter for Glowing Target Pointer Needle (Points towards listing location)
class _TargetArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const topY = 12.0;

    // Glowing shadow
    final glowPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..isAntiAlias = true;

    final arrowPath = Path()
      ..moveTo(center.dx, topY)
      ..lineTo(center.dx - 16, topY + 34)
      ..lineTo(center.dx - 7, topY + 28)
      ..lineTo(center.dx - 7, topY + 48)
      ..lineTo(center.dx + 7, topY + 48)
      ..lineTo(center.dx + 7, topY + 28)
      ..lineTo(center.dx + 16, topY + 34)
      ..close();

    canvas.drawPath(arrowPath, glowPaint);

    // Solid Emerald Vector Pointer
    final arrowPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(arrowPath, arrowPaint);

    // White center highlight line for depth
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawLine(Offset(center.dx, topY + 6), Offset(center.dx, topY + 38), highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
