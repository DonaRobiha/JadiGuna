import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../services/ai_service.dart';
import '../sensors/item_measurement_screen.dart';

class AddEditListingScreen extends StatefulWidget {
  final ListingModel? listingToEdit;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialCategory;
  final String? initialCondition;
  final bool? initialIsFree;
  final double? initialLength;
  final double? initialWidth;
  final double? initialHeight;
  final String? initialImagePath;

  const AddEditListingScreen({
    super.key,
    this.listingToEdit,
    this.initialTitle,
    this.initialDescription,
    this.initialCategory,
    this.initialCondition,
    this.initialIsFree,
    this.initialLength,
    this.initialWidth,
    this.initialHeight,
    this.initialImagePath,
  });

  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aiService = AiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  late String _selectedCategory;
  late String _selectedCondition;
  bool _isFree = false;
  bool _isAiGenerating = false;
  bool _isSaving = false;
  bool _allowNego = true;
  bool _hideAddressUntilChat = true;
  bool _measuredWithSensor = false;

  final List<String> _photos = [];
  final Map<String, Uint8List> _photoBytesCache = {};

  @override
  void initState() {
    super.initState();
    final edit = widget.listingToEdit;

    String initLen = '';
    String initWid = '';
    String initHei = '';
    if (widget.initialLength != null && widget.initialLength! > 0) {
      initLen = widget.initialLength!.round().toString();
      _measuredWithSensor = true;
    }
    if (widget.initialWidth != null && widget.initialWidth! > 0) {
      initWid = widget.initialWidth!.round().toString();
    }
    if (widget.initialHeight != null && widget.initialHeight! > 0) {
      initHei = widget.initialHeight!.round().toString();
    }

    if (edit != null && initLen.isEmpty) {
      final match = RegExp(
        r'\[Dimensi:\s*(\d+(?:\.\d+)?)\s*[×x]\s*(\d+(?:\.\d+)?)\s*[×x]\s*(\d+(?:\.\d+)?)\s*cm\]',
        caseSensitive: false,
      ).firstMatch(edit.description);
      if (match != null) {
        initLen = match.group(1) ?? '';
        initWid = match.group(2) ?? '';
        initHei = match.group(3) ?? '';
        _measuredWithSensor = true;
      }
    }

    _lengthController = TextEditingController(text: initLen);
    _widthController = TextEditingController(text: initWid);
    _heightController = TextEditingController(text: initHei);

    _titleController = TextEditingController(
      text: edit?.title ?? widget.initialTitle ?? '',
    );
    _descController = TextEditingController(
      text: edit?.description ??
          widget.initialDescription ??
          (initLen.isNotEmpty ? '[Dimensi: $initLen × $initWid × $initHei cm]' : ''),
    );
    _priceController = TextEditingController(
      text: (edit != null && !edit.isFree)
          ? edit.price.toString()
          : ((edit == null && (widget.initialIsFree ?? false)) ? '' : (edit == null ? '' : '')),
    );
    _locationController = TextEditingController(
      text: edit?.locationName ?? 'Kos Griya Mahasiswa, Pogung Kidul, Kec. Mlati, Kabupaten Sleman, D.I. Yogyakarta',
    );

    _selectedCategory = edit?.categoryName ?? widget.initialCategory ?? 'Perlengkapan Rumah';
    _selectedCondition = edit?.condition ?? widget.initialCondition ?? 'Sangat Baik';
    _isFree = edit?.isFree ?? widget.initialIsFree ?? false;

    if (edit != null && edit.images.isNotEmpty) {
      _photos.addAll(edit.images);
    } else if (widget.initialImagePath != null && widget.initialImagePath!.isNotEmpty) {
      _photos.add(widget.initialImagePath!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _getImageBytes(String path) async {
    if (_photoBytesCache.containsKey(path)) {
      return _photoBytesCache[path];
    }
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final res = await http.get(Uri.parse(path)).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          _photoBytesCache[path] = res.bodyBytes;
          return res.bodyBytes;
        }
      } else if (kIsWeb || path.startsWith('blob:')) {
        final xFile = XFile(path);
        final b = await xFile.readAsBytes();
        _photoBytesCache[path] = b;
        return b;
      } else if (path.startsWith('assets/')) {
        final byteData = await rootBundle.load(path);
        final b = byteData.buffer.asUint8List();
        _photoBytesCache[path] = b;
        return b;
      } else {
        final file = File(path);
        if (await file.exists()) {
          final b = await file.readAsBytes();
          _photoBytesCache[path] = b;
          return b;
        }
        final b = await XFile(path).readAsBytes();
        _photoBytesCache[path] = b;
        return b;
      }
    } catch (e) {
      debugPrint('Gagal membaca bytes foto: $e');
    }
    return null;
  }

