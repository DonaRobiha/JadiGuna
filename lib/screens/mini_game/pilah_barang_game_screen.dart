import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class GameItem {
  final String name;
  final String icon;
  final String category;
  final String tip;

  const GameItem({
    required this.name,
    required this.icon,
    required this.category,
    required this.tip,
  });
}

class PilahBarangGameScreen extends StatefulWidget {
  const PilahBarangGameScreen({super.key});

  @override
  State<PilahBarangGameScreen> createState() => _PilahBarangGameScreenState();
}

class _PilahBarangGameScreenState extends State<PilahBarangGameScreen> {
  static const List<GameItem> _allItems = [
    GameItem(name: 'Kipas Angin Berdiri', icon: '🌀', category: 'Elektronik', tip: 'Komponen dinamo dan plastik kipas dapat diservis atau didaur ulang.'),
    GameItem(name: 'Meja Belajar Kayu', icon: '🪑', category: 'Furnitur', tip: 'Kayu kokoh dapat dipelitur ulang atau digunakan adik tingkat kos.'),
    GameItem(name: 'Novel / Modul Kuliah', icon: '📚', category: 'Buku', tip: 'Mewariskan buku kuliah menghemat biaya jutaan rupiah bagi mahasiswa baru.'),
    GameItem(name: 'Jaket Hoodie Tebal', icon: '🧥', category: 'Pakaian', tip: 'Pakaian layak pakai memperpanjang siklus serat tekstil dan mengurangi emisi garmen.'),
    GameItem(name: 'Rak Sepatu Susun', icon: '👟', category: 'Perlengkapan', tip: 'Bahan plastik keras awet bertahun-tahun jika dirawat dengan baik.'),
    GameItem(name: 'Monitor PC Bekas', icon: '🖥️', category: 'Elektronik', tip: 'Limbah elektronik bernilai tinggi dan harus dihindarkan dari tempat pembuangan sampah.'),
    GameItem(name: 'Sofa Minimalis 2 Seater', icon: '🛋️', category: 'Furnitur', tip: 'Furnitur bekas layak pakai adalah primadona bagi penghuni kos mandiri.'),
    GameItem(name: 'Panci & Wajan Masak', icon: '🍳', category: 'Perlengkapan', tip: 'Peralatan masak aluminium/besi dapat dihibahkan saat lulus kuliah.'),
    GameItem(name: 'Kemeja Flanel Kotak', icon: '👔', category: 'Pakaian', tip: 'Tren thrifting dan berbagi pakaian membantu mengurangi polusi air industri tekstil.'),
    GameItem(name: 'Kamus Bahasa Inggris', icon: '📖', category: 'Buku', tip: 'Referensi fisik sangat berharga untuk perpustakaan mini komunitas.'),
  ];

  static const List<String> _categories = [
    'Furnitur',
    'Elektronik',
    'Buku',
    'Pakaian',
    'Perlengkapan',
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _streak = 0;
  int _timeLeft = 35;
  Timer? _timer;
  bool _isPlaying = false;
  bool _isGameOver = false;
  String? _feedbackMessage;
  bool _lastAnswerCorrect = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _correctCount = 0;
      _streak = 0;
      _currentIndex = 0;
      _timeLeft = 35;
      _feedbackMessage = null;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _checkAnswer(String selectedCategory) {
    if (!_isPlaying || _isGameOver) return;

    final currentItem = _allItems[_currentIndex % _allItems.length];
    final isCorrect = selectedCategory == currentItem.category;

    setState(() {
      _lastAnswerCorrect = isCorrect;
      if (isCorrect) {
        _streak++;
        final multiplier = _streak > 2 ? 150 : 100;
        _score += multiplier;
        _correctCount++;
        _feedbackMessage = 'Benar! +$multiplier Poin ✨\n${currentItem.tip}';
      } else {
        _streak = 0;
        _feedbackMessage = 'Kurang tepat! Barang ini masuk kategori "${currentItem.category}".';
      }

      if (_currentIndex < _allItems.length - 1) {
        _currentIndex++;
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _allItems[_currentIndex % _allItems.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mini Game: Pilah Barang'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: !_isPlaying && !_isGameOver
              ? _buildStartScreen()
              : _isGameOver
                  ? _buildGameOverScreen()
                  : _buildGamePlayScreen(currentItem),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryLight, width: 2),
          ),
          child: const Text('♻️', style: TextStyle(fontSize: 64)),
        ),
        const SizedBox(height: 28),
        const Text(
          'Game Edukatif: Pilah Barang',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        const Text(
          'Kelompokkan barang bekas yang muncul ke dalam kategori yang tepat secepat mungkin sebelum waktu habis!\n\nPermainan ini mengasah pemahaman pemilahan barang dan gaya hidup circular economy.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 36),
        CustomButton(
          text: 'Mulai Permainan (35 Detik)',
          icon: Icons.play_arrow_rounded,
          onPressed: _startGame,
        ),
      ],
    );
  }

  Widget _buildGamePlayScreen(GameItem currentItem) {
    return Column(
      children: [
        // Top stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.error, size: 18),
                  const SizedBox(width: 6),
                  Text('$_timeLeft dtk', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.error)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text('Skor: $_score', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryDark)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Item Card to Sort
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(currentItem.icon, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                Text(
                  currentItem.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Soal ${_currentIndex + 1} dari ${_allItems.length}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                if (_feedbackMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _lastAnswerCorrect ? AppColors.freeBadgeBg : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _feedbackMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: _lastAnswerCorrect ? AppColors.freeBadge : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Category Choice Buttons
        const Text('Pilih Kategori Wadah:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _categories.map((cat) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _checkAnswer(cat),
              child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildGameOverScreen() {
    final accuracy = (_correctCount / _allItems.length * 100).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Text('🏆', style: TextStyle(fontSize: 60)),
        ),
        const SizedBox(height: 20),
        const Text(
          'Permainan Selesai!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Total Skor Anda: $_score Poin',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          'Akurasi Pemilahan: $accuracy% ($_correctCount/${_allItems.length} Benar)',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Text(
                '💡 Pesan Edukatif',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                'Dengan memilah dan menyalurkan barang bekas layak pakai ke orang yang tepat melalui jadiGuna, Anda telah berkontribusi langsung mengurangi timbulan sampah dan memperpanjang masa guna barang!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        CustomButton(
          text: 'Main Lagi',
          icon: Icons.replay_rounded,
          onPressed: _startGame,
        ),
      ],
    );
  }
}
