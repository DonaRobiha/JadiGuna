
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;

  String? _photoPath;
  bool _isSaving = false;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();

    final user = Provider.of<AuthProvider>(context, listen: false).user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(
      text: user?.bio ?? 'Mahasiswa aktif mencari barang kos hemat.',
    );
    _cityController = TextEditingController(
      text: user?.city ?? 'Sleman, D.I. Yogyakarta',
    );
    _phoneController = TextEditingController(
      text: user?.phoneNumber ?? '081234567890',
    );

    _photoPath = user?.profilePhotoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto([ImageSource source = ImageSource.gallery]) async {
    if (_isPickingPhoto) return;

    setState(() => _isPickingPhoto = true);

    try {
      final XFile? selected = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (selected == null || !mounted) return;

      String finalPath;
      if (kIsWeb) {
        finalPath = selected.path;
      } else {
        final appDirectory = await getApplicationSupportDirectory();
        final photoDirectory = Directory(
          p.join(appDirectory.path, 'profile_photos'),
        );

        if (!await photoDirectory.exists()) {
          await photoDirectory.create(recursive: true);
        }

        final ext = p.extension(selected.path).isEmpty ? '.jpg' : p.extension(selected.path);
        final savedPath = p.join(
          photoDirectory.path,
          'profile_${DateTime.now().microsecondsSinceEpoch}$ext',
        );

        await File(selected.path).copy(savedPath);
        finalPath = savedPath;
      }

      if (!mounted) return;

      setState(() => _photoPath = finalPath);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil baru dipilih. Klik "Simpan Profil" untuk menerapkan.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  void _removePhoto() {
    setState(() => _photoPath = null);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto profil dihapus. Klik "Simpan Profil" untuk menerapkan.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPhotoOptions() {
    final hasPhoto = _photoPath != null && _photoPath!.trim().isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Foto Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Ambil Foto dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    ),
                    title: const Text(
                      'Hapus Foto Profil',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removePhoto();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;

    if (_photoPath != null && _photoPath!.trim().isNotEmpty) {
      final path = _photoPath!.trim();
      if (path.startsWith('http://') ||
          path.startsWith('https://') ||
          path.startsWith('blob:') ||
          kIsWeb) {
        imageProvider = NetworkImage(path);
      } else if (path.startsWith('assets/')) {
        imageProvider = AssetImage(path);
      } else if (!kIsWeb && File(path).existsSync()) {
        imageProvider = FileImage(File(path));
      }
    }

    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.primarySurface,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(
              Icons.person,
              size: 52,
              color: AppColors.primary,
            )
          : null,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      final success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        photoPath: _photoPath,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Gagal memperbarui profil.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: _isPickingPhoto ? null : _showPhotoOptions,
                            child: _buildAvatar(),
                          ),

                          // Camera button (Bottom-right)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Tooltip(
                              message: 'Ubah foto profil',
                              child: Material(
                                color: AppColors.primary,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: InkWell(
                                  onTap: _isPickingPhoto ? null : _showPhotoOptions,
                                  customBorder: const CircleBorder(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(9),
                                    child: _isPickingPhoto
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Delete button (Top-right, if photo exists)
                          if (_photoPath != null && _photoPath!.trim().isNotEmpty)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Tooltip(
                                message: 'Hapus foto',
                                child: Material(
                                  color: AppColors.error,
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: _isPickingPhoto ? null : _removePhoto,
                                    customBorder: const CircleBorder(),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _isPickingPhoto ? null : _showPhotoOptions,
                            icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: AppColors.primary),
                            label: Text(
                              _photoPath != null && _photoPath!.trim().isNotEmpty
                                  ? 'Ganti Foto'
                                  : 'Tambah Foto',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (_photoPath != null && _photoPath!.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _isPickingPhoto ? null : _removePhoto,
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                              label: const Text(
                                'Hapus Foto',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  hint: 'Nama Anda',
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _cityController,
                  label: 'Kota / Wilayah',
                  hint: 'Contoh: Sleman, D.I. Yogyakarta',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Nomor Telepon / WhatsApp',
                  hint: '0812xxxxxxxx',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _bioController,
                  label: 'Bio Singkat',
                  hint: 'Ceritakan sedikit tentang Anda...',
                  maxLines: 3,
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Simpan Profil',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}