import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/listing_provider.dart';
import '../../services/location_service.dart';

enum GpsMapMode {
  userGps,
  pickupLocation,
}

class GpsFullMapScreen extends StatefulWidget {
  final GpsMapMode mode;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? locationTitle;
  final String? locationSubtitle;

  const GpsFullMapScreen({
    super.key,
    this.mode = GpsMapMode.userGps,
    this.initialLatitude,
    this.initialLongitude,
    this.locationTitle,
    this.locationSubtitle,
  });

  @override
  State<GpsFullMapScreen> createState() => _GpsFullMapScreenState();
}

class _GpsFullMapScreenState extends State<GpsFullMapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  LatLng _currentCenter = const LatLng(-7.797068, 110.370529);
  double _currentZoom = 15.5;

  bool _isLocating = false;
  String _statusText = 'Mendeteksi sinyal GPS...';
  String? _errorMessage;
  double? _accuracyMeters;

  // Tile layer style (0: Google Maps Standard, 1: Google Maps Satellite/Hybrid, 2: Google Maps Terrain, 3: OpenStreetMap)
  int _tileStyleIndex = 0;

  final List<Map<String, String>> _tileProviders = [
    {
      'name': 'Google Maps Standar',
      'url': 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
    },
    {
      'name': 'Google Maps Satelit / Hybrid',
      'url': 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
    },
    {
      'name': 'Google Maps Medan (Terrain)',
      'url': 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}',
    },
    {
      'name': 'OpenStreetMap',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for GPS marker
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    // Initial coordinates
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentCenter = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }

    if (widget.mode == GpsMapMode.userGps) {
      _fetchCurrentGpsLocation();
    } else {
      _statusText = widget.locationTitle ?? 'Titik Pengambilan Barang';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentGpsLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
      _statusText = 'Menghubungkan ke satelit GPS...';
    });

    try {
      final pos = await _locationService.getCurrentLocation();
      if (!mounted) return;

      if (pos != null) {
        final newCenter = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentCenter = newCenter;
          _isLocating = false;
          _accuracyMeters = pos.accuracy;
          _statusText = 'GPS Terhubung (Akurasi ±${pos.accuracy.toStringAsFixed(0)}m)';
        });
        _mapController.move(newCenter, 16.0);
      } else {
        // Fallback to last known position
        final fallback = await _locationService.getLastKnownOrCoordinates();
        if (!mounted) return;
        final newCenter = LatLng(fallback['latitude']!, fallback['longitude']!);
        setState(() {
          _currentCenter = newCenter;
          _isLocating = false;
          _errorMessage = 'Izin GPS belum aktif. Menggunakan lokasi default.';
          _statusText = 'Lokasi Default';
        });
        _mapController.move(newCenter, 15.0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _errorMessage = 'Gagal mendeteksi GPS: $e';
        _statusText = 'Gagal terhubung GPS';
      });
    }
  }

  void _zoomIn() {
    final newZoom = (_mapController.camera.zoom + 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() {
      _currentZoom = newZoom;
    });
  }

  void _zoomOut() {
    final newZoom = (_mapController.camera.zoom - 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, newZoom);
    setState(() {
      _currentZoom = newZoom;
    });
  }

  void _centerToPoint() {
    _mapController.move(_currentCenter, 16.0);
  }

  void _applyLocationToProvider() {
    final provider = Provider.of<ListingProvider>(context, listen: false);
    final lat = _currentCenter.latitude;
    final lng = _currentCenter.longitude;

    // Apply coordinates to listing provider
    provider.setUserCity(
      'Lokasi GPS Terkini (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})',
      lat,
      lng,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lokasi GPS berhasil diterapkan: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isUserMode = widget.mode == GpsMapMode.userGps;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // The Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  _currentZoom = camera.zoom;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tileProviders[_tileStyleIndex]['url']!,
                userAgentPackageName: 'com.jadiguna.jadiguna',
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxZoom: 20,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentCenter,
                    width: isUserMode ? 90 : 160,
                    height: isUserMode ? 90 : 90,
                    alignment: isUserMode ? Alignment.center : Alignment.topCenter,
                    child: isUserMode ? _buildUserGpsMarker() : _buildPickupMarker(),
                  ),
                ],
              ),
            ],
          ),

          // Top Google Maps Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: _buildTopSearchBar(context, isUserMode),
          ),

          // Right Floating Map Action Controls (Zoom in, Zoom out, Layer, Center)
          Positioned(
            right: 14,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Layer switch button
                _buildMapControlBtn(
                  icon: Icons.layers_rounded,
                  tooltip: 'Ganti Tampilan Peta',
                  onTap: () {
                    setState(() {
                      _tileStyleIndex = (_tileStyleIndex + 1) % _tileProviders.length;
                    });
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tampilan Peta: ${_tileProviders[_tileStyleIndex]['name']}'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Zoom In
                _buildMapControlBtn(
                  icon: Icons.add_rounded,
                  tooltip: 'Perbesar',
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 4),

                // Zoom Out
                _buildMapControlBtn(
                  icon: Icons.remove_rounded,
                  tooltip: 'Perkecil',
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 8),

                // Center back to marker
                _buildMapControlBtn(
                  icon: isUserMode ? Icons.my_location_rounded : Icons.location_searching_rounded,
                  tooltip: isUserMode ? 'Pusatkan ke GPS Saya' : 'Pusatkan ke Titik Lokasi',
                  iconColor: AppColors.primary,
                  onTap: () {
                    if (isUserMode) {
                      _fetchCurrentGpsLocation();
                    } else {
                      _centerToPoint();
                    }
                  },
                ),
              ],
            ),
          ),

          // Bottom Floating Detail Card
          Positioned(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(context).padding.bottom + 14,
            child: _buildBottomCard(context, isUserMode),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchBar(BuildContext context, bool isUserMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _errorMessage != null
                            ? AppColors.warning
                            : (_isLocating ? Colors.orange : AppColors.success),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isUserMode ? 'Google Maps GPS Terkini' : (widget.locationTitle ?? 'Lokasi Pengambilan COD'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currentCenter.latitude.toStringAsFixed(5)}, ${_currentCenter.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (isUserMode)
            IconButton(
              icon: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.refresh_rounded, size: 22, color: AppColors.primary),
              tooltip: 'Perbarui Koordinat GPS',
              onPressed: _isLocating ? null : _fetchCurrentGpsLocation,
              splashRadius: 22,
            ),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = AppColors.textPrimary,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildUserGpsMarker() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing wave
            Container(
              width: 70 * _pulseAnimation.value,
              height: 70 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: (0.35 / _pulseAnimation.value).clamp(0.0, 1.0)),
              ),
            ),
            // White outline disc
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            // Inner Google Maps blue core dot
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPickupMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Titik Pengambilan (COD)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Icon(
          Icons.location_on_rounded,
          color: AppColors.error,
          size: 40,
          shadows: [
            Shadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomCard(BuildContext context, bool isUserMode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUserMode ? AppColors.primarySurface : const Color(0xFFFFECEB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUserMode ? Icons.my_location_rounded : Icons.location_on_rounded,
                  color: isUserMode ? AppColors.primary : AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUserMode ? 'Satelit GPS Perangkat Terkini' : (widget.locationTitle ?? 'Lokasi COD'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _errorMessage != null ? AppColors.error : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_accuracyMeters != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Akurasi: ±${_accuracyMeters!.toStringAsFixed(1)} m • Koordinat Live',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isUserMode)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLocating ? null : _applyLocationToProvider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'Gunakan Lokasi Ini',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text(
                  'Kembali ke Detail Barang',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
