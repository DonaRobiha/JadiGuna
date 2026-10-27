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

  double _deviceHeading = 0.0;
  double _unwrappedHeading = 0.0;
  double _lastRawHeading = 0.0;

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

      if (position != null && _hasValidDestination) {
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
    } catch (e) {
      _locationError = 'Tidak dapat mendeteksi lokasi: $e';
    }

    _compassService.startListening(
      onUpdate: (heading) {
        if (!mounted) return;
        setState(() {
          // Continuous unwrap to guarantee butter-smooth rotation without 360-to-0 jumping
          double diff = heading - _lastRawHeading;
          if (diff > 180) diff -= 360;
          if (diff < -180) diff += 360;

          _unwrappedHeading += diff;
          _lastRawHeading = heading;
          _deviceHeading = heading;
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
                  : 'Sensor Magnetometer Perangkat',
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
                    math.min(constraints.maxWidth * 0.72, constraints.maxHeight * 0.40),
                  ).clamp(160.0, 280.0);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Column(
                      children: [
                        // 1. Heading Degree & Cardinal Direction Badge
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_deviceHeading.round()}°',
                              style: TextStyle(
                                fontSize: isCompact ? 44 : 56,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: -2,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                                      color: _compassService.hasGyroscope
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFEAB308),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    LocationHelper.getCardinalDirection(_deviceHeading).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Direction instruction pill if navigating to destination
                        if (directionInstruction != null) ...[
                          const SizedBox(height: 10),
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

                        SizedBox(height: isCompact ? 12 : 18),

                        // 2. Ultra-Smooth Vector Compass Dial
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

                                    // Vector Center Crosshair & Gimbal Circle
                                    IgnorePointer(
                                      child: CustomPaint(
                                        size: const Size(140, 140),
                                        painter: _CenterCrosshairPainter(),
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

                        SizedBox(height: isCompact ? 14 : 20),

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
                  'Status Sensor Magnetik',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_compassService.hasGyroscope ? const Color(0xFF22C55E) : const Color(0xFFEAB308))
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _compassService.hasGyroscope ? 'Aktif' : 'Simulasi',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _compassService.hasGyroscope ? const Color(0xFF86EFAC) : const Color(0xFFFDE047),
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
                      ? 'Koordinat: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_outlined, size: 14, color: Color(0xFF86EFAC)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tips: Gerakkan ponsel membentuk pola angka 8 jika kompas memerlukan kalibrasi. Buka dari Detail Barang untuk navigasi titik temu.',
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

/// Anti-aliased, pixel-perfect iOS Compass Dial Painter
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

/// Vector Painter for Center Gimbal Crosshairs
class _CenterCrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, circlePaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, 5.0, dotPaint);

    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.drawLine(Offset(center.dx - 12, center.dy), Offset(center.dx - 6, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx + 6, center.dy), Offset(center.dx + 12, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 12), Offset(center.dx, center.dy - 6), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy + 6), Offset(center.dx, center.dy + 12), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
