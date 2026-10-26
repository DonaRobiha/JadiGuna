import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Eco Rush — mini game pemilahan barang JadiGuna.
/// Ganti isi pilah_barang_game_screen.dart dengan file ini.
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

class EcoRushLevel {
  final int id;
  final String name;
  final String world;
  final int duration;
  final int targetScore;
  final int targetItems;
  final int minAccuracy;
  final String mission;
  final String reward;
  final Color color;

  const EcoRushLevel({
    required this.id,
    required this.name,
    required this.world,
    required this.duration,
    required this.targetScore,
    required this.targetItems,
    required this.minAccuracy,
    required this.mission,
    required this.reward,
    required this.color,
  });
}

class PilahBarangGameScreen extends StatefulWidget {
  const PilahBarangGameScreen({super.key});

  @override
  State<PilahBarangGameScreen> createState() => _PilahBarangGameScreenState();
}

class _PilahBarangGameScreenState extends State<PilahBarangGameScreen>
    with TickerProviderStateMixin {
  static const List<String> _categories = [
    'Furnitur',
    'Elektronik',
    'Buku',
    'Pakaian',
    'Perlengkapan',
  ];

  static const List<GameItem> _allItems = [
    GameItem(
      name: 'Kipas Angin Berdiri',
      icon: '🌀',
      category: 'Elektronik',
      tip: 'Kipas yang rusak bisa diperbaiki; komponen elektronik perlu disalurkan dengan benar.',
    ),
    GameItem(
      name: 'Meja Belajar Kayu',
      icon: '🪑',
      category: 'Furnitur',
      tip: 'Meja kokoh dapat digunakan kembali atau disumbangkan.',
    ),
    GameItem(
      name: 'Novel / Modul Kuliah',
      icon: '📚',
      category: 'Buku',
      tip:
          'Buku layak baca dapat diwariskan atau disumbangkan ke perpustakaan.',
    ),
    GameItem(
      name: 'Jaket Hoodie Tebal',
      icon: '🧥',
      category: 'Pakaian',
      tip: 'Pakaian layak pakai dapat dijual kembali atau disumbangkan.',
    ),
    GameItem(
      name: 'Rak Sepatu Susun',
      icon: '👟',
      category: 'Perlengkapan',
      tip: 'Rawat dan gunakan kembali perlengkapan sebelum membuangnya.',
    ),
    GameItem(
      name: 'Monitor PC Bekas',
      icon: '🖥️',
      category: 'Elektronik',
      tip: 'Elektronik bekas sebaiknya diserahkan ke pengelola limbah elektronik.',
    ),
    GameItem(
      name: 'Sofa Minimalis',
      icon: '🛋️',
      category: 'Furnitur',
      tip: 'Sofa yang masih layak bisa diperbaiki, dijual, atau diberikan kepada orang lain.',
    ),
    GameItem(
      name: 'Panci dan Wajan',
      icon: '🍳',
      category: 'Perlengkapan',
      tip: 'Peralatan masak yang masih bagus dapat dihibahkan.',
    ),
    GameItem(
      name: 'Kemeja Flanel',
      icon: '👔',
      category: 'Pakaian',
      tip: 'Berbagi pakaian membantu memperpanjang masa guna tekstil.',
    ),
    GameItem(
      name: 'Kamus Bahasa Inggris',
      icon: '📖',
      category: 'Buku',
      tip: 'Buku referensi dapat dimanfaatkan oleh pelajar lain.',
    ),
    GameItem(
      name: 'Lampu Meja',
      icon: '💡',
      category: 'Elektronik',
      tip: 'Periksa apakah lampu bisa diperbaiki sebelum menggantinya.',
    ),
    GameItem(
      name: 'Kursi Belajar',
      icon: '💺',
      category: 'Furnitur',
      tip: 'Kursi dapat diperbaiki atau digunakan kembali.',
    ),
    GameItem(
      name: 'Tas Sekolah',
      icon: '🎒',
      category: 'Pakaian',
      tip: 'Tas yang masih layak dapat digunakan kembali atau disumbangkan.',
    ),
    GameItem(
      name: 'Kotak Perkakas',
      icon: '🧰',
      category: 'Perlengkapan',
      tip: 'Perkakas yang masih berfungsi berguna untuk banyak orang.',
    ),
    GameItem(
      name: 'Buku Catatan',
      icon: '📒',
      category: 'Buku',
      tip: 'Manfaatkan halaman kosong sebelum mendaur ulang kertasnya.',
    ),
    GameItem(
      name: 'Keyboard Komputer',
      icon: '⌨️',
      category: 'Elektronik',
      tip: 'Aksesori komputer yang tidak terpakai bisa diperbaiki atau disalurkan sebagai e-waste.',
    ),
    GameItem(
      name: 'Lemari Pakaian',
      icon: '🚪',
      category: 'Furnitur',
      tip: 'Lemari bekas dapat dipakai ulang setelah dibersihkan atau diperbaiki.',
    ),
    GameItem(
      name: 'Sepatu Olahraga',
      icon: '👟',
      category: 'Pakaian',
      tip: 'Sepatu yang masih layak dapat diberikan kepada orang yang membutuhkan.',
    ),
    GameItem(
      name: 'Panci Penyimpanan',
      icon: '🥣',
      category: 'Perlengkapan',
      tip: 'Wadah yang masih bagus dapat digunakan ulang.',
    ),
    GameItem(
      name: 'Ensiklopedia',
      icon: '📕',
      category: 'Buku',
      tip: 'Buku referensi lama tetap bisa bermanfaat bagi pembaca lain.',
    ),
  ];

  // Setiap dunia memiliki kumpulan barang berbeda agar pertanyaannya tidak berulang.
  static const Map<int, List<GameItem>> _itemsByLevel = {
    1: [
      GameItem(
        name: 'Meja Belajar Kayu',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Meja yang masih kokoh bisa digunakan kembali atau disumbangkan.',
      ),
      GameItem(
        name: 'Kipas Angin Berdiri',
        icon: '🌀',
        category: 'Elektronik',
        tip: 'Kipas rusak bisa diperbaiki sebelum memutuskan menggantinya.',
      ),
      GameItem(
        name: 'Novel Bekas',
        icon: '📚',
        category: 'Buku',
        tip: 'Novel layak baca bisa diberikan kepada pembaca lain.',
      ),
      GameItem(
        name: 'Jaket Hoodie',
        icon: '🧥',
        category: 'Pakaian',
        tip: 'Pakaian layak pakai bisa disumbangkan.',
      ),
      GameItem(
        name: 'Rak Sepatu',
        icon: '👟',
        category: 'Perlengkapan',
        tip: 'Perlengkapan yang masih berfungsi dapat dipakai kembali.',
      ),
      GameItem(
        name: 'Sofa Minimalis',
        icon: '🛋️',
        category: 'Furnitur',
        tip: 'Sofa bekas bisa diperbaiki atau dijual kembali.',
      ),
      GameItem(
        name: 'Lampu Meja',
        icon: '💡',
        category: 'Elektronik',
        tip: 'Periksa apakah lampu bisa diperbaiki.',
      ),
      GameItem(
        name: 'Kamus Lama',
        icon: '📖',
        category: 'Buku',
        tip: 'Kamus masih berguna untuk belajar atau bisa disumbangkan.',
      ),
      GameItem(
        name: 'Kemeja Flanel',
        icon: '👔',
        category: 'Pakaian',
        tip: 'Pakaian yang masih bagus dapat diwariskan.',
      ),
      GameItem(
        name: 'Kotak Perkakas',
        icon: '🧰',
        category: 'Perlengkapan',
        tip: 'Perkakas yang berfungsi bisa membantu orang lain.',
      ),
      GameItem(
        name: 'Kursi Kayu',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Kursi bisa diperbaiki jika ada bagian yang longgar.',
      ),
      GameItem(
        name: 'Buku Catatan',
        icon: '📒',
        category: 'Buku',
        tip: 'Gunakan halaman kosong sebelum mendaur ulang kertasnya.',
      ),
    ],
    2: [
      GameItem(
        name: 'Tas Sekolah',
        icon: '🎒',
        category: 'Pakaian',
        tip: 'Tas yang masih layak bisa dipakai adik kelas atau disumbangkan.',
      ),
      GameItem(
        name: 'Laptop Rusak',
        icon: '💻',
        category: 'Elektronik',
        tip: 'Laptop rusak perlu diperbaiki atau diserahkan ke pengelola e-waste.',
      ),
      GameItem(
        name: 'Buku Pelajaran',
        icon: '📚',
        category: 'Buku',
        tip: 'Buku pelajaran bekas dapat diwariskan ke siswa lain.',
      ),
      GameItem(
        name: 'Meja Kelas',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Meja kelas bisa diperbaiki agar dapat digunakan lagi.',
      ),
      GameItem(
        name: 'Seragam Sekolah',
        icon: '👕',
        category: 'Pakaian',
        tip: 'Seragam yang masih bagus bisa diberikan kepada siswa lain.',
      ),
      GameItem(
        name: 'Kalkulator',
        icon: '🧮',
        category: 'Elektronik',
        tip: 'Periksa baterai dan kondisi kalkulator sebelum membuangnya.',
      ),
      GameItem(
        name: 'Pensil dan Penghapus',
        icon: '✏️',
        category: 'Perlengkapan',
        tip: 'Alat tulis yang masih bisa digunakan tidak perlu dibuang.',
      ),
      GameItem(
        name: 'Rak Perpustakaan',
        icon: '🗄️',
        category: 'Furnitur',
        tip: 'Rak bisa diperbaiki atau dipakai ulang.',
      ),
      GameItem(
        name: 'Modul Praktikum',
        icon: '📒',
        category: 'Buku',
        tip: 'Kertas yang masih kosong dapat digunakan kembali.',
      ),
      GameItem(
        name: 'Proyektor Rusak',
        icon: '📽️',
        category: 'Elektronik',
        tip: 'Perangkat elektronik perlu diperiksa atau disalurkan ke pengelola khusus.',
      ),
      GameItem(
        name: 'Sepatu Olahraga',
        icon: '👟',
        category: 'Pakaian',
        tip: 'Sepatu layak pakai dapat disumbangkan.',
      ),
      GameItem(
        name: 'Kotak Pensil',
        icon: '🧰',
        category: 'Perlengkapan',
        tip: 'Kotak pensil yang masih bagus bisa dipakai lagi.',
      ),
      GameItem(
        name: 'Lemari Kelas',
        icon: '🚪',
        category: 'Furnitur',
        tip: 'Lemari dapat diperbaiki daripada langsung diganti.',
      ),
      GameItem(
        name: 'Mouse Komputer',
        icon: '🖱️',
        category: 'Elektronik',
        tip: 'Aksesori elektronik rusak sebaiknya dikelola dengan benar.',
      ),
    ],
    3: [
      GameItem(
        name: 'Keranjang Belanja',
        icon: '🧺',
        category: 'Perlengkapan',
        tip: 'Keranjang bisa dipakai berulang kali untuk mengurangi sampah.',
      ),
      GameItem(
        name: 'Buku Resep',
        icon: '📕',
        category: 'Buku',
        tip: 'Buku resep yang masih baik bisa diberikan ke orang lain.',
      ),
      GameItem(
        name: 'Kulkas Bekas',
        icon: '🧊',
        category: 'Elektronik',
        tip: 'Kulkas bekas perlu diperiksa dan ditangani dengan aman.',
      ),
      GameItem(
        name: 'Meja Kasir',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Meja dapat digunakan ulang di toko atau tempat lain.',
      ),
      GameItem(
        name: 'Apron Kain',
        icon: '👕',
        category: 'Pakaian',
        tip: 'Apron yang masih layak dapat digunakan kembali.',
      ),
      GameItem(
        name: 'Timbangan Digital',
        icon: '⚖️',
        category: 'Elektronik',
        tip: 'Elektronik rusak jangan dicampur dengan sampah biasa.',
      ),
      GameItem(
        name: 'Kardus Bersih',
        icon: '📦',
        category: 'Perlengkapan',
        tip: 'Kardus bersih bisa digunakan ulang atau didaur ulang.',
      ),
      GameItem(
        name: 'Rak Dagangan',
        icon: '🗄️',
        category: 'Furnitur',
        tip: 'Rak yang kokoh bisa digunakan oleh pedagang lain.',
      ),
      GameItem(
        name: 'Buku Kas',
        icon: '📒',
        category: 'Buku',
        tip: 'Manfaatkan halaman kosong jika masih memungkinkan.',
      ),
      GameItem(
        name: 'Jaket Kurir',
        icon: '🧥',
        category: 'Pakaian',
        tip: 'Tekstil layak pakai dapat digunakan ulang.',
      ),
      GameItem(
        name: 'Mesin Pembuat Kopi',
        icon: '☕',
        category: 'Elektronik',
        tip: 'Coba perbaiki alat sebelum menggantinya.',
      ),
      GameItem(
        name: 'Troli Lipat',
        icon: '🛒',
        category: 'Perlengkapan',
        tip: 'Troli yang berfungsi dapat digunakan berkali-kali.',
      ),
      GameItem(
        name: 'Kursi Warung',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Kursi bekas bisa diperbaiki dan dipakai lagi.',
      ),
      GameItem(
        name: 'Buku Stok Barang',
        icon: '📚',
        category: 'Buku',
        tip: 'Kertas bekas dapat didaur ulang setelah data penting diamankan.',
      ),
      GameItem(
        name: 'Sarung Tangan Kain',
        icon: '🧤',
        category: 'Pakaian',
        tip: 'Tekstil yang masih layak bisa digunakan kembali.',
      ),
      GameItem(
        name: 'Pemindai Barcode',
        icon: '📟',
        category: 'Elektronik',
        tip: 'Perangkat elektronik perlu disalurkan ke jalur yang sesuai.',
      ),
    ],
    4: [
      GameItem(
        name: 'Lemari Besi',
        icon: '🗄️',
        category: 'Furnitur',
        tip: 'Lemari dapat digunakan ulang atau disalurkan ke tempat reparasi.',
      ),
      GameItem(
        name: 'Ponsel Rusak',
        icon: '📱',
        category: 'Elektronik',
        tip: 'Ponsel termasuk limbah elektronik; serahkan ke pengumpul tepercaya.',
      ),
      GameItem(
        name: 'Ensiklopedia',
        icon: '📚',
        category: 'Buku',
        tip: 'Ensiklopedia masih dapat bermanfaat bagi sekolah atau perpustakaan.',
      ),
      GameItem(
        name: 'Jas Hujan',
        icon: '🧥',
        category: 'Pakaian',
        tip: 'Jas hujan yang masih baik dapat dipakai ulang.',
      ),
      GameItem(
        name: 'Peralatan Perbaikan',
        icon: '🧰',
        category: 'Perlengkapan',
        tip: 'Perkakas dapat dirawat dan digunakan dalam waktu lama.',
      ),
      GameItem(
        name: 'Printer Bekas',
        icon: '🖨️',
        category: 'Elektronik',
        tip: 'Printer bisa diperbaiki atau dibawa ke pengelola e-waste.',
      ),
      GameItem(
        name: 'Sofa Kantor',
        icon: '🛋️',
        category: 'Furnitur',
        tip: 'Sofa dapat diperbaiki atau disumbangkan jika masih layak.',
      ),
      GameItem(
        name: 'Buku Arsip',
        icon: '📒',
        category: 'Buku',
        tip: 'Pastikan data rahasia diamankan sebelum kertas didaur ulang.',
      ),
      GameItem(
        name: 'Seragam Kerja',
        icon: '👕',
        category: 'Pakaian',
        tip: 'Seragam layak pakai dapat digunakan ulang sesuai kebutuhan.',
      ),
      GameItem(
        name: 'Baterai Bekas',
        icon: '🔋',
        category: 'Elektronik',
        tip: 'Baterai bekas perlu dikumpulkan terpisah di titik pengumpulan khusus.',
      ),
      GameItem(
        name: 'Meja Kantor',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Meja yang masih kokoh tidak harus dibuang.',
      ),
      GameItem(
        name: 'Tas Perkakas',
        icon: '🧰',
        category: 'Perlengkapan',
        tip: 'Tas perkakas bisa dipakai ulang selama masih berfungsi.',
      ),
      GameItem(
        name: 'Monitor Komputer',
        icon: '🖥️',
        category: 'Elektronik',
        tip: 'Monitor bekas termasuk e-waste dan perlu penanganan khusus.',
      ),
      GameItem(
        name: 'Buku Panduan',
        icon: '📖',
        category: 'Buku',
        tip: 'Panduan lama bisa dibagikan jika masih relevan.',
      ),
      GameItem(
        name: 'Tirai Kain',
        icon: '🪟',
        category: 'Pakaian',
        tip: 'Kain yang masih bagus bisa digunakan kembali atau diubah fungsinya.',
      ),
      GameItem(
        name: 'Rak Besi',
        icon: '🗄️',
        category: 'Furnitur',
        tip: 'Rak bisa dipakai ulang atau didaur ulang melalui jalur yang tepat.',
      ),
      GameItem(
        name: 'Kabel Charger',
        icon: '🔌',
        category: 'Elektronik',
        tip: 'Kabel elektronik bekas jangan dibuang sembarangan.',
      ),
      GameItem(
        name: 'Kotak Penyimpanan',
        icon: '📦',
        category: 'Perlengkapan',
        tip: 'Kotak yang masih bagus dapat dipakai berulang kali.',
      ),
    ],
    5: [
      GameItem(
        name: 'Kipas Angin Rusak',
        icon: '🌀',
        category: 'Elektronik',
        tip: 'Tentukan kategori dengan cepat, lalu ingat bahwa elektronik rusak perlu jalur khusus.',
      ),
      GameItem(
        name: 'Kursi Patah',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Perabot bisa diperbaiki sebelum diputuskan untuk dibuang.',
      ),
      GameItem(
        name: 'Buku Basah',
        icon: '📚',
        category: 'Buku',
        tip: 'Jika masih bisa diselamatkan, keringkan dan gunakan kembali.',
      ),
      GameItem(
        name: 'Seragam Lama',
        icon: '👕',
        category: 'Pakaian',
        tip: 'Pakaian layak pakai bisa disumbangkan atau dimanfaatkan ulang.',
      ),
      GameItem(
        name: 'Kotak Perkakas',
        icon: '🧰',
        category: 'Perlengkapan',
        tip: 'Perlengkapan yang berfungsi dapat digunakan berulang kali.',
      ),
      GameItem(
        name: 'Tablet Rusak',
        icon: '📱',
        category: 'Elektronik',
        tip: 'Tablet termasuk e-waste dan perlu pengelolaan yang tepat.',
      ),
      GameItem(
        name: 'Lemari Bekas',
        icon: '🚪',
        category: 'Furnitur',
        tip: 'Lemari dapat dijual, disumbangkan, atau diperbaiki.',
      ),
      GameItem(
        name: 'Komik Lama',
        icon: '📖',
        category: 'Buku',
        tip: 'Komik layak baca dapat diberikan ke pembaca lain.',
      ),
      GameItem(
        name: 'Sepatu Bekas',
        icon: '👟',
        category: 'Pakaian',
        tip: 'Sepatu yang masih layak dapat digunakan kembali.',
      ),
      GameItem(
        name: 'Lampu LED Rusak',
        icon: '💡',
        category: 'Elektronik',
        tip: 'Cari jalur pengumpulan limbah elektronik yang sesuai.',
      ),
      GameItem(
        name: 'Meja Lipat',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Meja lipat bisa digunakan ulang jika masih aman.',
      ),
      GameItem(
        name: 'Buku Ensiklopedia',
        icon: '📕',
        category: 'Buku',
        tip: 'Buku referensi bisa disumbangkan ke perpustakaan.',
      ),
      GameItem(
        name: 'Jaket Tebal',
        icon: '🧥',
        category: 'Pakaian',
        tip: 'Jaket layak pakai bisa bermanfaat bagi orang lain.',
      ),
      GameItem(
        name: 'Baterai Laptop',
        icon: '🔋',
        category: 'Elektronik',
        tip: 'Baterai perlu dikumpulkan terpisah, bukan ke sampah campuran.',
      ),
      GameItem(
        name: 'Rak Serbaguna',
        icon: '🗄️',
        category: 'Furnitur',
        tip: 'Rak yang kokoh bisa dipakai di ruang lain.',
      ),
      GameItem(
        name: 'Tas Perjalanan',
        icon: '🎒',
        category: 'Pakaian',
        tip: 'Tas layak pakai dapat diwariskan atau disumbangkan.',
      ),
      GameItem(
        name: 'Keyboard Bekas',
        icon: '⌨️',
        category: 'Elektronik',
        tip: 'Aksesori komputer bekas sebaiknya masuk jalur e-waste.',
      ),
      GameItem(
        name: 'Buku Catatan',
        icon: '📒',
        category: 'Buku',
        tip: 'Gunakan sisa halaman sebelum mendaur ulang kertas.',
      ),
      GameItem(
        name: 'Meja Kerja',
        icon: '🪑',
        category: 'Furnitur',
        tip: 'Perabot dapat diperbaiki atau digunakan ulang.',
      ),
      GameItem(
        name: 'Peralatan Kebun',
        icon: '🧰',
        category: 'Perlengkapan',
        tip: 'Rawat perkakas agar masa pakainya lebih panjang.',
      ),
    ],
  };

  List<GameItem> _itemsForLevel(int levelId) =>
      _itemsByLevel[levelId] ?? _allItems;

  static const List<EcoRushLevel> _levels = [
    EcoRushLevel(
      id: 1,
      name: 'Rumah Hijau',
      world: 'Dunia 1',
      duration: 40,
      targetScore: 700,
      targetItems: 10,
      minAccuracy: 70,
      mission: 'Pilah 10 barang dengan akurasi minimal 70%.',
      reward: 'Topi Daun 🌿',
      color: Color(0xFF62C370),
    ),
    EcoRushLevel(
      id: 2,
      name: 'Sekolah Bersih',
      world: 'Dunia 2',
      duration: 40,
      targetScore: 1100,
      targetItems: 14,
      minAccuracy: 80,
      mission: 'Pilah 14 barang dengan akurasi minimal 80%.',
      reward: 'Efek Combo Bintang ⭐',
      color: Color(0xFF54B8F0),
    ),
    EcoRushLevel(
      id: 3,
      name: 'Pasar Daur Ulang',
      world: 'Dunia 3',
      duration: 35,
      targetScore: 1500,
      targetItems: 18,
      minAccuracy: 85,
      mission: 'Pilah 18 barang dengan akurasi minimal 85%.',
      reward: 'Tema Arena Pelangi 🌈',
      color: Color(0xFFFFB547),
    ),
    EcoRushLevel(
      id: 4,
      name: 'Kota Eco',
      world: 'Dunia 4',
      duration: 35,
      targetScore: 1900,
      targetItems: 22,
      minAccuracy: 90,
      mission: 'Pilah 22 barang dengan akurasi minimal 90%.',
      reward: 'Kostum Eco Hero 🦸',
      color: Color(0xFF9B7BEA),
    ),
    EcoRushLevel(
      id: 5,
      name: 'Eco Champion',
      world: 'Final',
      duration: 30,
      targetScore: 2300,
      targetItems: 25,
      minAccuracy: 90,
      mission: 'Raih skor tinggi sebelum waktu habis!',
      reward: 'Piala Eco Champion 🏆',
      color: Color(0xFFFF7B79),
    ),
  ];

  final Random _random = Random();

  Timer? _timer;
  late final AnimationController _itemAnimationController;

  int _selectedLevelIndex = 0;
  int _unlockedLevel = 1;
  int _timeLeft = 40;
  int _score = 0;
  int _correctCount = 0;
  int _answeredCount = 0;
  int _streak = 0;
  int _bestCombo = 0;
  int _lives = 3;
  int _currentIndex = 0;
  int _starsEarned = 0;
  int _bestScore = 0;

  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _lastAnswerCorrect = false;
  bool _levelPassed = false;
  bool _isLoadingProgress = true;
  String? _feedbackMessage;
  List<GameItem> _roundItems = [];

  EcoRushLevel get _level => _levels[_selectedLevelIndex];
  GameItem get _currentItem => _roundItems[_currentIndex];

  @override
  void initState() {
    super.initState();
    _itemAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _loadProgress();
    _loadStars();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _itemAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _unlockedLevel = (prefs.getInt('eco_rush_unlocked_level') ?? 1)
            .clamp(1, _levels.length)
            .toInt();
        _bestScore = prefs.getInt('eco_rush_best_score') ?? 0;
        _isLoadingProgress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProgress = false);
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('eco_rush_unlocked_level', _unlockedLevel);
      await prefs.setInt('eco_rush_best_score', _bestScore);
      for (var i = 0; i < _levels.length; i++) {
        await prefs.setInt(
          'eco_rush_level_${i + 1}_stars',
          i == _selectedLevelIndex
              ? max(
                  _starsEarned,
                  prefs.getInt('eco_rush_level_${i + 1}_stars') ?? 0,
                )
              : (prefs.getInt('eco_rush_level_${i + 1}_stars') ?? 0),
        );
      }
    } catch (_) {
      // Game tetap bisa dimainkan jika penyimpanan lokal tidak tersedia.
    }
  }

  int _savedStars(int levelId) {
    // Nilai diambil asynchronous saat memuat peta; untuk tampilan, cache lokal
    // sederhana diambil dari SharedPreferences saat widget dibangun tidak diperlukan.
    return _starsByLevel[levelId] ?? 0;
  }

  final Map<int, int> _starsByLevel = {};

  Future<void> _loadStars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        for (final level in _levels) {
          _starsByLevel[level.id] =
              prefs.getInt('eco_rush_level_${level.id}_stars') ?? 0;
        }
      });
    } catch (_) {}
  }

  void _openLevel(int index) {
    if (index + 1 > _unlockedLevel) return;
    setState(() {
      _selectedLevelIndex = index;
      _isPlaying = false;
      _isGameOver = false;
      _feedbackMessage = null;
    });
  }

  void _startGame() {
    _timer?.cancel();
    final items = List<GameItem>.from(_itemsForLevel(_selectedLevelIndex + 1))
      ..shuffle(_random);

    setState(() {
      _roundItems = items;
      _currentIndex = 0;
      _timeLeft = _level.duration;
      _score = 0;
      _correctCount = 0;
      _answeredCount = 0;
      _streak = 0;
      _bestCombo = 0;
      _lives = 3;
      _starsEarned = 0;
      _feedbackMessage = null;
      _lastAnswerCorrect = false;
      _isPlaying = true;
      _isGameOver = false;
      _levelPassed = false;
    });
    _itemAnimationController.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isPlaying || _isGameOver) {
        timer.cancel();
        return;
      }
      if (_timeLeft <= 1) {
        setState(() => _timeLeft = 0);
        _endGame();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _checkAnswer(String selectedCategory) {
    if (!_isPlaying || _isGameOver || _roundItems.isEmpty) return;

    final item = _currentItem;
    final isCorrect = selectedCategory == item.category;

    setState(() {
      _answeredCount++;
      _lastAnswerCorrect = isCorrect;

      if (isCorrect) {
        // Hitung jawaban benar agar akurasi dan syarat membuka level berfungsi.
        _correctCount++;
        _streak++;
        _bestCombo = max(_bestCombo, _streak);
        final bonus = _streak >= 8
            ? 100
            : _streak >= 5
            ? 50
            : _streak >= 3
            ? 25
            : 0;
        final points = 100 + bonus;
        _score += points;
        _feedbackMessage = _streak >= 3
            ? 'COMBO x$_streak! +$points ✨\n${item.tip}'
            : 'Benar! +$points poin\n${item.tip}';
      } else {
        _streak = 0;
        _lives--;
        _feedbackMessage =
            'Oops! -1 nyawa\nKategori yang tepat: ${item.category}';
      }

      _currentIndex = (_currentIndex + 1) % _roundItems.length;
    });

    _itemAnimationController.forward(from: 0);

    if (_lives <= 0) {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    if (_isGameOver) return;
    _timer?.cancel();

    final accuracy = _answeredCount == 0
        ? 0
        : (_correctCount * 100 / _answeredCount).round();
    final passed =
        _correctCount >= _level.targetItems &&
        _score >= _level.targetScore &&
        accuracy >= _level.minAccuracy;

    int stars = 0;
    if (_correctCount >= _level.targetItems) stars = 1;
    if (_score >= _level.targetScore && accuracy >= _level.minAccuracy) {
      stars = max(stars, 2);
    }
    if (_score >= (_level.targetScore * 1.35).round() &&
        accuracy >= 95 &&
        _bestCombo >= 5) {
      stars = 3;
    }

    setState(() {
      _isPlaying = false;
      _isGameOver = true;
      _levelPassed = passed || stars >= 1;
      _starsEarned = stars;
      _bestScore = max(_bestScore, _score);
      if (_levelPassed && _selectedLevelIndex + 2 > _unlockedLevel) {
        _unlockedLevel = min(_levels.length, _selectedLevelIndex + 2);
      }
    });

    await _saveProgress();
    await _loadStars();
  }

  int get _accuracy =>
      _answeredCount == 0 ? 0 : (_correctCount * 100 / _answeredCount).round();

  void _backToMap() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = false;
      _feedbackMessage = null;
    });
    _loadStars();
  }

  String _worldEmoji(int id) =>
      const {1: '🏡', 2: '🎒', 3: '♻️', 4: '🌆', 5: '🏆'}[id] ?? '🌿';

  String _worldMechanic(int id) =>
      const {
        1: 'MISI: Kenali barang rumah dan pilah dengan tepat',
        2: 'TANTANGAN: Jaga akurasi saat barang sekolah berdatangan',
        3: 'COMBO: Jawaban benar beruntun memberi bonus poin',
        4: 'MODE CEPAT: Waktu lebih singkat, tetap jaga nyawa',
        5: 'FINAL RUSH: Campuran barang dari semua dunia',
      }[id] ??
      'Pilah barang dan kumpulkan poin!';

  List<Color> _worldGradient(int id) =>
      const {
        1: [Color(0xFFE4F9D5), Color(0xFFB5E8A0)],
        2: [Color(0xFFDFF2FF), Color(0xFFA5D9FA)],
        3: [Color(0xFFFFE8C7), Color(0xFFFFC979)],
        4: [Color(0xFFDCDFFF), Color(0xFFA9B2FF)],
        5: [Color(0xFFFFD8E8), Color(0xFFFFA7C9)],
      }[id] ??
      [Color(0xFFE4F9D5), Color(0xFFB5E8A0)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isPlaying
          ? _worldGradient(_level.id).first
          : const Color(0xFFFFF9E9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFF9E9),
        foregroundColor: const Color(0xFF214A36),
        title: const Text(
          'ECO RUSH!',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Peta level',
            onPressed: _isPlaying ? null : _backToMap,
            icon: const Icon(Icons.map_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingProgress
            ? const Center(child: CircularProgressIndicator())
            : _isPlaying
            ? _buildGameScreen()
            : _isGameOver
            ? _buildResultScreen()
            : _buildLevelScreen(),
      ),
    );
  }

  Widget _buildLevelScreen() {
    return RefreshIndicator(
      onRefresh: _loadStars,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB7F29B), Color(0xFF6ED7A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A9D69).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌎  MISI SELAMATKAN BUMI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF20563B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jadi Eco Hero!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF174A32),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilah barang secepat mungkin. Jaga nyawa, bangun combo, dan buka hadiah baru!',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF285B40),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill('🏆 Rekor $_bestScore'),
                    _pill('🔓 Level $_unlockedLevel/${_levels.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'PETA PETUALANGAN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF214A36),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Selesaikan level untuk membuka dunia berikutnya.',
            style: TextStyle(color: Color(0xFF718078), fontSize: 13),
          ),
          const SizedBox(height: 14),
          ..._levels.map((level) {
            final index = level.id - 1;
            final unlocked = level.id <= _unlockedLevel;
            final stars = _savedStars(level.id);
            final selected = index == _selectedLevelIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: unlocked ? () => _openLevel(index) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: unlocked ? Colors.white : const Color(0xFFF0EFE8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? level.color : const Color(0xFFE5E8DC),
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: level.color.withValues(
                            alpha: unlocked ? 0.20 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Text(
                          unlocked ? _worldEmoji(level.id) : '🔒',
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${level.world} • ${level.name}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: unlocked
                                    ? const Color(0xFF214A36)
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unlocked
                                  ? 'Hadiah: ${level.reward}'
                                  : 'Selesaikan level sebelumnya untuk membuka',
                              style: TextStyle(
                                fontSize: 11,
                                color: unlocked
                                    ? const Color(0xFF6B7C71)
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              unlocked
                                  ? '★' * stars + '☆' * (3 - stars)
                                  : 'Level terkunci',
                              style: const TextStyle(
                                color: Color(0xFFFFB629),
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        unlocked
                            ? (selected
                                  ? Icons.check_circle
                                  : Icons.chevron_right)
                            : Icons.lock_outline,
                        color: unlocked ? level.color : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          _buildSelectedLevelCard(),
        ],
      ),
    );
  }

  Widget _buildSelectedLevelCard() {
    final level = _level;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF214A36),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 MISI BERIKUTNYA',
            style: TextStyle(
              color: Color(0xFFB7F29B),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.mission,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${level.duration} detik • 3 nyawa • Hadiah: ${level.reward}',
            style: const TextStyle(color: Color(0xFFD5E7DB), fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_selectedLevelIndex + 1 <= _unlockedLevel) {
                  _startGame();
                }
              },
              icon: const Icon(Icons.bolt_rounded),
              label: Text('MULAI ${level.name.toUpperCase()}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD166),
                foregroundColor: const Color(0xFF4B3A13),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    final item = _currentItem;
    final double timeFraction = (_timeLeft / _level.duration)
        .clamp(0.0, 1.0)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _worldGradient(_level.id),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _level.color.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Text(
                  _worldEmoji(_level.id),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_level.world.toUpperCase()} • ${_level.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF214A36),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _worldMechanic(_level.id),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF426452),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  '⏱️ WAKTU',
                  '$_timeLeft dtk',
                  const Color(0xFFFF7777),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard('⭐ SKOR', '$_score', const Color(0xFFFFC857)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  '🔥 COMBO',
                  'x$_streak',
                  const Color(0xFF69C9A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: timeFraction,
              minHeight: 9,
              backgroundColor: const Color(0xFFE7E8D9),
              color: _timeLeft <= 10
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF65C98A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedScale(
                  scale: index < _lives ? 1 : 0.75,
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    index < _lives ? '❤️' : '🖤',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: _itemAnimationController,
              builder: (context, child) {
                final value = Curves.elasticOut.transform(
                  _itemAnimationController.value.clamp(0.0, 1.0).toDouble(),
                );
                return Transform.scale(
                  scale: 0.82 + (0.18 * value),
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, _worldGradient(_level.id).first],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _level.color, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _level.color.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _level.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_level.world} • ${_level.name}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF285B40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 94,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _worldGradient(_level.id).last
                            .withValues(alpha: 0.42),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 54),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF214A36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Barang ${_answeredCount + 1} • Target ${_level.targetItems}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF718078),
                      ),
                    ),
                    if (_feedbackMessage != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _lastAnswerCorrect
                              ? const Color(0xFFE0F8D9)
                              : const Color(0xFFFFE5E1),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          _feedbackMessage!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: _lastAnswerCorrect
                                ? const Color(0xFF286B3B)
                                : const Color(0xFFB23C35),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'PILIH TEMPAT YANG TEPAT!',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w900,
              color: Color(0xFF627468),
            ),
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              // Tombol dibuat lebih pipih agar tidak overflow di layar pendek.
              childAspectRatio: 2.45,
            ),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return ElevatedButton(
                onPressed: () => _checkAnswer(category),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF214A36),
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: _level.color.withValues(alpha: 0.75),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _categoryEmoji(category),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final passed = _levelPassed;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _level.color, width: 2),
            boxShadow: [
              BoxShadow(
                color: _level.color.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(passed ? '🎉' : '💪', style: const TextStyle(fontSize: 70)),
              const SizedBox(height: 8),
              Text(
                passed ? 'MISI BERHASIL!' : 'COBA LAGI!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF214A36),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _level.name,
                style: const TextStyle(fontSize: 14, color: Color(0xFF718078)),
              ),
              const SizedBox(height: 16),
              Text(
                '★' * _starsEarned + '☆' * (3 - _starsEarned),
                style: const TextStyle(
                  fontSize: 36,
                  letterSpacing: 5,
                  color: Color(0xFFFFB629),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_score POIN',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E9D62),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _resultStat('BENAR', '$_correctCount')),
                  Expanded(child: _resultStat('AKURASI', '$_accuracy%')),
                  Expanded(child: _resultStat('COMBO TERBAIK', 'x$_bestCombo')),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1FFE8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      passed
                          ? '🎁 Hadiah terbuka: ${_level.reward}'
                          : '🎯 Target: ${_level.mission}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF285B40),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Barang yang masih layak bisa digunakan kembali, diperbaiki, dijual, atau disumbangkan sebelum dipertimbangkan untuk dibuang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF627468),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('MAIN LAGI'),
                  style: _primaryButtonStyle(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _backToMap,
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('KEMBALI KE PETA LEVEL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF214A36),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFB8D5C1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF718078),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: Color(0xFF214A36),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF718078),
          ),
        ),
      ],
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF285B40),
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFD166),
      foregroundColor: const Color(0xFF4B3A13),
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'Furnitur':
        return '🪑';
      case 'Elektronik':
        return '🔌';
      case 'Buku':
        return '📚';
      case 'Pakaian':
        return '👕';
      default:
        return '🧰';
    }
  }
}
