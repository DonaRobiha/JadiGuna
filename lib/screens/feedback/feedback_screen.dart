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

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final TextEditingController _messageController = TextEditingController();

  String _selectedCategory = 'Fitur';
  int _selectedRating = 5;
  bool _isSubmitting = false;
  List<FeedbackModel> _pastFeedback = [];

  final List<String> _categories = [
    'Fitur',
    'Tampilan UI/UX',
    'Kendala / Bug',
    'Saran Kemitraan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadPastFeedback();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadPastFeedback() async {
    final list = await _localDb.getFeedbackList();
    setState(() => _pastFeedback = list);
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tuliskan pesan saran atau kesan Anda.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final feedback = FeedbackModel(
      id: 'fb-${const Uuid().v4().substring(0, 8)}',
      userId: user?.id ?? 'user-current-1',
      userName: user?.name ?? 'Pengguna jadiGuna',
      category: _selectedCategory,
      rating: _selectedRating,
      message: message,
      createdAt: DateTime.now(),
    );

    await _localDb.insertFeedback(feedback);
    _messageController.clear();
    await _loadPastFeedback();

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('Terima Kasih!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Masukan dan kesan Anda sangat berharga bagi penyempurnaan aplikasi jadiGuna untuk Tugas Akhir ini.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // Form Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Formulir Masukan Pengguna', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  // Rating Stars
                  const Text('Tingkat Kepuasan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return IconButton(
                        icon: Icon(
                          starNum <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.secondary,
                          size: 32,
                        ),
                        onPressed: () => setState(() => _selectedRating = starNum),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Category Dropdown
                  const Text('Kategori Masukan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Message field
                  const Text('Pesan, Saran, atau Kesan Anda:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan pengalaman Anda menggunakan aplikasi jadiGuna...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Kirim Masukan',
                    icon: Icons.send_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _submitFeedback,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Past Feedback History
            if (_pastFeedback.isNotEmpty) ...[
              const Text('Riwayat Masukan yang Telah Terkirim', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pastFeedback.length,
                itemBuilder: (context, index) {
                  final item = _pastFeedback[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: List.generate(
                                item.rating,
                                (i) => const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormatter.formatRelative(item.createdAt),
                              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.message,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                        ),
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
