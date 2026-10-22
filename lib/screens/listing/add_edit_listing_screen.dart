import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../services/ai_service.dart';

class AddEditListingScreen extends StatefulWidget {
  final ListingModel? listingToEdit;

  const AddEditListingScreen({super.key, this.listingToEdit});

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

  late String _selectedCategory;
  late String _selectedCondition;
  bool _isFree = false;
  bool _isAiGenerating = false;
  bool _isSaving = false;
  bool _allowNego = true;
  bool _hideAddressUntilChat = true;

  final List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    final edit = widget.listingToEdit;
    _titleController = TextEditingController(
      text: edit?.title ?? 'Kursi Belajar Ergonomis Putar',
    );
    _descController = TextEditingController(
      text: edit?.description ??
          'Kursi kerja putar hidrolik masih berfungsi lancar turun-naik tanpa macet. Busa dudukan masih empuk, tebal, dan bebas noda basah. Roda lima lancar menggelinding di ubin atau karpet kos. Minus pemakaian normal di armrest kiri sedikit gores halus. Sangat cocok untuk mahasiswa...',
    );
    _priceController = TextEditingController(
      text: (edit != null && !edit.isFree)
          ? edit.price.toString()
          : (edit == null ? '85000' : ''),
    );
    _locationController = TextEditingController(
      text: edit?.locationName ?? 'Kos Griya Mahasiswa, Pogung Kidul, Kec. Mlati, Kabupaten Sleman, D.I. Yogyakarta',
    );

    _selectedCategory = edit?.categoryName ?? 'Furnitur';
    _selectedCondition = edit?.condition ?? 'Sangat Baik';
    _isFree = edit?.isFree ?? false;

    if (edit != null && edit.images.isNotEmpty) {
      _photos.addAll(edit.images);
    } else {
      // Default photo from Image 4
      _photos.add('https://images.unsplash.com/photo-1580481077191-c29223c84996?w=800');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleAiHelp() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi judul barang terlebih dahulu agar AI dapat memahami konteks barang Anda.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAiGenerating = true);
    try {
      final result = await _aiService.generateAdDraft(
        title: title,
        rawDetails: _descController.text,
        condition: _selectedCondition,
        isFree: _isFree,
        category: _selectedCategory,
      );

      if (!mounted) return;
      setState(() {
        _descController.text = result.description;
        if (AppConstants.categories.contains(result.suggestedCategory)) {
          _selectedCategory = result.suggestedCategory;
        }
        _isAiGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Draf deskripsi berhasil disusun dan kategori disarankan: $_selectedCategory!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (_) {
      setState(() => _isAiGenerating = false);
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
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
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

    if (widget.listingToEdit != null) {
      final updated = widget.listingToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
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
        description: _descController.text.trim(),
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

                // Brand Circle Logo
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC29B72), width: 1.8),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC29B72),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

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

                // User Profile Picture
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                  ),
                ),
                const SizedBox(width: 6),
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
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cukup masukkan judul singkat atau foto, AI kami akan otomatis menyusun deskripsi santun, memilih kategori tepat, dan menakar harga wajar!',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

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
                                _buildQuickPresetChip('✨ Barang Bekas Kos', () {
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
                          _isAiGenerating ? 'Menyusun...' : 'Buat Deskripsi Otomatis dengan AI',
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
}
