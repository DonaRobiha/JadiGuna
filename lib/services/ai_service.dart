import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class AiGenerationResult {
  final String title;
  final String description;
  final String suggestedCategory;
  final List<String> suggestedKeywords;
  final String tips;
  final bool fromLlm;
  final int? estimatedPrice;
  final String? suggestedCondition;

  AiGenerationResult({
    required this.title,
    required this.description,
    required this.suggestedCategory,
    required this.suggestedKeywords,
    required this.tips,
    this.fromLlm = false,
    this.estimatedPrice,
    this.suggestedCondition,
  });
}

class AiService {
  // Key default dari environment bila ada (flutter run --dart-define=GEMINI_API_KEY=xxxx)
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static String? _cachedApiKey;

  // Model Gemini resmi & stabil dengan dukungan multimodal vision
  static const List<String> _geminiModels = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
  ];

  static Future<String?> getApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey;
    }
    if (_envApiKey.isNotEmpty) {
      _cachedApiKey = _envApiKey;
      return _cachedApiKey;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('gemini_api_key');
      if (saved != null && saved.trim().isNotEmpty) {
        _cachedApiKey = saved.trim();
        return _cachedApiKey;
      }
    } catch (e) {
      debugPrint('Gagal membaca saved Gemini API Key: $e');
    }
    return null;
  }

  static Future<void> saveApiKey(String key) async {
    _cachedApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', key.trim());
    } catch (e) {
      debugPrint('Gagal menyimpan Gemini API Key: $e');
    }
  }

  bool get isLlmConfigured =>
      (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) ||
      _envApiKey.isNotEmpty;

  List<String> get _allowedCategories =>
      AppConstants.categories.where((c) => c != 'Semua').toList();

  static String cleanJsonResponse(String raw) {
    var s = raw.trim();
    if (s.startsWith('```json')) {
      s = s.substring(7);
    } else if (s.startsWith('```')) {
      s = s.substring(3);
    }
    if (s.endsWith('```')) {
      s = s.substring(0, s.length - 3);
    }
    return s.trim();
  }

  // ---------------------------------------------------------------
  // Panggilan ke LLM (Gemini) dengan Dukungan Multimodal Vision
  // ---------------------------------------------------------------
  Future<String> _callGemini(
    String prompt, {
    Uint8List? imageBytes,
    bool asJson = false,
    double temperature = 0.4,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key belum dikonfigurasi');
    }

    Exception? lastError;

    for (final model in _geminiModels) {
      try {
        final endpoint =
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

        final parts = <Map<String, dynamic>>[];

        if (imageBytes != null && imageBytes.isNotEmpty) {
          // Deteksi MIME type dari magic bytes
          String mime = 'image/jpeg';
          if (imageBytes.length > 4) {
            if (imageBytes[0] == 0x89 &&
                imageBytes[1] == 0x50 &&
                imageBytes[2] == 0x4E &&
                imageBytes[3] == 0x47) {
              mime = 'image/png';
            } else if (imageBytes[0] == 0x52 &&
                imageBytes[1] == 0x49 &&
                imageBytes[2] == 0x46 &&
                imageBytes[3] == 0x46) {
              mime = 'image/webp';
            }
          }
          parts.add({
            'inline_data': {
              'mime_type': mime,
              'data': base64Encode(imageBytes),
            },
          });
        }

        parts.add({'text': prompt});

        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode({
                'contents': [
                  {'parts': parts},
                ],
                'generationConfig': {
                  'temperature': temperature,
                  if (asJson) 'responseMimeType': 'application/json',
                },
              }),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text is String && text.trim().isNotEmpty) {
            return cleanJsonResponse(text);
          }
        } else {
          lastError = Exception(
            'Gemini ($model) HTTP ${response.statusCode}: ${response.body}',
          );
        }
      } catch (e) {
        lastError = Exception('Gemini ($model) gagal: $e');
      }
    }

    throw lastError ?? Exception('Tidak dapat menghubungi layanan Gemini');
  }

  // ---------------------------------------------------------------
  // 1. Buat Draf Iklan (Multimodal: Teks + Foto)
  // ---------------------------------------------------------------
  Future<AiGenerationResult> generateAdDraft({
    String? title,
    String? rawDetails,
    String? condition,
    bool isFree = false,
    String? category,
    Uint8List? imageBytes,
    String? imagePath,
    Map<String, double>? dimensions,
  }) async {
    final effectiveCondition = condition ?? 'Sangat Baik';
    final effectiveDetails = rawDetails ?? '';
    final effectiveTitle = title?.trim() ?? '';

    final apiKey = await getApiKey();
    final hasLlm = apiKey != null && apiKey.isNotEmpty;

    if (hasLlm) {
      try {
        final prompt =
            '''
Kamu adalah sistem Computer Vision dan AI Kurator profesional untuk marketplace "jadiGuna" (Indonesia).
Tugas utamamu: SCAN FOTO BARANG INI DENGAN SANGAT CERMAT dan buatkan data iklan yang 100% akurat sesuai objek nyata di foto!

WAJIB IKUTI ATURAN BERIKUT:
1. IDENTIFIKASI OBJEK UTAMA DARI FOTO:
   - Kenali apa objek utama yang difoto (misalnya: Sepatu Olahraga/Sneakers, Baju Kemeja Pria, Celana Jeans, Laptop Asus ROG, Monitor LED LG, Kipas Angin Meja, Buku Novel, Helm Motor KYT, Meja Belajar Kayu, Gitar Akustik, Tas Ransel, dll).
   - Tentukan judul yang spesifik, jelas, dan menarik (maksimal 6-8 kata, jangan pernah gunakan judul generik seperti "Barang Bekas").
   - Jika pengguna sudah menuliskan judul awal, sempurnakan judul tersebut agar sinkron dengan foto fisik.

2. KLASIFIKASI KATEGORI RESMI (PILIH PERSIS SALAH SATU DARI: ${_allowedCategories.join(', ')}):
   - "Elektronik": HP, smartphone, tablet, laptop, PC, monitor, TV, kipas angin, rice cooker, blender, dispenser, setrika, headphone, speaker, mouse, keyboard, gadget elektronik.
   - "Furnitur": meja, kursi, lemari pakaian, rak piring, rak buku kayu/besi, sofa, kasur, matras, nakas, bangku, perabot interior.
   - "Buku & Hobi": buku pelajaran, novel, komik, alat musik (gitar, ukulele), raket badminton, bola, perlengkapan olahraga, mainan, konsol game.
   - "Perlengkapan Rumah": pakaian, kaos, kemeja, jaket, celana, sepatu, sandal, tas, ransel, piring, wajan, panci, helm motor, selimut, sprei, peralatan makan/dapur.
   - "Gratis": jika barang ini dinyatakan gratis oleh pemilik.

3. KONDISI & ESTIMASI HARGA:
   - Evaluasi kondisi fisik visual ('Baru / Belum Dipakai', 'Sangat Baik', 'Layak Pakai', atau 'Perlu Servis / Modif').
   - Berikan perkiraan harga pasar wajar barang bekas tersebut dalam Rupiah (angka bulat tanpa titik, contoh: 85000, 150000, 350000). Jika gratis, berikan 0.

4. DESKRIPSI LENGKAP:
   - Tulis deskripsi 3-5 kalimat ramah, jelas, menyebutkan ciri visual yang terlihat (warna, bahan, perkiraan ukuran), dan siap COD di area yang aman.

Data Konteks Pengguna:
- Judul saat ini: ${effectiveTitle.isEmpty ? '(belum ada, tentukan otomatis dari foto)' : effectiveTitle}
- Catatan pengguna: ${effectiveDetails.trim().isEmpty ? '(tidak ada)' : effectiveDetails}
- Kondisi awal: $effectiveCondition
- Jenis penawaran: ${isFree ? 'GRATIS (donasi tanpa biaya)' : 'Dijual'}
- Kategori saat ini: ${category ?? '(belum ditentukan)'}
${dimensions != null ? '- Dimensi terukur: P: ${dimensions['panjang']?.toStringAsFixed(1)} cm × L: ${dimensions['lebar']?.toStringAsFixed(1)} cm × T: ${dimensions['tinggi']?.toStringAsFixed(1)} cm' : ''}

Balas HANYA dengan JSON valid format:
{
  "title": "Nama barang spesifik dan akurat",
  "category": "Elektronik",
  "condition": "Sangat Baik",
  "estimatedPrice": 125000,
  "description": "Deskripsi terstruktur dan informatif...",
  "keywords": ["kata1", "kata2", "kata3"],
  "tips": "Tips menjual barang ini cepat laku"
}
''';

        final raw = await _callGemini(
          prompt,
          imageBytes: imageBytes,
          asJson: true,
          temperature: 0.3,
        );
        final json = jsonDecode(raw) as Map<String, dynamic>;

        final parsedCat = json['category']?.toString() ?? '';
        final finalCat = _allowedCategories.contains(parsedCat)
            ? parsedCat
            : _smartDetectCategory(
                title: json['title']?.toString() ?? effectiveTitle,
                isFree: isFree,
                chosen: category,
                imagePath: imagePath,
              );

        int? estPrice;
        if (json['estimatedPrice'] != null) {
          if (json['estimatedPrice'] is num) {
            estPrice = (json['estimatedPrice'] as num).toInt();
          } else {
            estPrice = int.tryParse(
              json['estimatedPrice'].toString().replaceAll(
                RegExp(r'[^0-9]'),
                '',
              ),
            );
          }
        }

        return AiGenerationResult(
          title: (json['title'] ?? effectiveTitle).toString().trim(),
          description: (json['description'] ?? '').toString().trim(),
          suggestedCategory: finalCat,
          suggestedKeywords: (json['keywords'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
          tips: '✨ Dibuat oleh AI Vision Gemini. ${json['tips'] ?? ''}'.trim(),
          fromLlm: true,
          estimatedPrice: estPrice,
          suggestedCondition: json['condition']?.toString(),
        );
      } catch (e) {
        debugPrint(
          'Panggilan AI LLM Gemini gagal, beralih ke Fallback Cerdas: $e',
        );
      }
    }

    // Fallback Lokal Cerdas: Mendeteksi konteks dari foto, nama file, dimensi, dan judul
    return _smartRuleBasedDraft(
      title: effectiveTitle,
      rawDetails: effectiveDetails,
      condition: effectiveCondition,
      isFree: isFree,
      category: category,
      imagePath: imagePath,
      imageBytes: imageBytes,
      dimensions: dimensions,
    );
  }

  // ---------------------------------------------------------------
  // 2. Saran Kategori Cerdas
  // ---------------------------------------------------------------
  Future<String> suggestCategory(String title, {String? imagePath}) async {
    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final prompt =
            '''
Pilih satu kategori yang paling cocok untuk barang bekas berjudul "$title".
Pilihan resmi: ${_allowedCategories.join(', ')}
Balas HANYA nama kategorinya persis.
''';
        final answer = await _callGemini(prompt, temperature: 0.2);
        final cleaned = answer.replaceAll('"', '').trim();
        if (_allowedCategories.contains(cleaned)) return cleaned;
      } catch (e) {
        debugPrint('AI suggestCategory gagal, pakai fallback: $e');
      }
    }
    return _smartDetectCategory(
      title: title,
      isFree: false,
      imagePath: imagePath,
    );
  }

  // ---------------------------------------------------------------
  // 3. Poles & Rapikan Teks
  // ---------------------------------------------------------------
  Future<String> polishText(String originalText) async {
    final trimmed = originalText.trim();
    if (trimmed.isEmpty) return 'Deskripsi barang belum diisi.';

    final apiKey = await getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final prompt =
            '''
Rapikan deskripsi iklan barang bekas berikut agar lebih jelas, sopan, dan menarik dalam bahasa Indonesia.
Gunakan format terstruktur dan bahasa santun. Balas HANYA teks deskripsinya.

Teks asli:
$trimmed
''';
        return await _callGemini(prompt);
      } catch (e) {
        debugPrint('AI polishText gagal, pakai fallback: $e');
      }
    }

    return '✨ Deskripsi yang Diperjelas oleh AI:\n\n'
        '$trimmed\n\n'
        'Catatan Penjual:\n'
        '• Kondisi barang sesuai foto dan deskripsi yang dicantumkan.\n'
        '• Siap COD / ketemuan di area umum yang disepakati.\n'
        '• Silakan chat untuk bertanya lebih lanjut atau negosiasi!';
  }

  // ===============================================================
  // MESIN HEURISTIK LOKAL CERDAS (Sinkronisasi Foto & Konteks)
  // ===============================================================

  /// Ekstraksi kata kunci nama barang dan kategori dari teks (judul / catatan pengguna)
  Map<String, dynamic> _detectItemFromText(String text) {
    if (text.trim().isEmpty) return {};
    final clean = text.toLowerCase();
    bool has(List<String> words) => words.any(clean.contains);

    if (has([
      'sepatu',
      'sneaker',
      'boots',
      'sandal',
      'pantofel',
      'flatshoes',
      'converse',
      'vans',
      'nike',
      'adidas',
      'ventela',
      'compass',
      'aerostreet',
    ])) {
      return {
        'name': 'Sepatu / Alas Kaki Preloved',
        'category': 'Perlengkapan Rumah',
        'price': 95000,
      };
    }
    if (has([
      'baju',
      'kaos',
      'kemeja',
      'tshirt',
      't shirt',
      'jaket',
      'hoodie',
      'sweater',
      'celana',
      'jeans',
      'gamis',
      'rok',
      'cardigan',
      'vest',
      'outer',
      'flanel',
    ])) {
      return {
        'name': 'Pakaian / Fashion Preloved',
        'category': 'Perlengkapan Rumah',
        'price': 50000,
      };
    }
    if (has([
      'tas',
      'ransel',
      'backpack',
      'tote',
      'slingbag',
      'dompet',
      'koper',
      'waistbag',
    ])) {
      return {
        'name': 'Tas / Ransel Preloved',
        'category': 'Perlengkapan Rumah',
        'price': 75000,
      };
    }
    if (has([
      'laptop',
      'notebook',
      'macbook',
      'asus',
      'lenovo',
      'acer',
      'dell',
      'hp notebook',
      'thinkpad',
      'rog',
    ])) {
      return {
        'name': 'Laptop / Notebook Portabel',
        'category': 'Elektronik',
        'price': 1800000,
      };
    }
    if (has([
      'keyboard',
      'mouse',
      'mousepad',
      'headphone',
      'headset',
      'earphone',
      'tws',
      'airpods',
      'speaker',
      'mic',
      'mikrofon',
    ])) {
      return {
        'name': 'Aksesoris Komputer / Audio',
        'category': 'Elektronik',
        'price': 85000,
      };
    }
    if (has(['monitor', 'layar', 'lcd', 'led', 'tv', 'televisi'])) {
      return {
        'name': 'Monitor PC / Layar TV',
        'category': 'Elektronik',
        'price': 350000,
      };
    }
    if (has([
      'hp',
      'handphone',
      'smartphone',
      'iphone',
      'samsung',
      'xiaomi',
      'oppo',
      'vivo',
      'tablet',
      'ipad',
      'redmi',
      'realme',
      'infinix',
    ])) {
      return {
        'name': 'Smartphone / Gadget',
        'category': 'Elektronik',
        'price': 950000,
      };
    }
    if (has(['kipas', 'fan', 'ac mini', 'exhaust'])) {
      return {
        'name': 'Kipas Angin Elektrik',
        'category': 'Elektronik',
        'price': 95000,
      };
    }
    if (has([
      'rice cooker',
      'magic com',
      'blender',
      'dispenser',
      'setrika',
      'microwave',
      'kompor',
      'panci',
      'wajan',
      'toaster',
      'air fryer',
    ])) {
      return {
        'name': 'Peralatan Rumah Tangga / Dapur',
        'category': 'Perlengkapan Rumah',
        'price': 120000,
      };
    }
    if (has([
      'buku',
      'novel',
      'komik',
      'manga',
      'kamus',
      'modul',
      'diktat',
      'majalah',
      'buku kuliah',
      'ensiklopedia',
    ])) {
      return {
        'name': 'Buku Bacaan / Pelajaran',
        'category': 'Buku & Hobi',
        'price': 35000,
      };
    }
    if (has([
      'gitar',
      'ukulele',
      'piano',
      'organ',
      'raket',
      'badminton',
      'bola',
      'sepeda',
      'skate',
      'boardgame',
      'ps4',
      'ps5',
      'ps3',
      'game',
      'nintendo',
      'stick',
    ])) {
      return {
        'name': 'Peralatan Hobi / Olahraga',
        'category': 'Buku & Hobi',
        'price': 220000,
      };
    }
    if (has([
      'meja',
      'kursi',
      'lemari',
      'wardrobe',
      'sofa',
      'rak',
      'bookshelf',
      'kasur',
      'matras',
      'nakas',
      'laci',
      'dipan',
      'bangku',
    ])) {
      return {
        'name': 'Perabot Furnitur Rumah',
        'category': 'Furnitur',
        'price': 150000,
      };
    }
    if (has([
      'helm',
      'spion',
      'jaket motor',
      'jas hujan',
      'sarung tangan motor',
      'kyt',
      'bogo',
      'ink',
    ])) {
      return {
        'name': 'Perlengkapan Berkendara / Helm',
        'category': 'Perlengkapan Rumah',
        'price': 110000,
      };
    }
    return {};
  }

  /// Ekstraksi kata kunci nama barang dari path / filename foto
  Map<String, dynamic> _detectItemFromPhotoPath(String? path) {
    if (path == null || path.trim().isEmpty) return {};

    final cleanName = path
        .split(RegExp(r'[/\\]'))
        .last
        .toLowerCase()
        .replaceAll(RegExp(r'\.(jpg|jpeg|png|webp|bmp|gif)$'), '')
        .replaceAll(RegExp(r'[-_]'), ' ');

    return _detectItemFromText(cleanName);
  }

  String _smartDetectCategory({
    required String title,
    required bool isFree,
    String? chosen,
    String? imagePath,
  }) {
    if (isFree) return 'Gratis';

    final t = title.toLowerCase();
    bool has(List<String> words) => words.any(t.contains);

    if (has([
      'meja',
      'kursi',
      'lemari',
      'kasur',
      'sofa',
      'rak',
      'nakas',
      'laci',
      'perabot',
      'bangku',
    ])) {
      return 'Furnitur';
    }
    if (has([
      'monitor',
      'laptop',
      'hp',
      'phone',
      'kipas',
      'speaker',
      'mouse',
      'keyboard',
      'headphone',
      'headset',
      'tws',
      'kabel',
      'pc',
      'tv',
      'kamera',
      'charger',
      'gadget',
      'komputer',
    ])) {
      return 'Elektronik';
    }
    if (has([
      'buku',
      'novel',
      'kamus',
      'komik',
      'modul',
      'raket',
      'bola',
      'sepeda',
      'matras',
      'gitar',
      'game',
      'ukulele',
      'hobi',
      'alat musik',
    ])) {
      return 'Buku & Hobi';
    }
    if (has([
      'piring',
      'wajan',
      'panci',
      'sprei',
      'ember',
      'jemuran',
      'kardus',
      'sepatu',
      'baju',
      'kaos',
      'jaket',
      'celana',
      'tas',
      'ransel',
      'dispenser',
      'blender',
      'setrika',
      'helm',
      'selimut',
    ])) {
      return 'Perlengkapan Rumah';
    }

    // Jika judul belum cocok, coba cek nama file foto
    final photoDetect = _detectItemFromPhotoPath(imagePath);
    if (photoDetect['category'] != null) {
      return photoDetect['category'] as String;
    }

    if (chosen != null && _allowedCategories.contains(chosen)) return chosen;
    return 'Perlengkapan Rumah';
  }

  AiGenerationResult _smartRuleBasedDraft({
    required String title,
    required String rawDetails,
    required String condition,
    required bool isFree,
    String? category,
    String? imagePath,
    Uint8List? imageBytes,
    Map<String, double>? dimensions,
  }) {
    // 1. Deteksi nama barang dari kombinasi teks pengguna dan nama file foto
    final textInfo = _detectItemFromText('$title $rawDetails');
    final photoInfo = _detectItemFromPhotoPath(imagePath);
    String detectedName = title.trim();

    final isDefaultChairTitle = detectedName == 'Kursi Belajar Ergonomis Putar';
    if (detectedName.isEmpty || isDefaultChairTitle) {
      if (textInfo['name'] != null) {
        detectedName = textInfo['name'] as String;
      } else if (photoInfo['name'] != null) {
        detectedName = photoInfo['name'] as String;
      } else if (rawDetails.trim().isNotEmpty && rawDetails.trim().length > 3) {
        final words = rawDetails.trim().split(RegExp(r'\s+'));
        detectedName = words.take(4).join(' ');
      } else if (imagePath != null && imagePath.isNotEmpty) {
        detectedName = 'Barang Preloved Layak Pakai';
      } else {
        detectedName = 'Barang Berkualitas';
      }
    }

    // 2. Kategori yang sinkron
    final suggestedCat = _smartDetectCategory(
      title: detectedName,
      isFree: isFree,
      chosen: textInfo['category'] as String? ?? category,
      imagePath: imagePath,
    );

    // 3. Estimasi harga wajar
    int? estimatedPrice;
    if (!isFree) {
      if (textInfo['price'] != null) {
        estimatedPrice = textInfo['price'] as int;
      } else if (photoInfo['price'] != null) {
        estimatedPrice = photoInfo['price'] as int;
      } else {
        if (suggestedCat == 'Furnitur') estimatedPrice = 120000;
        if (suggestedCat == 'Elektronik') estimatedPrice = 150000;
        if (suggestedCat == 'Buku & Hobi') estimatedPrice = 45000;
        if (suggestedCat == 'Perlengkapan Rumah') estimatedPrice = 60000;
      }
    }

    // 4. Susun deskripsi yang sinkron dengan foto iklan
    final buffer = StringBuffer();
    buffer.writeln('Halo calon pembeli/penerima!');
    buffer.writeln();

    if (isFree) {
      buffer.writeln(
        'Saya menawarkan $detectedName ini secara GRATIS untuk siapa saja yang membutuhkan.',
      );
    } else {
      buffer.writeln(
        'Dijual santai $detectedName dengan kondisi fisik masih $condition.',
      );
    }
    buffer.writeln();

    buffer.writeln('Keterangan Barang:');
    buffer.writeln(
      '• Kondisi fisik: $condition (silakan cek detail fisik pada foto iklan terlampir).',
    );
    if (rawDetails.trim().isNotEmpty &&
        !rawDetails.contains('Kursi kerja putar hidrolik')) {
      buffer.writeln('• Catatan tambahan: ${rawDetails.trim()}');
    } else {
      buffer.writeln(
        '• Fungsi dan kelayakan: Masih sangat layak pakai untuk kebutuhan sehari-hari.',
      );
    }

    if (dimensions != null) {
      final p = dimensions['panjang']?.toStringAsFixed(1) ?? '0';
      final l = dimensions['lebar']?.toStringAsFixed(1) ?? '0';
      final t = dimensions['tinggi']?.toStringAsFixed(1) ?? '0';
      buffer.writeln(
        '• Dimensi terukur (Sensor Optik jadiGuna): $p × $l × $t cm',
      );
    }

    buffer.writeln(
      '• Lokasi pengambilan: Terbuka untuk janjian titik temu (COD) di area sekitar yang aman.',
    );
    buffer.writeln();
    buffer.writeln(
      'Berminat? Langsung kirim pesan melalui aplikasi jadiGuna ya!',
    );

    final keywords = <String>{
      detectedName.toLowerCase(),
      suggestedCat,
      condition,
      if (isFree) 'barang gratis',
      'bekas layak pakai',
      'jadiguna',
    }.toList();

    return AiGenerationResult(
      title: detectedName,
      description: buffer.toString().trim(),
      suggestedCategory: suggestedCat,
      suggestedKeywords: keywords,
      tips: '💡 Mode Cerdas Lokal: Masukkan Google Gemini API Key pada ikon kunci (🔑) untuk mengaktifkan AI Vision multimodal otomatis yang memindai kamera dengan akurasi 100%.',
      fromLlm: false,
      estimatedPrice: estimatedPrice,
      suggestedCondition: condition,
    );
  }
}
