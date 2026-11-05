import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/ai_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../listing/add_edit_listing_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  String _selectedCondition = 'Sangat Baik';
  bool _isFree = false;
  bool _isLoading = false;
  bool _isApiKeyConfigured = false;
  AiGenerationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _checkApiKeyStatus();
  }

  Future<void> _checkApiKeyStatus() async {
    final key = await AiService.getApiKey();
    if (mounted) {
      setState(() {
        _isApiKeyConfigured = key != null && key.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImagePath = picked.path;
          _selectedImageBytes = bytes;
        });

        // Tampilkan konfirmasi dan tawarkan scan langsung
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.photo_camera_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Foto berhasil dimuat. Ketuk tombol di bawah untuk memindai dengan AI!'),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _generateDraft() async {
    final title = _titleController.text.trim();
    final hasPhoto = _selectedImageBytes != null && _selectedImageBytes!.isNotEmpty;

    if (title.isEmpty && !hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah foto barang atau ketik nama barang terlebih dahulu agar AI dapat menganalisis.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _aiService.generateAdDraft(
        title: title.isEmpty ? null : title,
        rawDetails: _notesController.text.trim(),
        condition: _selectedCondition,
        isFree: _isFree,
        imageBytes: _selectedImageBytes,
        imagePath: _selectedImagePath,
      );

      if (!mounted) return;
      setState(() {
        _lastResult = res;
        _titleController.text = res.title;
        _resultController.text = res.description;
        if (res.suggestedCondition != null &&
            AppConstants.conditions.contains(res.suggestedCondition)) {
          _selectedCondition = res.suggestedCondition!;
        }
        _isLoading = false;
      });

      if (!res.fromLlm) {
        final message = res.llmError != null
            ? '⚠️ Gemini Vision gagal (${res.llmError}). Beralih ke analisis lokal: "${res.title}"'
            : _isApiKeyConfigured
                ? '💡 Analisis Lokal: "${res.title}".'
                : '💡 Analisis Lokal: "${res.title}". Masukkan Gemini API Key di ikon 🔑 untuk hasil scan foto 100% akurat.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: res.llmError != null ? AppColors.warning : AppColors.primaryDark,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✨ AI Gemini Vision berhasil memindai: "${res.title}" (${res.suggestedCategory})',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kendala AI: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _polishCurrentText() async {
    if (_resultController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final polished = await _aiService.polishText(_resultController.text);
      if (!mounted) return;
      setState(() {
        _resultController.text = polished;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memoles teks: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAiApiKeyDialog() async {
    final currentKey = await AiService.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'API Key Google Gemini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan Google Gemini API Key Anda untuk mengaktifkan AI Vision Multimodal yang memindai foto barang secara akurat.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  labelText: 'Gemini API Key',
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Catatan: Jika dikosongkan, sistem tetap berjalan dalam mode analisis lokal.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.7) : AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await AiService.saveApiKey(controller.text.trim());
                await _checkApiKeyStatus();
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
        );
      },
    );
  }

  Widget _buildPhotoPreview(bool isDark) {
    if (_selectedImageBytes != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              _selectedImageBytes!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                tooltip: 'Hapus Foto',
                onPressed: () {
                  setState(() {
                    _selectedImagePath = null;
                    _selectedImageBytes = null;
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 36,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'Unggah Foto Barang untuk Pemindaian AI',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI Vision akan otomatis mengenali jenis barang, kategori, kondisi, dan harga wajar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Kamera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Galeri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Asisten AI & Scan Barang'),
        actions: [
          IconButton(
            icon: Icon(
              _isApiKeyConfigured ? Icons.vpn_key_rounded : Icons.key_off_rounded,
              color: _isApiKeyConfigured ? Colors.green : Colors.amber.shade700,
            ),
            tooltip: _isApiKeyConfigured ? 'Gemini API Key Aktif' : 'Gemini API Key Belum Diisi',
            onPressed: _showAiApiKeyDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Vision & Kurator Barang Pintar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isApiKeyConfigured
                              ? '✨ Google Gemini Vision aktif. Foto barang Anda dan AI akan mendeteksi nama, kategori, dan deskripsi secara akurat.'
                              : '💡 Mode Offline aktif. Masukkan Kunci API Gemini pada ikon 🔑 untuk akurasi visual maksimal.',
                          style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Input Form Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Foto Barang (Pemindaian Visual)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 10),
                  _buildPhotoPreview(isDark),
                  const SizedBox(height: 18),

                  Text(
                    '2. Data Barang (Boleh Dikosongkan jika ada foto)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _titleController,
                    label: 'Judul / Nama Barang',
                    hint: 'Contoh: Sepatu Sneakers Ventela / Kipas Miyako',
                    prefixIcon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _notesController,
                    label: 'Catatan Khusus (Opsional)',
                    hint: 'Minus, kelengkapan, alasan jual/diberikan...',
                    maxLines: 2,
                    prefixIcon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kondisi Fisik:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subTextColor),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              dropdownColor: cardBg,
                              initialValue: AppConstants.conditions.contains(_selectedCondition)
                                  ? _selectedCondition
                                  : AppConstants.conditions.first,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: AppConstants.conditions.toSet().map((c) {
                                return DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: TextStyle(fontSize: 11, color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedCondition = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jenis Penawaran:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subTextColor),
                            ),
                            const SizedBox(height: 4),
                            ChoiceChip(
                              label: Text(
                                _isFree ? 'Gratis' : 'Dijual',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isFree ? AppColors.freeBadge : textColor,
                                ),
                              ),
                              selected: _isFree,
                              selectedColor: isDark ? const Color(0xFF4A251C) : AppColors.freeBadgeBg,
                              backgroundColor: isDark ? AppColors.darkSurface : AppColors.background,
                              onSelected: (val) => setState(() => _isFree = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    text: _selectedImageBytes != null
                        ? '🔍 Pindai Foto & Susun Iklan AI'
                        : 'Susun Draf Deskripsi dengan AI',
                    icon: Icons.auto_awesome_rounded,
                    isLoading: _isLoading,
                    onPressed: _generateDraft,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Generated Results Card
            if (_resultController.text.isNotEmpty || _lastResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.primaryLight,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Hasil Pemindaian AI',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        const Spacer(),
                        if (_lastResult != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _lastResult!.fromLlm
                                  ? (isDark ? const Color(0xFF1E3A24) : AppColors.primarySurface)
                                  : (isDark ? const Color(0xFF3D2E14) : Colors.amber.shade50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _lastResult!.fromLlm ? '✨ Gemini Vision' : '💡 Analisis Lokal',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _lastResult!.fromLlm
                                    ? (isDark ? const Color(0xFF81C784) : AppColors.primaryDark)
                                    : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Kategori: ${_lastResult!.suggestedCategory}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_lastResult != null && _lastResult!.estimatedPrice != null && !_isFree)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.terracotta),
                            const SizedBox(width: 6),
                            Text(
                              'Estimasi Harga Wajar: Rp ${_lastResult!.estimatedPrice}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                            ),
                          ],
                        ),
                      ),

                    TextField(
                      controller: _resultController,
                      maxLines: 8,
                      style: TextStyle(fontSize: 13, height: 1.5, color: textColor),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Hasil deskripsi...',
                        fillColor: isDark ? AppColors.darkSurface : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Suggested Keywords
                    if (_lastResult != null && _lastResult!.suggestedKeywords.isNotEmpty) ...[
                      Text(
                        'Saran Kata Kunci Pencarian:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subTextColor),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _lastResult!.suggestedKeywords.map((k) {
                          return Chip(
                            label: Text(
                              k,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            backgroundColor: isDark ? AppColors.darkSurface : AppColors.background,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_lastResult != null && _lastResult!.tips.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: _lastResult!.fromLlm
                              ? (isDark ? const Color(0xFF1E3A24) : AppColors.primarySurface)
                              : (isDark ? const Color(0xFF3D2E14) : Colors.amber.shade50),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _lastResult!.fromLlm
                                ? (isDark ? const Color(0xFF2E5A35) : AppColors.primaryLight)
                                : (isDark ? const Color(0xFF6B5120) : Colors.amber.shade200),
                          ),
                        ),
                        child: Text(
                          _lastResult!.tips,
                          style: TextStyle(
                            fontSize: 11,
                            color: _lastResult!.fromLlm
                                ? (isDark ? const Color(0xFFA5D6A7) : AppColors.primaryDark)
                                : (isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 38),
                        foregroundColor: AppColors.primaryDark,
                      ),
                      onPressed: _polishCurrentText,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: const Text('✨ Poles & Perjelas Teks Deskripsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _resultController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Deskripsi berhasil disalin ke papan klip!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Salin Teks', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditListingScreen(
                                    initialTitle: _titleController.text.trim(),
                                    initialDescription: _resultController.text.trim(),
                                    initialCategory: _lastResult?.suggestedCategory,
                                    initialCondition: _selectedCondition,
                                    initialIsFree: _isFree,
                                    initialImagePath: _selectedImagePath,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                            label: const Text('Pasang Iklan', style: TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
