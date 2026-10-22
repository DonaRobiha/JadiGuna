import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _titleController = TextEditingController(text: 'Meja Belajar Minimalis');
  final TextEditingController _notesController = TextEditingController(text: 'Bahan kayu jati londo, ada laci samping, kokoh');
  final TextEditingController _resultController = TextEditingController();

  String _selectedCondition = 'Layak Pakai';
  bool _isFree = false;
  bool _isLoading = false;
  AiGenerationResult? _lastResult;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _generateDraft() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan judul atau nama barang terlebih dahulu.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _aiService.generateAdDraft(
        title: title,
        rawDetails: _notesController.text.trim(),
        condition: _selectedCondition,
        isFree: _isFree,
      );

      if (!mounted) return;
      setState(() {
        _lastResult = res;
        _resultController.text = res.description;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan AI: $e'), backgroundColor: AppColors.error),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Asisten AI / LLM Iklan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Info Banner
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
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Copywriter & Kategori Pintar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        SizedBox(height: 2),
                        Text(
                          'Membantu Anda menyusun deskripsi iklan yang informatif, menarik, dan menyarankan kategori yang tepat secara otomatis.',
                          style: TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Mentah Barang', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _titleController,
                    label: 'Judul / Nama Barang',
                    hint: 'Contoh: Monitor PC LG 22 Inch',
                    prefixIcon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _notesController,
                    label: 'Catatan Khusus / Poin Penting',
                    hint: 'Kelengkapan kabel, alasan jual/diberikan, minus bila ada...',
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
                            const Text('Kondisi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCondition,
                              isExpanded: true,
                              items: AppConstants.conditions
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11))))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCondition = v);
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
                            const Text('Tipe Penawaran:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            ChoiceChip(
                              label: Text(_isFree ? 'Gratis' : 'Dijual', style: const TextStyle(fontSize: 12)),
                              selected: _isFree,
                              selectedColor: AppColors.freeBadgeBg,
                              onSelected: (val) => setState(() => _isFree = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    text: 'Susun Draf Deskripsi dengan AI',
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryLight, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Hasil Rekomendasi AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (_lastResult != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Kategori: ${_lastResult!.suggestedCategory}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _resultController,
                      maxLines: 8,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Hasil deskripsi...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Suggested Keywords
                    if (_lastResult != null && _lastResult!.suggestedKeywords.isNotEmpty) ...[
                      const Text('Saran Kata Kunci Pencarian:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _lastResult!.suggestedKeywords.map((k) {
                          return Chip(
                            label: Text(k, style: const TextStyle(fontSize: 10)),
                            backgroundColor: AppColors.background,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
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
