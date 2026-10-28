import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/listing_model.dart';
import '../listing/add_edit_listing_screen.dart';

/// Model objek referensi kalibrasi skala optik
class ReferenceObject {
  final String id;
  final String name;
  final String description;
  final double realWidthCm;
  final double realHeightCm;
  final IconData icon;

  const ReferenceObject({
    required this.id,
    required this.name,
    required this.description,
    required this.realWidthCm,
    required this.realHeightCm,
    required this.icon,
  });
}

/// Mode pengukuran kamera
enum MeasurementToolMode {
  box, // Kotak dimensi P x T (Bounding box)
  ruler, // Meteran penggaris titik A ke titik B
}

class ItemMeasurementScreen extends StatefulWidget {
  final ListingModel? listing;
  final bool isSelectingForListing;

  const ItemMeasurementScreen({
    super.key,
    this.listing,
    this.isSelectingForListing = false,
  });

  @override
  State<ItemMeasurementScreen> createState() => _ItemMeasurementScreenState();
}

class _ItemMeasurementScreenState extends State<ItemMeasurementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  // Mode 1: Camera photo measurement
  File? _capturedImage;
  Uint8List? _capturedImageBytes;
  String? _capturedImagePath;
  String? _sampleImageUrl;
  bool _isCameraLoading = false;
  MeasurementToolMode _toolMode = MeasurementToolMode.box;

  // Objek referensi populer di Indonesia
  static const List<ReferenceObject> _referenceObjects = [
    ReferenceObject(
      id: 'id_card',
      name: 'Kartu KTP / ATM',
      description: 'Standar ISO/IEC 7810 (8.56 × 5.40 cm)',
      realWidthCm: 8.56,
      realHeightCm: 5.40,
      icon: Icons.credit_card_rounded,
    ),
    ReferenceObject(
      id: 'banknote',
      name: 'Uang Rp 50k / 100k',
      description: 'Uang kertas rupiah emisi baru (15.1 × 6.5 cm)',
      realWidthCm: 15.1,
      realHeightCm: 6.5,
      icon: Icons.money_rounded,
    ),
    ReferenceObject(
      id: 'a4_paper',
      name: 'Kertas HVS A4',
      description: 'Kertas dokumen resmi (29.7 × 21.0 cm)',
      realWidthCm: 21.0,
      realHeightCm: 29.7,
      icon: Icons.description_outlined,
    ),
    ReferenceObject(
      id: 'floor_tile_40',
      name: 'Ubin Keramik 40x40',
      description: 'Ubin keramik lantai rumah (40.0 × 40.0 cm)',
      realWidthCm: 40.0,
      realHeightCm: 40.0,
      icon: Icons.grid_view_rounded,
    ),
    ReferenceObject(
      id: 'floor_tile_30',
      name: 'Ubin Keramik 30x30',
      description: 'Ubin keramik standar (30.0 × 30.0 cm)',
      realWidthCm: 30.0,
      realHeightCm: 30.0,
      icon: Icons.grid_on_rounded,
    ),
    ReferenceObject(
      id: 'water_bottle',
      name: 'Botol Air 600ml',
      description: 'Tinggi botol mineral umum (23.5 × 6.5 cm)',
      realWidthCm: 6.5,
      realHeightCm: 23.5,
      icon: Icons.local_drink_rounded,
    ),
    ReferenceObject(
      id: 'lighter',
      name: 'Korek Api Gas (Tokai)',
      description: 'Korek api gas saku (8.0 × 2.5 cm)',
      realWidthCm: 2.5,
      realHeightCm: 8.0,
      icon: Icons.flash_on_rounded,
    ),
  ];

  late ReferenceObject _selectedReference;
  double _customRefWidthCm = 10.0;
  bool _isCustomReference = false;

  // 1. KOTAK REFERENSI PATOKAN (Normalized coordinates 0.0 - 1.0)
  double _refLeft = 0.08;
  double _refTop = 0.65;
  double _refWidth = 0.22;
  double _refHeight = 0.16;

  // 2. KOTAK PENGUKURAN BARANG (Normalized coordinates 0.0 - 1.0)
  double _itemLeft = 0.25;
  double _itemTop = 0.15;
  double _itemWidth = 0.65;
  double _itemHeight = 0.50;

  // 3. MODE METERAN GARIS (Ruler mode: Titik A & Titik B)
  Offset _rulerPointA = const Offset(0.25, 0.40);
  Offset _rulerPointB = const Offset(0.75, 0.40);

  // Rasio tebal / kedalaman barang (untuk estimasi volume 3D)
  double _depthRatio = 0.5;

  // Mode 2: Kalkulator Manual
  final TextEditingController _lengthController = TextEditingController(text: '100');
  final TextEditingController _widthController = TextEditingController(text: '50');
  final TextEditingController _heightController = TextEditingController(text: '75');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedReference = _referenceObjects[0];

    if (widget.listing != null) {
      _applyListingDefaults(widget.listing!);
    }
  }

  void _applyListingDefaults(ListingModel listing) {
    final titleLower = listing.title.toLowerCase();
    final descLower = listing.description.toLowerCase();

    if (titleLower.contains('kursi') || descLower.contains('kursi')) {
      _lengthController.text = '55';
      _widthController.text = '55';
      _heightController.text = '95';
    } else if (titleLower.contains('lemari') || descLower.contains('lemari')) {
      _lengthController.text = '80';
      _widthController.text = '50';
      _heightController.text = '180';
    } else if (titleLower.contains('rak') || descLower.contains('rak')) {
      _lengthController.text = '60';
      _widthController.text = '30';
      _heightController.text = '120';
    } else if (titleLower.contains('sofa') || descLower.contains('sofa')) {
      _lengthController.text = '140';
      _widthController.text = '75';
      _heightController.text = '80';
    } else {
      _lengthController.text = '100';
      _widthController.text = '50';
      _heightController.text = '75';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ─── Optical Calibration & Measurement Math ────────────────────────────────

  double _calculatePixelsPerCm(double canvasWidth, double canvasHeight) {
    final refPixelW = (_refWidth * canvasWidth).abs();
    final refPixelH = (_refHeight * canvasHeight).abs();

    final realW = _isCustomReference ? _customRefWidthCm : _selectedReference.realWidthCm;
    final realH = _isCustomReference ? _customRefWidthCm : _selectedReference.realHeightCm;

    final scaleX = refPixelW / math.max(0.1, realW);
    final scaleY = refPixelH / math.max(0.1, realH);

    final avgScale = (scaleX + scaleY) / 2.0;
    return avgScale > 0.05 ? avgScale : 1.0;
  }

  Map<String, double> _calculateItemDimensions(double canvasWidth, double canvasHeight) {
    final pxPerCm = _calculatePixelsPerCm(canvasWidth, canvasHeight);

    if (_toolMode == MeasurementToolMode.box) {
      final itemPixelW = (_itemWidth * canvasWidth).abs();
      final itemPixelH = (_itemHeight * canvasHeight).abs();

      final lengthCm = itemPixelW / pxPerCm;
      final heightCm = itemPixelH / pxPerCm;
      final widthCm = lengthCm * _depthRatio;

      return {
        'panjang': lengthCm.clamp(1.0, 500.0),
        'lebar': widthCm.clamp(1.0, 400.0),
        'tinggi': heightCm.clamp(1.0, 400.0),
        'jarakGaris': 0.0,
      };
    } else {
      final dx = (_rulerPointB.dx - _rulerPointA.dx) * canvasWidth;
      final dy = (_rulerPointB.dy - _rulerPointA.dy) * canvasHeight;
      final linePixels = math.sqrt(dx * dx + dy * dy);
      final distanceCm = linePixels / pxPerCm;

      return {
        'panjang': distanceCm.clamp(1.0, 500.0),
        'lebar': (distanceCm * _depthRatio).clamp(1.0, 400.0),
        'tinggi': (distanceCm * 0.5).clamp(1.0, 400.0),
        'jarakGaris': distanceCm.clamp(1.0, 500.0),
      };
    }
  }

  String _formatDim(double cm) {
    if (cm >= 100) {
      return '${(cm / 100).toStringAsFixed(2)} m (${cm.round()} cm)';
    }
    return '${cm.toStringAsFixed(1)} cm';
  }

  // ─── Camera Flow ──────────────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Izin Kamera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'jadiGuna memerlukan akses kamera untuk mengambil foto barang beserta objek patokan (seperti KTP, uang kertas, atau ubin).\n\nFoto diproses secara lokal di perangkat Anda untuk menghitung ukuran barang secara akurat.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buka Kamera'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    setState(() => _isCameraLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
          _capturedImagePath = photo.path;
          if (!kIsWeb) {
            _capturedImage = File(photo.path);
          } else {
            _capturedImage = null;
          }
          _sampleImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera tidak tersedia ($e). Menggunakan contoh foto barang untuk simulasi kalibrasi.'),
            backgroundColor: AppColors.warning,
          ),
        );
        _useSampleFurnitureImage();
      }
    } finally {
      if (mounted) {
        setState(() => _isCameraLoading = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isCameraLoading = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
          _capturedImagePath = image.path;
          if (!kIsWeb) {
            _capturedImage = File(image.path);
          } else {
            _capturedImage = null;
          }
          _sampleImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCameraLoading = false);
      }
    }
  }

  void _useSampleFurnitureImage() {
    setState(() {
      _capturedImage = null;
      _capturedImageBytes = null;
      _capturedImagePath = null;
      if (widget.listing != null && widget.listing!.images.isNotEmpty) {
        _sampleImageUrl = widget.listing!.images.first;
      } else {
        _sampleImageUrl = 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=800';
      }
    });
  }

  void _resetMeasurement() {
    setState(() {
      _capturedImage = null;
      _capturedImageBytes = null;
      _capturedImagePath = null;
      _sampleImageUrl = null;
      _refLeft = 0.08;
      _refTop = 0.65;
      _refWidth = 0.22;
      _refHeight = 0.16;
      _itemLeft = 0.25;
      _itemTop = 0.15;
      _itemWidth = 0.65;
      _itemHeight = 0.50;
      _rulerPointA = const Offset(0.25, 0.40);
      _rulerPointB = const Offset(0.75, 0.40);
    });
  }

  void _showCustomReferenceDialog() {
    final controller = TextEditingController(text: _customRefWidthCm.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Objek Patokan Kustom', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan ukuran panjang objek patokan yang ada di foto Anda (misal penggaris 30 cm atau buku 20 cm):',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Panjang Patokan (cm)',
                suffixText: 'cm',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 10.0;
              setState(() {
                _customRefWidthCm = val.clamp(1.0, 200.0);
                _isCustomReference = true;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  void _proceedToCreateListing(double p, double l, double t) {
    final lengthVal = p.roundToDouble();
    final widthVal = l.roundToDouble();
    final heightVal = t.roundToDouble();

    final chosenImagePath = _capturedImagePath ?? _capturedImage?.path;
    if (widget.isSelectingForListing) {
      Navigator.pop(context, {
        'length': lengthVal,
        'width': widthVal,
        'height': heightVal,
        'imagePath': chosenImagePath,
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditListingScreen(
          initialLength: lengthVal,
          initialWidth: widthVal,
          initialHeight: heightVal,
          initialImagePath: chosenImagePath,
          initialTitle: widget.listing?.title,
          initialCategory: widget.listing?.categoryName,
        ),
      ),
    );
  }

  void _copyDimensionsToClipboard(double p, double l, double t, String method) {
    final text = 'Dimensi Barang (Hasil Ukur jadiGuna - $method):\n'
        '• Panjang: ${p.toStringAsFixed(1)} cm\n'
        '• Lebar: ${l.toStringAsFixed(1)} cm\n'
        '• Tinggi: ${t.toStringAsFixed(1)} cm\n'
        'Estimasi Volume: ${((p * l * t) / 1000).toStringAsFixed(1)} Liter';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Ukuran berhasil disalin ke papan klip!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<String, dynamic> _getVehicleFit(double p, double l, double t) {
    final dims = [p, l, t]..sort();
    final dMin = dims[0];
    final dMid = dims[1];
    final dMax = dims[2];

    if (dMax <= 70 && dMid <= 45 && dMin <= 35) {
      return {
        'vehicle': 'Motor Roda Dua (Dek Depan / Boncengan)',
        'color': AppColors.statusAvailable,
        'icon': Icons.two_wheeler_rounded,
        'note': 'Mudah diangkut dengan motor roda dua menggunakan tali pengikat.',
      };
    } else if (dMax <= 110 && dMid <= 70 && dMin <= 60) {
      return {
        'vehicle': 'Mobil City Car / Hatchback',
        'color': const Color(0xFF2E7D32),
        'icon': Icons.directions_car_rounded,
        'note': 'Muat di bagasi atau jok belakang city car dengan melipat kursi.',
      };
    } else if (dMax <= 160 && dMid <= 90 && dMin <= 85) {
      return {
        'vehicle': 'Mobil MPV / Minivan / SUV',
        'color': AppColors.secondary,
        'icon': Icons.airport_shuttle_rounded,
        'note': 'Disarankan menggunakan mobil MPV/SUV dengan melipat kursi baris belakang.',
      };
    } else {
      return {
        'vehicle': 'Mobil Pickup / Truk Engkel',
        'color': AppColors.terracotta,
        'icon': Icons.local_shipping_rounded,
        'note': 'Ukuran besar! Sangat disarankan menggunakan mobil bak terbuka / jasa angkut barang.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengukur Ukuran Barang',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.listing != null
                  ? widget.listing!.title
                  : (widget.isSelectingForListing
                      ? 'Pilih Ukuran untuk Formulir Pasang Iklan'
                      : 'Estimasi Dimensi Berbantuan Kamera & Patokan'),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.camera_enhance_rounded, size: 18), text: 'Bantuan Kamera'),
            Tab(icon: Icon(Icons.straighten_rounded, size: 18), text: 'Input Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCameraAssistedTab(),
          _buildManualCalculatorTab(),
        ],
      ),
      bottomNavigationBar: widget.listing != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Kembali ke Detail Barang', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ─── TAB 1: Camera-Assisted Precision Measurement ──────────────────────────

  Widget _buildCameraAssistedTab() {
    final hasImage = _capturedImageBytes != null || _capturedImage != null || _sampleImageUrl != null;

    if (!hasImage) {
      return _buildCameraWelcomeScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const canvasHeight = 360.0;
        final canvasWidth = constraints.maxWidth;

        final dims = _calculateItemDimensions(canvasWidth, canvasHeight);
        final p = dims['panjang']!;
        final l = dims['lebar']!;
        final t = dims['tinggi']!;
        final jarakGaris = dims['jarakGaris']!;
        final vehicleFit = _getVehicleFit(p, l, t);
        final pxPerCm = _calculatePixelsPerCm(canvasWidth, canvasHeight);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tool Mode Selector & Calibration Notice (Overflow-Proof)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Mode:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SegmentedButton<MeasurementToolMode>(
                                style: SegmentedButton.styleFrom(
                                  selectedBackgroundColor: AppColors.primarySurface,
                                  selectedForegroundColor: AppColors.primaryDark,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                segments: const [
                                  ButtonSegment(
                                    value: MeasurementToolMode.box,
                                    label: Text('Kotak (P×T)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    icon: Icon(Icons.crop_square_rounded, size: 14),
                                  ),
                                  ButtonSegment(
                                    value: MeasurementToolMode.ruler,
                                    label: Text('Garis A-B', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    icon: Icon(Icons.linear_scale_rounded, size: 14),
                                  ),
                                ],
                                selected: {_toolMode},
                                onSelectionChanged: (set) {
                                  setState(() => _toolMode = set.first);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Legend pills wrapped safely to prevent pixel overflow on narrow screens
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Kuning = Patokan',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                        const Text('•', style: TextStyle(color: Colors.black26)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Hijau = Barang Target',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Interactive Measuring Canvas
              Container(
                height: canvasHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo background
                      if (_capturedImageBytes != null)
                        Image.memory(_capturedImageBytes!, fit: BoxFit.cover)
                      else if (_capturedImage != null && !kIsWeb)
                        Image.file(_capturedImage!, fit: BoxFit.cover)
                      else if (_sampleImageUrl != null)
                        Image.network(_sampleImageUrl!, fit: BoxFit.cover),

                      // Reference calibration badge & Scale factor badge (Unified Overflow-Proof Bar)
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded, color: Color(0xFFFBBF24), size: 13),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        _isCustomReference
                                            ? 'Patokan: ${_customRefWidthCm.toStringAsFixed(1)} cm'
                                            : '${_selectedReference.name} (${_selectedReference.realWidthCm} cm)',
                                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                '${pxPerCm.toStringAsFixed(1)} px/cm',
                                style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 10.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── A. KOTAK PATOKAN REFERENSI (Kuning Emas) ──────────
                      _buildDraggableReferenceBox(canvasWidth, canvasHeight),

                      // ── B. KOTAK PENGUKURAN BARANG (Hijau Zamrud) ───────────
                      if (_toolMode == MeasurementToolMode.box)
                        _buildDraggableItemBox(canvasWidth, canvasHeight, p, t)
                      else
                        _buildDraggableRuler(canvasWidth, canvasHeight, jarakGaris),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Reference Object Quick Selector (Overflow-Proof)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Objek Patokan di Foto:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _showCustomReferenceDialog,
                    icon: const Icon(Icons.edit_rounded, size: 13),
                    label: const Text('Kustom', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ..._referenceObjects.map((ref) {
                      final isSelected = !_isCustomReference && ref.id == _selectedReference.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(
                            ref.icon,
                            size: 16,
                            color: isSelected ? Colors.white : const Color(0xFFB45309),
                          ),
                          label: Text(ref.name),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD97706),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFD97706) : AppColors.border,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedReference = ref;
                                _isCustomReference = false;
                              });
                            }
                          },
                        ),
                      );
                    }),
                    if (_isCustomReference)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.straighten, size: 16, color: Colors.white),
                          label: Text('Kustom (${_customRefWidthCm.toStringAsFixed(1)} cm)'),
                          selected: true,
                          selectedColor: AppColors.primary,
                          onSelected: (_) => _showCustomReferenceDialog(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Live Dimension Results Card (Overflow-Proof)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Hasil Ukuran Terkalibrasi',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.freeBadgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.freeBadge),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 11, color: AppColors.primaryDark),
                              SizedBox(width: 4),
                              Text(
                                'Akurasi Optik',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_toolMode == MeasurementToolMode.box) ...[
                      Row(
                        children: [
                          _buildResultBox('PANJANG', _formatDim(p), Icons.swap_horiz_rounded),
                          const SizedBox(width: 6),
                          _buildResultBox('LEBAR', _formatDim(l), Icons.layers_outlined),
                          const SizedBox(width: 6),
                          _buildResultBox('TINGGI', _formatDim(t), Icons.swap_vert_rounded),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Depth adjustment slider (Lebar / Tebal) - Formatted as neat Column to prevent overflow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Atur Tebal / Kedalaman:',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(_depthRatio * 100).round()}% dari Panjang',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            ),
                            child: Slider(
                              value: _depthRatio,
                              min: 0.2,
                              max: 1.0,
                              divisions: 8,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _depthRatio = val),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Estimasi Volume: ${((p * l * t) / 1000).toStringAsFixed(1)} Liter (${((p * l * t) / 1000000).toStringAsFixed(2)} m³)',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Mode Meteran Titik A - B
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.straighten_rounded, color: AppColors.primaryDark, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'JARAK DARI TITIK A KE B',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                  ),
                                  Text(
                                    _formatDim(jarakGaris),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Vehicle Fit Recommendation Card
              _buildVehicleFitCard(vehicleFit),
              const SizedBox(height: 16),

              // 6. Action Buttons: Ukur Ulang & Salin (Compact & Overflow-Proof)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terracotta,
                        side: const BorderSide(color: AppColors.terracotta),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                      onPressed: _resetMeasurement,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Foto Ulang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        elevation: 0,
                      ),
                      onPressed: () => _copyDimensionsToClipboard(p, l, t, 'Bantuan Kamera & Objek Patokan'),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Salin Ukuran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tombol Utama: Pasang Iklan dengan Ukuran Ini / Terapkan ke Formulir
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27382B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () => _proceedToCreateListing(p, l, t),
                  icon: Icon(
                    widget.isSelectingForListing ? Icons.check_circle_rounded : Icons.post_add_rounded,
                    size: 20,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.isSelectingForListing
                          ? 'Terapkan Ukuran ke Formulir Iklan'
                          : 'Pasang Iklan dengan Ukuran Ini',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ─── A. Draggable Reference Box (Kotak Patokan Kuning) ─────────────────────

  Widget _buildDraggableReferenceBox(double cw, double ch) {
    final pixelLeft = (_refLeft * cw).clamp(0.0, cw - 40);
    final pixelTop = (_refTop * ch).clamp(0.0, ch - 40);
    final pixelWidth = (_refWidth * cw).clamp(35.0, cw - pixelLeft);
    final pixelHeight = (_refHeight * ch).clamp(35.0, ch - pixelTop);

    return Positioned(
      left: pixelLeft,
      top: pixelTop,
      width: pixelWidth,
      height: pixelHeight,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _refLeft = (_refLeft + details.delta.dx / cw).clamp(0.0, 1.0 - _refWidth);
            _refTop = (_refTop + details.delta.dy / ch).clamp(0.0, 1.0 - _refHeight);
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFF59E0B), width: 2.2),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
                  ),
                  child: const Text(
                    'PATOKAN',
                    style: TextStyle(color: Colors.black87, fontSize: 8.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  _selectedReference.icon,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _refWidth = (_refWidth + details.delta.dx / cw).clamp(0.08, 1.0 - _refLeft);
                      _refHeight = (_refHeight + details.delta.dy / ch).clamp(0.06, 1.0 - _refTop);
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: const Icon(Icons.aspect_ratio_rounded, color: Colors.black87, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── B. Draggable Item Box (Kotak Barang Hijau Zamrud) ──────────────────────

  Widget _buildDraggableItemBox(double cw, double ch, double p, double t) {
    final pixelLeft = (_itemLeft * cw).clamp(0.0, cw - 50);
    final pixelTop = (_itemTop * ch).clamp(0.0, ch - 50);
    final pixelWidth = (_itemWidth * cw).clamp(50.0, cw - pixelLeft);
    final pixelHeight = (_itemHeight * ch).clamp(50.0, ch - pixelTop);

    return Positioned(
      left: pixelLeft,
      top: pixelTop,
      width: pixelWidth,
      height: pixelHeight,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _itemLeft = (_itemLeft + details.delta.dx / cw).clamp(0.0, 1.0 - _itemWidth);
            _itemTop = (_itemTop + details.delta.dy / ch).clamp(0.0, 1.0 - _itemHeight);
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF22C55E), width: 2.5),
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                  ),
                  child: Text(
                    'P: ${p.round()} cm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(6)),
                  ),
                  child: Text(
                    'T\n${t.round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.open_with_rounded, color: Colors.white70, size: 16),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _itemWidth = (_itemWidth + details.delta.dx / cw).clamp(0.15, 1.0 - _itemLeft);
                      _itemHeight = (_itemHeight + details.delta.dy / ch).clamp(0.12, 1.0 - _itemTop);
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── C. Draggable Ruler Line (Meteran Garis Titik A - B) ───────────────────

  Widget _buildDraggableRuler(double cw, double ch, double distanceCm) {
    final posA = Offset(_rulerPointA.dx * cw, _rulerPointA.dy * ch);
    final posB = Offset(_rulerPointB.dx * cw, _rulerPointB.dy * ch);

    return Stack(
      children: [
        CustomPaint(
          size: Size(cw, ch),
          painter: _RulerLinePainter(
            pointA: posA,
            pointB: posB,
            label: '${distanceCm.toStringAsFixed(1)} cm',
          ),
        ),
        Positioned(
          left: posA.dx - 18,
          top: posA.dy - 18,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rulerPointA = Offset(
                  (_rulerPointA.dx + details.delta.dx / cw).clamp(0.02, 0.98),
                  (_rulerPointA.dy + details.delta.dy / ch).clamp(0.02, 0.98),
                );
              });
            },
            child: _buildRulerPin('A', const Color(0xFF3B82F6)),
          ),
        ),
        Positioned(
          left: posB.dx - 18,
          top: posB.dy - 18,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rulerPointB = Offset(
                  (_rulerPointB.dx + details.delta.dx / cw).clamp(0.02, 0.98),
                  (_rulerPointB.dy + details.delta.dy / ch).clamp(0.02, 0.98),
                );
              });
            },
            child: _buildRulerPin('B', const Color(0xFF22C55E)),
          ),
        ),
      ],
    );
  }

  Widget _buildRulerPin(String label, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildCameraWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 54,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ukur Barang dengan Kamera',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Arahkan kamera ke barang yang ingin Anda ukur. Tempatkan objek patokan (seperti KTP, uang kertas, atau kertas A4) di dekat barang agar ukuran terhitung akurat.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cara Mengukur Agar Akurat 100%:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                const SizedBox(height: 10),
                _buildInstructionRow('1', 'Posisikan barang dan letakkan kartu KTP / uang kertas / kertas A4 di samping barang.'),
                _buildInstructionRow('2', 'Ambil foto tegak lurus (lurus dari depan atau atas, jangan dari sudut miring tajam).'),
                _buildInstructionRow('3', 'Geser KOTAK KUNING pas di atas objek patokan (KTP / Kertas A4).'),
                _buildInstructionRow('4', 'Geser KOTAK HIJAU melingkupi barang Anda. Ukuran cm akan terhitung secara optik presisi!'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isCameraLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _takePhoto,
                icon: const Icon(Icons.photo_camera_rounded, size: 20),
                label: const Text(
                  'Buka Kamera & Mulai Mengukur',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Pilih Galeri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _useSampleFurnitureImage,
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Simulasi Contoh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── TAB 2: Manual Calculator & Preset Guide ──────────────────────────────

  Widget _buildManualCalculatorTab() {
    final p = double.tryParse(_lengthController.text) ?? 0.0;
    final l = double.tryParse(_widthController.text) ?? 0.0;
    final t = double.tryParse(_heightController.text) ?? 0.0;
    final vehicleFit = _getVehicleFit(p, l, t);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Input Manual & Kalkulator Muatan. Masukkan dimensi barang atau gunakan preset kategori furnitur di bawah ini.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dimensi Barang (Sentimeter):',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInputField('Panjang (cm)', _lengthController)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInputField('Lebar (cm)', _widthController)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInputField('Tinggi (cm)', _heightController)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Estimasi Volume: ${((p * l * t) / 1000).toStringAsFixed(1)} Liter',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _copyDimensionsToClipboard(p, l, t, 'Input Manual'),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Salin Ukuran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Preset Standar Furnitur Populer:',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Meja Belajar', 100, 50, 75),
              _buildPresetChip('Kursi Kantor', 55, 55, 95),
              _buildPresetChip('Lemari 2 Pintu', 80, 50, 180),
              _buildPresetChip('Rak Buku 4 Tingkat', 60, 30, 120),
              _buildPresetChip('Sofa 2 Dudukan', 140, 75, 80),
              _buildPresetChip('Meja Tamu / Kopi', 80, 45, 45),
              _buildPresetChip('Kasur Busa Single', 200, 90, 20),
            ],
          ),
          const SizedBox(height: 18),
          _buildVehicleFitCard(vehicleFit),
          const SizedBox(height: 14),

          // Tombol Utama: Pasang Iklan dengan Ukuran Ini / Terapkan ke Formulir
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27382B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: (p > 0 && l > 0 && t > 0) ? () => _proceedToCreateListing(p, l, t) : null,
              icon: Icon(
                widget.isSelectingForListing ? Icons.check_circle_rounded : Icons.post_add_rounded,
                size: 20,
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.isSelectingForListing
                      ? 'Terapkan Ukuran ke Formulir Iklan'
                      : 'Pasang Iklan dengan Ukuran Ini',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Helper Widgets (Overflow-Proof) ───────────────────────────────────────

  Widget _buildResultBox(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.primary),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleFitCard(Map<String, dynamic> fit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (fit['color'] as Color).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(fit['icon'] as IconData, color: fit['color'] as Color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Rekomendasi Angkut: ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    Expanded(
                      child: Text(
                        fit['vehicle'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: fit['color'] as Color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  fit['note'] as String,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int p, int l, int t) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      label: Text('$label ($p×$l×$t cm)'),
      labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      onPressed: () {
        setState(() {
          _lengthController.text = p.toString();
          _widthController.text = l.toString();
          _heightController.text = t.toString();
        });
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            filled: true,
            fillColor: AppColors.background,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildInstructionRow(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              step,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for Ruler line connecting Point A to Point B
class _RulerLinePainter extends CustomPainter {
  final Offset pointA;
  final Offset pointB;
  final String label;

  _RulerLinePainter({
    required this.pointA,
    required this.pointB,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final glowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawLine(pointA, pointB, glowPaint);
    canvas.drawLine(pointA, pointB, linePaint);

    final midX = (pointA.dx + pointB.dx) / 2.0;
    final midY = (pointA.dy + pointB.dy) / 2.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(midX, midY),
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(8),
    );

    final bgPaint = Paint()..color = const Color(0xFF15803D);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(badgeRect, bgPaint);
    canvas.drawRRect(badgeRect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(midX - textPainter.width / 2.0, midY - textPainter.height / 2.0),
    );
  }

  @override
  bool shouldRepaint(covariant _RulerLinePainter oldDelegate) {
    return oldDelegate.pointA != pointA || oldDelegate.pointB != pointB || oldDelegate.label != label;
  }
}
