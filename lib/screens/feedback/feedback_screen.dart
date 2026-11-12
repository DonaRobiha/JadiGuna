import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/local_database.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/feedback_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  // ====== EDIT DI SINI: isi saran & kesan mata kuliah ======
  static const String namaMatkul = 'Pemrograman Aplikasi Mobile';

  static const String kesanMatkul =
      'Mata kuliah Pemrograman Aplikasi Mobile menjadi pengalaman belajar yang '
      'paling terasa langsung manfaatnya. Lewat tugas akhir ini saya belajar '
      'membuat aplikasi utuh, mulai dari login dan session, database lokal '
      'dan online, pemanfaatan sensor, lokasi (GPS), notifikasi, sampai '
      'integrasi API. Materinya menantang, tetapi hasilnya membuat saya lebih '
      'percaya diri membangun aplikasi mobile sendiri.';

  static const String saranMatkul =
      'Semoga ke depannya waktu praktik dan pendampingan pengerjaan proyek '
      'ditambah, terutama untuk materi yang cukup berat seperti autentikasi, '
      'database online, dan integrasi AI. Akan lebih baik lagi jika ada contoh '
      'proyek lengkap atau sesi tanya jawab berkala selama pengerjaan tugas '
      'akhir supaya kendala bisa segera teratasi.';
  // =========================================================

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final TextEditingController _kesanController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();

  static const String _categoryMatkul = 'Mata Kuliah PAM';

  int _selectedRating = 5;
  bool _isSubmitting = false;
  List<FeedbackModel> _pastFeedback = [];

  @override
  void initState() {
    super.initState();
    _loadPastFeedback();
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  Future<void> _loadPastFeedback() async {
    final list = await _localDb.getFeedbackList();
    if (!mounted) return;
    setState(() => _pastFeedback = list);
  }

  Future<void> _submitFeedback() async {
    final kesan = _kesanController.text.trim();
    final saran = _saranController.text.trim();
    if (kesan.isEmpty && saran.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi minimal salah satu: kesan atau saran.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Simpan kesan & saran dalam satu pesan dengan penanda
    final message = '[KESAN]\n$kesan\n[SARAN]\n$saran';

    setState(() => _isSubmitting = true);
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    final feedback = FeedbackModel(
      id: 'fb-${const Uuid().v4().substring(0, 8)}',
      userId: user?.id ?? 'user-current-1',
      userName: user?.name ?? 'Pengguna jadiGuna',
      category: _categoryMatkul,
      rating: _selectedRating,
      message: message,
      createdAt: DateTime.now(),
    );

    await _localDb.insertFeedback(feedback);
    _kesanController.clear();
    _saranController.clear();
    await _loadPastFeedback();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tambahan berhasil disimpan. Terima kasih!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Memisahkan pesan tersimpan menjadi kesan & saran.
  /// Data lama (tanpa penanda) dianggap sebagai satu teks biasa.
  ({String kesan, String saran, String umum}) _parseMessage(String msg) {
    if (!msg.startsWith('[KESAN]')) {
      return (kesan: '', saran: '', umum: msg);
    }
    final body = msg.substring('[KESAN]'.length);
    final idx = body.indexOf('[SARAN]');
    if (idx == -1) {
      return (kesan: body.trim(), saran: '', umum: '');
    }
    return (
      kesan: body.substring(0, idx).trim(),
      saran: body.substring(idx + '[SARAN]'.length).trim(),
      umum: '',
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildTextCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saran dan Kesan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mata kuliah
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded,
                      color: AppColors.primary, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mata Kuliah',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          FeedbackScreen.namaMatkul,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        if (user != null)
                          Text(
                            'Oleh: ${user.name}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Kesan (langsung tampil, tanpa input)
            _buildTextCard(
              icon: Icons.favorite_rounded,
              title: 'Kesan',
              text: FeedbackScreen.kesanMatkul,
            ),
            const SizedBox(height: 14),

            // Saran (langsung tampil, tanpa input)
            _buildTextCard(
              icon: Icons.lightbulb_rounded,
              title: 'Saran',
              text: FeedbackScreen.saranMatkul,
            ),
            const SizedBox(height: 24),

            // Tambahan (opsional)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambahan (Opsional)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ada kesan atau saran lain? Tulis di kotak masing-masing.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kepuasan terhadap mata kuliah:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return IconButton(
                        icon: Icon(
                          starNum <= _selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.secondary,
                          size: 32,
                        ),
                        onPressed: () => setState(() => _selectedRating = starNum),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.favorite_rounded,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Kesan Anda',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _kesanController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Tulis kesan Anda tentang mata kuliah dan dosen...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Saran Anda',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _saranController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Tulis saran Anda untuk mata kuliah dan dosen...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Simpan Tambahan',
                    icon: Icons.send_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _submitFeedback,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Riwayat tambahan
            if (_pastFeedback.isNotEmpty) ...[
              const Text(
                'Kesan & Saran Tambahan yang Telah Disimpan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pastFeedback.length,
                itemBuilder: (context, index) {
                  final item = _pastFeedback[index];
                  final parsed = _parseMessage(item.message);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                item.rating,
                                (i) => const Icon(Icons.star_rounded,
                                    size: 14, color: AppColors.secondary),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormatter.formatRelative(item.createdAt),
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                        if (parsed.kesan.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildTextCard(
                            icon: Icons.favorite_rounded,
                            title: 'Kesan',
                            text: parsed.kesan,
                          ),
                        ],
                        if (parsed.saran.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildTextCard(
                            icon: Icons.lightbulb_rounded,
                            title: 'Saran',
                            text: parsed.saran,
                          ),
                        ],
                        if (parsed.umum.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            parsed.umum,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}