
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
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

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) return;

    setState(() => _isPickingPhoto = true);

    try {
      final XFile? selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (selected == null || !mounted) return;

      final appDirectory = await getApplicationSupportDirectory();
      final photoDirectory = Directory(
        p.join(appDirectory.path, 'profile_photos'),
      );

      if (!await photoDirectory.exists()) {
        await photoDirectory.create(recursive: true);
      }

      final extension = p.extension(selected.path);
      final savedPath = p.join(
        photoDirectory.path,
        'profile_${DateTime.now().microsecondsSinceEpoch}$extension',
      );

      await File(selected.path).copy(savedPath);

      if (!mounted) return;

      setState(() => _photoPath = savedPath);
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

  Widget _buildAvatar() {
    final path = (_photoPath == null || _photoPath!.isEmpty)
        ? AppConstants.defaultProfilePhotoUrl
        : _photoPath;
    ImageProvider? imageProvider;

    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        imageProvider = NetworkImage(path);
      } else if (File(path).existsSync()) {
        imageProvider = FileImage(File(path));
      }
    }

    return CircleAvatar(
      radius: 46,
      backgroundColor: AppColors.primarySurface,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(
              Icons.person,
              size: 50,
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
                  child: Stack(
                    children: [
                      _buildAvatar(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _isPickingPhoto ? null : _pickPhoto,
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
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