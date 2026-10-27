import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class AiGenerationResult {
  final String title;
  final String description;
  final String suggestedCategory;
  final List<String> suggestedKeywords;
  final String tips;
  final bool fromLlm;

  AiGenerationResult({
    required this.title,
    required this.description,
    required this.suggestedCategory,
    required this.suggestedKeywords,
    required this.tips,
    this.fromLlm = false,
  });
}

class AiService {
  // Key diisi lewat: flutter run --dart-define=GEMINI_API_KEY=xxxx
  // (tidak ditulis di kode supaya aman saat di-upload ke GitHub)
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  bool get isLlmConfigured => _apiKey.isNotEmpty;

  List<String> get _allowedCategories =>
      AppConstants.categories.where((c) => c != 'Semua').toList();

  // ---------------------------------------------------------------
  // Panggilan ke LLM (Gemini)
  // ---------------------------------------------------------------
  Future<String> _callGemini(
    String prompt, {
    bool asJson = false,
    double temperature = 0.7,
  }) async {
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': temperature,
              'thinkingConfig': {'thinkingBudget': 0},
              if (asJson) 'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Gemini HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text is! String || text.trim().isEmpty) {
      throw Exception('Respons Gemini kosong');
    }
    return text.trim();
  }

  // ---------------------------------------------------------------
  // 1. Buat draf iklan
  // ---------------------------------------------------------------
  Future<AiGenerationResult> generateAdDraft({
    required String title,
    required String rawDetails,
    required String condition,
    required bool isFree,
    String? category,
  }) async {
    if (isLlmConfigured) {
      try {
        final prompt = '''
Kamu adalah asisten penulis iklan untuk aplikasi marketplace barang bekas "jadiGuna" di Indonesia.
Tulis draf iklan dalam bahasa Indonesia yang ramah, jelas, dan jujur.
Jangan mengarang spesifikasi, merek, atau fakta yang tidak disebutkan pengguna.

Data barang:
- Judul: $title
- Detail dari pengguna: ${rawDetails.trim().isEmpty ? '(tidak ada)' : rawDetails}
- Kondisi: $condition
- Jenis iklan: ${isFree ? 'GRATIS (diberikan cuma-cuma)' : 'dijual'}
- Kategori pilihan pengguna: ${category ?? '(belum dipilih)'}

Kategori yang boleh dipilih (pilih persis salah satu): ${_allowedCategories.join(', ')}

Balas HANYA dengan JSON valid dengan format:
{"title": "judul iklan yang menarik", "description": "deskripsi iklan 3-6 kalimat, boleh pakai poin", "category": "salah satu kategori di atas", "keywords": ["kata kunci 1", "kata kunci 2", "..."], "tips": "satu tips singkat agar iklan cepat laku"}
''';

        final raw = await _callGemini(prompt, asJson: true);
        final json = jsonDecode(raw) as Map<String, dynamic>;

        final cat = json['category']?.toString() ?? '';
        return AiGenerationResult(
          title: (json['title'] ?? title).toString().trim(),
          description: (json['description'] ?? '').toString().trim(),
          suggestedCategory: _allowedCategories.contains(cat)
              ? cat
              : _ruleBasedCategory(title, isFree, category),
          suggestedKeywords: (json['keywords'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
          tips: '✨ Dibuat oleh Gemini (LLM). ${json['tips'] ?? ''}'.trim(),
          fromLlm: true,
        );
      } catch (e) {
        debugPrint('AI LLM gagal, pakai fallback: $e');
      }
    }
    return _ruleBasedDraft(
      title: title,
      rawDetails: rawDetails,
      condition: condition,
      isFree: isFree,
      category: category,
    );
  }

  // ---------------------------------------------------------------
  // 2. Saran kategori
  // ---------------------------------------------------------------
  Future<String> suggestCategory(String title) async {
    if (isLlmConfigured) {
      try {
        final prompt = '''
Pilih satu kategori yang paling cocok untuk barang bekas berjudul "$title".
Pilihan: ${_allowedCategories.join(', ')}
Balas HANYA nama kategorinya, persis seperti di pilihan.
''';
        final answer = await _callGemini(prompt, temperature: 0.2);
        final cleaned = answer.replaceAll('"', '').trim();
        if (_allowedCategories.contains(cleaned)) return cleaned;
      } catch (e) {
        debugPrint('AI LLM gagal, pakai fallback: $e');
      }
    }
    return _ruleBasedCategory(title, false, null);
  }

  // ---------------------------------------------------------------
  // 3. Rapikan deskripsi
  // ---------------------------------------------------------------
  Future<String> polishText(String originalText) async {
    final trimmed = originalText.trim();
    if (trimmed.isEmpty) return 'Deskripsi barang belum diisi.';

    if (isLlmConfigured) {
      try {
        final prompt = '''
Rapikan deskripsi iklan barang bekas berikut agar lebih jelas, sopan, dan menarik dalam bahasa Indonesia.
Jangan menambah fakta baru yang tidak ada di teks asli. Balas HANYA teks deskripsinya.

Teks asli:
$trimmed
''';
        return await _callGemini(prompt);
      } catch (e) {
        debugPrint('AI LLM gagal, pakai fallback: $e');
      }
    }

    return '✨ Deskripsi yang Diperjelas oleh AI:\n\n'
        '$trimmed\n\n'
        'Catatan tambahan:\n'
        '• Barang siap diambil sesuai kesepakatan di area umum.\n'
        '• Pembayaran dapat dilakukan saat serah terima barang (COD).\n'
        '• Terbuka untuk diskusi kondisi barang melalui fitur Pesan.';
  }

  // ===============================================================
  // FALLBACK (dipakai kalau offline / API key belum diisi / error)
  // ===============================================================
  String _ruleBasedCategory(String title, bool isFree, String? chosen) {
    final t = title.toLowerCase();
    bool has(List<String> words) => words.any(t.contains);

    if (has(['meja', 'kursi', 'lemari', 'kasur', 'sofa', 'rak'])) {
      return 'Furnitur';
    }
    if (has(['monitor', 'laptop', 'hp', 'kipas', 'speaker', 'mouse',
        'keyboard', 'headphone', 'kabel', 'pc', 'tv'])) {
      return 'Elektronik';
    }
    if (has(['buku', 'novel', 'kamus', 'komik', 'modul', 'raket', 'bola',
        'sepeda', 'matras', 'gitar', 'game'])) {
      return 'Buku & Hobi';
    }
    if (has(['piring', 'wajan', 'sprei', 'ember', 'jemuran', 'kardus',
        'box', 'sepatu', 'baju', 'kaos', 'jaket'])) {
      return 'Perlengkapan Rumah';
    }
    if (isFree) return 'Gratis';
    if (chosen != null && _allowedCategories.contains(chosen)) return chosen;
    return 'Furnitur';
  }

  AiGenerationResult _ruleBasedDraft({
    required String title,
    required String rawDetails,
    required String condition,
    required bool isFree,
    String? category,
  }) {
    final cleanTitle = title.trim();
    final suggestedCat = _ruleBasedCategory(cleanTitle, isFree, category);

    final buffer = StringBuffer()
      ..writeln('Halo calon pembeli/penerima!')
      ..writeln()
      ..writeln(isFree
          ? 'Saya menawarkan barang ini secara GRATIS untuk siapa saja yang membutuhkan.'
          : 'Dijual santai $cleanTitle dengan kondisi masih $condition.')
      ..writeln()
      ..writeln('Detail Barang:');
    if (rawDetails.trim().isNotEmpty) buffer.writeln('• $rawDetails');
    buffer
      ..writeln('• Kondisi fisik: $condition')
      ..writeln('• Lokasi pengambilan: Silakan chat untuk janjian titik temu (COD).')
      ..writeln()
      ..writeln('Berminat? Langsung chat melalui aplikasi jadiGuna ya!');

    return AiGenerationResult(
      title: cleanTitle,
      description: buffer.toString(),
      suggestedCategory: suggestedCat,
      suggestedKeywords: {
        cleanTitle,
        suggestedCat,
        condition,
        if (isFree) 'barang gratis',
        'bekas layak pakai',
      }.toList(),
      tips: 'Draf dibuat dengan template (mode offline). Silakan tinjau sebelum memasang iklan.',
    );
  }
}