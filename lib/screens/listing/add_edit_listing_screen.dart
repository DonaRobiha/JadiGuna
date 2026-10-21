import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

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

  final List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    final edit = widget.listingToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _descController = TextEditingController(text: edit?.description ?? '');
    _priceController = TextEditingController(text: (edit != null && !edit.isFree) ? edit.price.toString() : '');
    _locationController = TextEditingController(text: edit?.locationName ?? 'Pogung Dalangan, Sleman (Dekat UGM)');

    _selectedCategory = edit?.categoryName ?? 'Furnitur';
    _selectedCondition = edit?.condition ?? 'Baik (Layak Pakai)';
    _isFree = edit?.isFree ?? false;

    if (edit != null && edit.images.isNotEmpty) {
      _photos.addAll(edit.images);
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
          content: Text('✨ Draf deskripsi berhasil disusun dan kategori disarankan: $_selectedCategory! Anda dapat mengeditnya kembali.'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Column(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Ambil Foto',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gunakan Kamera',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Column(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 26),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Buka Galeri',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pilih dari File Foto',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
          content: Text('Silakan tambahkan minimal 1 foto barang (dari kamera atau galeri).'),
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
                // Celebration Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  isEditing ? 'Iklan Berhasil Diperbarui!' : 'Iklan Berhasil Dipasang! 🎉',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  isEditing
                      ? 'Perubahan informasi barang telah berhasil disimpan dan diperbarui di sistem.'
                      : 'Barang Anda kini sudah aktif dan siap dilihat oleh calon penerima atau pembeli di jadiGuna.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kategori: $category',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFree ? AppColors.freeBadgeBg : AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFree ? 'GRATIS' : CurrencyFormatter.format(price),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isFree ? AppColors.freeBadge : AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        _titleController.clear();
                        _descController.clear();
                        _priceController.clear();
                        setState(() {
                          _photos.clear();
                        });
                      }
                    },
                    child: const Text(
                      'Selesai & Lihat Iklan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
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
    final isEditing = widget.listingToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Iklan Barang' : 'Pasang Iklan Barang'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photos horizontal list
                const Text('Foto Barang', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Add Photo Button
                      InkWell(
                        onTap: _showAddPhotoSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 85,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryLight, width: 1.5),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 26),
                              SizedBox(height: 4),
                              Text('Tambah', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Photos thumbnails or empty state
                      if (_photos.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Belum ada foto.\nAmbil dari kamera atau buka galeri.',
                            style: TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.3),
                          ),
                        ),

                      ..._photos.map((photo) {
                        return Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                            image: DecorationImage(
                              image: _getImageProvider(photo),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photos.remove(photo)),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                CustomTextField(
                  controller: _titleController,
                  label: 'Judul Iklan',
                  hint: 'Contoh: Meja Belajar Kayu Jati Belanda',
                  prefixIcon: Icons.title_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Judul iklan wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                const Text('Kategori Barang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary, size: 20)),
                  items: AppConstants.categories
                      .where((c) => c != 'Semua')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),

                // Free Item Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isFree ? AppColors.freeBadgeBg : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isFree ? AppColors.freeBadge : AppColors.border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Berikan Secara GRATIS (Rp 0)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Bantu sesama dan perpanjang masa pakai barang', style: TextStyle(fontSize: 12)),
                    value: _isFree,
                    activeColor: AppColors.freeBadge,
                    onChanged: (val) {
                      setState(() {
                        _isFree = val;
                        if (_isFree) _priceController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Price (If not free)
                if (!_isFree) ...[
                  CustomTextField(
                    controller: _priceController,
                    label: 'Harga (Rupiah)',
                    hint: 'Contoh: 150000',
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (!_isFree && (val == null || val.trim().isEmpty)) {
                        return 'Harga wajib diisi atau aktifkan opsi Barang Gratis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Condition Dropdown
                const Text('Kondisi Barang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20)),
                  items: AppConstants.conditions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCondition = val);
                  },
                ),
                const SizedBox(height: 16),

                // Location
                CustomTextField(
                  controller: _locationController,
                  label: 'Lokasi Umum / Area Pengambilan',
                  hint: 'Contoh: Gejayan, Sleman (Dekat UNY)',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Lokasi wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description with AI Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Deskripsi Barang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    // AI Assistant Trigger Button
                    TextButton.icon(
                      onPressed: _isAiGenerating ? null : _handleAiHelp,
                      icon: _isAiGenerating
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                      label: Text(
                        _isAiGenerating ? 'Menyusun...' : '✨ Susun dengan AI',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _descController,
                  label: '',
                  hint: 'Tuliskan detail barang, alasan dijual/diberikan, dan spesifikasi...',
                  maxLines: 5,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Deskripsi wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: isEditing ? 'Simpan Perubahan' : 'Terbitkan Iklan Sekarang',
                  isLoading: _isSaving,
                  icon: isEditing ? Icons.save_rounded : Icons.campaign_rounded,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