  void _showAiApiKeyDialog() async {
    final currentKey = await AiService.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('API Key Google Gemini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda untuk mengaktifkan AI Vision Multimodal otomatis yang mengenali foto barang secara akurat.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                labelText: 'Gemini API Key',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Catatan: Jika dikosongkan, sistem tetap berjalan menggunakan analisis foto pintar berbasis heuristik lokal.',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await AiService.saveApiKey(controller.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Kunci API Gemini berhasil disimpan!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAiHelp() async {
    final title = _titleController.text.trim();
    final hasPhoto = _photos.isNotEmpty;

    if (title.isEmpty && !hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah foto barang atau ketik judul barang terlebih dahulu agar AI dapat memahami konteks barang Anda.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAiGenerating = true);
    try {
      Uint8List? imageBytes;
      String? imagePath;
      if (hasPhoto) {
        imagePath = _photos.first;
        imageBytes = await _getImageBytes(imagePath);
      }

      Map<String, double>? dims;
      final p = double.tryParse(_lengthController.text);
      final l = double.tryParse(_widthController.text);
      final t = double.tryParse(_heightController.text);
      if (p != null && l != null && t != null) {
        dims = {'panjang': p, 'lebar': l, 'tinggi': t};
      }

      final result = await _aiService.generateAdDraft(
        title: title.isEmpty ? null : title,
        rawDetails: _descController.text,
        condition: _selectedCondition,
        isFree: _isFree,
        category: _selectedCategory,
        imageBytes: imageBytes,
        imagePath: imagePath,
        dimensions: dims,
      );

      if (!mounted) return;
      setState(() {
        if (_titleController.text.trim().isEmpty || _titleController.text.trim() == 'Kursi Belajar Ergonomis Putar') {
          _titleController.text = result.title;
        }

        String desc = result.description;
        if (dims != null && !desc.contains('[Dimensi:')) {
          desc = '$desc\n\n[Dimensi: ${_lengthController.text} × ${_widthController.text} × ${_heightController.text} cm]';
        }
        _descController.text = desc;

        if (AppConstants.categories.contains(result.suggestedCategory)) {
          _selectedCategory = result.suggestedCategory;
        }

        if (result.estimatedPrice != null && result.estimatedPrice! > 0 && !_isFree && _priceController.text.isEmpty) {
          _priceController.text = result.estimatedPrice.toString();
        }

        _isAiGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('✨ AI berhasil menyinkronkan deskripsi & kategori (${result.suggestedCategory}) sesuai foto iklan!'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isAiGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kendala saat menyusun AI: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (pickedFiles.isNotEmpty) {
          for (final file in pickedFiles) {
            try {
              final bytes = await file.readAsBytes();
              _photoBytesCache[file.path] = bytes;
            } catch (_) {}
          }
          setState(() {
            for (final file in pickedFiles) {
              if (!_photos.contains(file.path)) {
                _photos.add(file.path);
              }
            }
          });
        }
      } else {
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (pickedFile != null) {
          try {
            final bytes = await pickedFile.readAsBytes();
            _photoBytesCache[pickedFile.path] = bytes;
          } catch (_) {}
          setState(() {
            if (!_photos.contains(pickedFile.path)) {
              _photos.add(pickedFile.path);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  ImageProvider _getImageProvider(String path) {
    if (_photoBytesCache.containsKey(path)) {
      return MemoryImage(_photoBytesCache[path]!);
    }
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:') ||
        kIsWeb) {
      return NetworkImage(path);
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    return FileImage(File(path));
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Tambah Foto Barang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih sumber foto barang yang ingin Anda pasang:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Ambil Foto',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Buka Galeri',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tambahkan minimal 1 foto barang.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final listingProvider = Provider.of<ListingProvider>(context, listen: false);

    final currentUserId = authProvider.user?.id ?? 'user-current-1';
    final currentUserName = authProvider.user?.name ?? 'Pengguna jadiGuna';

    final price = _isFree ? 0 : int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), ''));

    var descriptionText = _descController.text.trim();
    if (_lengthController.text.trim().isNotEmpty &&
        _widthController.text.trim().isNotEmpty &&
        _heightController.text.trim().isNotEmpty) {
      final p = _lengthController.text.trim();
      final l = _widthController.text.trim();
      final t = _heightController.text.trim();
      final dimTag = '[Dimensi: $p × $l × $t cm]';
      if (!descriptionText.contains('[Dimensi:')) {
        descriptionText = '$descriptionText\n\n$dimTag';
      } else {
        descriptionText = descriptionText.replaceAll(RegExp(r'\[Dimensi:.*?\]'), dimTag);
      }
    }

    if (widget.listingToEdit != null) {
      final updated = widget.listingToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: descriptionText,
        categoryName: _selectedCategory,
        price: price,
        condition: _selectedCondition,
        locationName: _locationController.text.trim(),
        images: _photos,
      );
      await listingProvider.updateListing(updated);
    } else {
      await listingProvider.createListing(
        userId: currentUserId,
        categoryId: 'cat_${_selectedCategory.toLowerCase().replaceAll(' ', '_')}',
        categoryName: _selectedCategory,
        title: _titleController.text.trim(),
        description: descriptionText,
        price: price,
        condition: _selectedCondition,
        locationName: _locationController.text.trim(),
        images: _photos,
        sellerName: currentUserName,
      );
    }

    setState(() => _isSaving = false);
    if (!mounted) return;

    _showSuccessDialog(
      widget.listingToEdit != null,
      _titleController.text.trim(),
      _selectedCategory,
      price,
      _isFree,
    );
  }

  void _showSuccessDialog(bool isEditing, String title, String category, int? price, bool isFree) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 42),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing ? 'Iklan Berhasil Diperbarui!' : 'Iklan Berhasil Dipasang! 🎉',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Perubahan informasi barang telah berhasil disimpan.'
                      : 'Barang Anda kini sudah aktif dan siap dilihat oleh calon penerima atau pembeli di jadiGuna.',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 4),

                // Title "Pasang Iklan"
                const Text(
                  'Pasang Iklan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),

                // Share Button
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 22),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Subheader: Batal & Draft tersimpan otomatis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9DF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.cloud_done_outlined, size: 13, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          'Draft tersimpan otomatis',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Foto Barang Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Foto Barang',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${_photos.length} dari 5 foto terunggah',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Photos Row (Matching Image 4: Foto Utama with close x, Tambah Foto, Slot 3)
              SizedBox(
                height: 105,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Uploaded Photos
                    ..._photos.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final photo = entry.value;
                      return Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: _getImageProvider(photo),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Close Button at top-right
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => setState(() => _photos.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                            // "Foto Utama" Pill at bottom
                            if (idx == 0)
                              Positioned(
                                bottom: 6,
                                left: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Foto Utama',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    // Tambah Foto Card
                    if (_photos.length < 5)
                      GestureDetector(
                        onTap: _showAddPhotoSheet,
                        child: Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt_outlined, size: 22, color: AppColors.textSecondary),
                              SizedBox(height: 6),
                              Text(
                                'Tambah Foto',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Slot 3 Placeholder Card
                    if (_photos.length < 2)
                      Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFE9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.crop_original_rounded, size: 20, color: AppColors.textTertiary),
                            SizedBox(height: 6),
                            Text(
                              'Slot 3',
                              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // AI Asisten Deskripsi & Kategori Card (Soft Mint Green)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EA),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD3E7D6), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF27382B),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.hub_outlined, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'AI Asisten Deskripsi & Kategori',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'TUGAS AKHIR LLM MODEL',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.terracotta,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_suggest_rounded, color: AppColors.primaryDark, size: 22),
                          tooltip: 'Atur Gemini API Key',
                          onPressed: _showAiApiKeyDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'AI kami akan otomatis menyinkronkan deskripsi santun, memilih kategori tepat, dan menakar harga wajar dari foto iklan barang Anda!',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status Foto Iklan
                    if (_photos.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7EBD9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBEDFBF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF1E5E2B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Foto iklan terpasang (${_photos.length} foto): AI siap menyinkronkan judul, deskripsi & kategori!',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E5E2B)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '💡 Unggah foto barang di atas agar AI otomatis mengenali barang dan menyinkronkan iklan.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Preset Cepat Row
                    Row(
                      children: [
                        const Text(
                          'Preset cepat: ',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickPresetChip('✨ Barang Kos', () {
                                  _titleController.text = 'Meja Belajar Kayu Minimalis';
                                  _handleAiHelp();
                                }),
                                const SizedBox(width: 6),
                                _buildQuickPresetChip('🎁 Gratis', () {
                                  setState(() {
                                    _isFree = true;
                                    _priceController.clear();
                                  });
                                }),
                                const SizedBox(width: 6),
                                _buildQuickPresetChip('⚡ Nego Cepat', () {
                                  setState(() => _allowNego = true);
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Button: Buat Deskripsi Otomatis dengan AI
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27382B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: _isAiGenerating ? null : _handleAiHelp,
                        icon: _isAiGenerating
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: Text(
                          _isAiGenerating
                              ? 'Menyinkronkan dari foto...'
                              : (_photos.isNotEmpty ? '✨ Sinkronkan Deskripsi & Kategori dari Foto' : 'Buat Deskripsi Otomatis dengan AI'),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Judul Iklan Barang
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Judul Iklan Barang',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${_titleController.text.length} / 70 Karakter',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextFormField(
                  controller: _titleController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan judul barang...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                    suffixIcon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Judul wajib diisi' : null,
                ),
              ),

              const SizedBox(height: 16),

              // Kategori Barang
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kategori Barang',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 11, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Saran AI',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: AppConstants.categories.contains(_selectedCategory) && _selectedCategory != 'Semua'
                        ? _selectedCategory
                        : 'Furnitur',
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    items: AppConstants.categories
                        .where((c) => c != 'Semua')
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Text(
                                    c == 'Furnitur'
                                        ? '🪑 Furnitur & Perabotan Kamar'
                                        : c == 'Elektronik'
                                            ? '💻 Elektronik & Gadget'
                                            : c == 'Perlengkapan Rumah'
                                                ? '🏠 Perlengkapan Rumah'
                                                : c == 'Buku & Hobi'
                                                    ? '📚 Buku & Hobi'
                                                    : '🎁 Gratis',
                                    style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bagian Ukuran Barang (Dimensi & Sensor Kamera)
              _buildDimensionsSection(),

              const SizedBox(height: 16),

              // Barang Gratis Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECE8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.volunteer_activism_rounded, color: AppColors.terracotta, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Barang Gratis',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Aktifkan bila ikhlas memberikan barang tanpa biaya',
                            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isFree,
                      activeThumbColor: AppColors.terracotta,
                      onChanged: (val) {
                        setState(() {
                          _isFree = val;
                          if (_isFree) _priceController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Harga Pas / Patokan (Rp)
              if (!_isFree) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Harga Pas / Patokan (Rp)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Rekomendasi AI: Rp 75k - 95k',
                      style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'Rp  ',
                      prefixStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      hintText: '85.000',
                      hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textTertiary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (val) {
                      if (!_isFree && (val == null || val.trim().isEmpty)) {
                        return 'Harga wajib diisi';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Checkbox: Boleh ditawar santai (Nego Halus)
                InkWell(
                  onTap: () => setState(() => _allowNego = !_allowNego),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _allowNego,
                          activeColor: const Color(0xFF27382B),
                          onChanged: (val) => setState(() => _allowNego = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Boleh ditawar santai (Nego Halus)',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Kondisi Fisik Barang (2x2 Grid)
              const Text(
                'Kondisi Fisik Barang',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildConditionOption('✨ Baru / Belum Dipakai', 'Baru / Belum Dipakai'),
                  const SizedBox(width: 8),
                  _buildConditionOption('✔ Sangat Baik', 'Sangat Baik'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildConditionOption('👍 Layak Pakai', 'Layak Pakai'),
                  const SizedBox(width: 8),
                  _buildConditionOption('🔧 Perlu Servis / Modif', 'Perlu Servis / Modif'),
                ],
              ),

              const SizedBox(height: 18),

              // Deskripsi Barang with Perbaiki Teks AI Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Deskripsi Barang',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: _isAiGenerating ? null : _handleAiHelp,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 24)),
                    icon: const Icon(Icons.sync_rounded, size: 14, color: AppColors.terracotta),
                    label: const Text(
                      'Perbaiki Teks AI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextFormField(
                  controller: _descController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan deskripsi lengkap barang...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                ),
              ),

              const SizedBox(height: 18),

              // Titik Lokasi Pengambilan (COD)
              const Text(
                'Titik Lokasi Pengambilan (COD)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F2EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Kos Griya Mahasiswa, Pogung Kidul',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kec. Mlati, Kabupaten Sleman, D.I. Yogyakarta',
                            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFEA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Ganti GPS',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Checkbox: Sembunyikan alamat rinci
              InkWell(
                onTap: () => setState(() => _hideAddressUntilChat = !_hideAddressUntilChat),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Sembunyikan alamat rinci sampai sepakat di chat',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _hideAddressUntilChat,
                        activeColor: const Color(0xFF27382B),
                        onChanged: (val) => setState(() => _hideAddressUntilChat = val ?? true),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // SQLite Local Database Synced Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9DF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storage_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'SQLite Local Database Synced',
                        style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF48BB78),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Submit Button: Terbitkan Iklan Sekarang
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27382B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cell_tower_rounded, size: 18),
                  label: Text(
                    widget.listingToEdit != null ? 'Simpan Perubahan' : 'Terbitkan Iklan Sekarang',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD3E7D6)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildConditionOption(String label, String value) {
    final isSelected = _selectedCondition == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCondition = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF27382B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF27382B) : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bagian Ukuran Barang (Dimensi & Integrasi Sensor Pengukur) ──────────────

  Future<void> _openMeasurementTool() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const ItemMeasurementScreen(isSelectingForListing: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        final p = (result['length'] as num?)?.toDouble() ?? 0.0;
        final l = (result['width'] as num?)?.toDouble() ?? 0.0;
        final t = (result['height'] as num?)?.toDouble() ?? 0.0;

        if (p > 0) _lengthController.text = p.round().toString();
        if (l > 0) _widthController.text = l.round().toString();
        if (t > 0) _heightController.text = t.round().toString();
        _measuredWithSensor = true;

        final imgPath = result['imagePath'] as String?;
        if (imgPath != null && imgPath.isNotEmpty && !_photos.contains(imgPath)) {
          _photos.insert(0, imgPath);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Ukuran dari sensor kamera berhasil diterapkan!'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDimensionsSection() {
    final p = double.tryParse(_lengthController.text) ?? 0.0;
    final l = double.tryParse(_widthController.text) ?? 0.0;
    final t = double.tryParse(_heightController.text) ?? 0.0;
    final hasDimensions = p > 0 && l > 0 && t > 0;
    final volumeLiter = (p * l * t) / 1000.0;

    String vehicleRecommendation;
    Color vehicleColor;
    IconData vehicleIcon;

    final longest = math.max(p, math.max(l, t));
    if (longest <= 60 && volumeLiter <= 50) {
      vehicleRecommendation = 'Muat Sepeda Motor (Tas / Bagasi Depan)';
      vehicleColor = const Color(0xFF22C55E);
      vehicleIcon = Icons.two_wheeler_rounded;
    } else if (longest <= 130 && volumeLiter <= 350) {
      vehicleRecommendation = 'Muat Bagasi Mobil MPV / City Car';
      vehicleColor = const Color(0xFF3B82F6);
      vehicleIcon = Icons.directions_car_rounded;
    } else {
      vehicleRecommendation = 'Disarankan Mobil Pick-up / Van Bak';
      vehicleColor = const Color(0xFFD97706);
      vehicleIcon = Icons.local_shipping_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _measuredWithSensor ? AppColors.primaryLight : AppColors.border,
          width: _measuredWithSensor ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              const Expanded(
                child: Text(
                  'Ukuran Barang (Dimensi)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _measuredWithSensor ? AppColors.primarySurface : const Color(0xFFF3EFE9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _measuredWithSensor ? AppColors.primary : AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _measuredWithSensor ? Icons.verified_rounded : Icons.straighten_rounded,
                      size: 11,
                      color: _measuredWithSensor ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _measuredWithSensor ? 'Terukur via Sensor' : 'Opsional',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _measuredWithSensor ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Calon pengambil butuh tahu ukuran agar bisa menyiapkan kendaraan angkut yang pas.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 12),

          // Banner Button: Ukur Otomatis dengan Kamera / Sensor
          InkWell(
            onTap: _openMeasurementTool,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F3EA), Color(0xFFF3F9F4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7E2CC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF27382B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_enhance_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ukur dengan Sensor Kamera',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E3524)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gunakan patokan KTP/uang rupiah untuk ukur otomatis',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF27382B)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3 Inputs (Panjang, Lebar, Tinggi)
          Row(
            children: [
              Expanded(child: _buildDimensionInput('Panjang', _lengthController)),
              const SizedBox(width: 8),
              Expanded(child: _buildDimensionInput('Lebar', _widthController)),
              const SizedBox(width: 8),
              Expanded(child: _buildDimensionInput('Tinggi', _heightController)),
            ],
          ),
          const SizedBox(height: 10),

          // Volume & Vehicle Recommendation Preview
          if (hasDimensions) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: vehicleColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: vehicleColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(vehicleIcon, color: vehicleColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Volume: ${volumeLiter.toStringAsFixed(1)} Liter • $vehicleRecommendation',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: vehicleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Quick Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Preset: ', style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                _buildDimensionPresetChip('Meja', 100, 50, 75),
                const SizedBox(width: 6),
                _buildDimensionPresetChip('Kursi', 55, 55, 95),
                const SizedBox(width: 6),
                _buildDimensionPresetChip('Lemari', 80, 50, 180),
                const SizedBox(width: 6),
                _buildDimensionPresetChip('Rak', 60, 30, 120),
                const SizedBox(width: 6),
                _buildDimensionPresetChip('Sofa', 140, 75, 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (cm)',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildDimensionPresetChip(String name, int p, int l, int t) {
    return InkWell(
      onTap: () {
        setState(() {
          _lengthController.text = p.toString();
          _widthController.text = l.toString();
          _heightController.text = t.toString();
          _measuredWithSensor = false;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFE9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '$name ($p×$l×$t)',
          style: const TextStyle(fontSize: 10.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
