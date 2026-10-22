class AiGenerationResult {
  final String title;
  final String description;
  final String suggestedCategory;
  final List<String> suggestedKeywords;
  final String tips;

  AiGenerationResult({
    required this.title,
    required this.description,
    required this.suggestedCategory,
    required this.suggestedKeywords,
    required this.tips,
  });
}

class AiService {
  /// Generate a polished ad draft based on user inputs
  Future<AiGenerationResult> generateAdDraft({
    required String title,
    required String rawDetails,
    required String condition,
    required bool isFree,
    String? category,
  }) async {
    // Simulate realistic AI generation latency
    await Future.delayed(const Duration(milliseconds: 600));

    final cleanTitle = title.trim();
    final lowerTitle = cleanTitle.toLowerCase();

    // 1. Determine suggested category
    String suggestedCat = category ?? (isFree ? 'Gratis' : 'Furnitur');
    if (lowerTitle.contains('meja') ||
        lowerTitle.contains('kursi') ||
        lowerTitle.contains('lemari') ||
        lowerTitle.contains('kasur') ||
        lowerTitle.contains('sofa') ||
        lowerTitle.contains('rak')) {
      suggestedCat = 'Furnitur';
    } else if (lowerTitle.contains('monitor') ||
        lowerTitle.contains('laptop') ||
        lowerTitle.contains('hp') ||
        lowerTitle.contains('kipas') ||
        lowerTitle.contains('speaker') ||
        lowerTitle.contains('mouse') ||
        lowerTitle.contains('keyboard') ||
        lowerTitle.contains('headphone') ||
        lowerTitle.contains('kabel') ||
        lowerTitle.contains('pc') ||
        lowerTitle.contains('tv')) {
      suggestedCat = 'Elektronik';
    } else if (lowerTitle.contains('buku') ||
        lowerTitle.contains('novel') ||
        lowerTitle.contains('kamus') ||
        lowerTitle.contains('komik') ||
        lowerTitle.contains('modul') ||
        lowerTitle.contains('raket') ||
        lowerTitle.contains('bola') ||
        lowerTitle.contains('sepeda') ||
        lowerTitle.contains('matras') ||
        lowerTitle.contains('gitar') ||
        lowerTitle.contains('game')) {
      suggestedCat = 'Buku & Hobi';
    } else if (lowerTitle.contains('piring') ||
        lowerTitle.contains('wajan') ||
        lowerTitle.contains('sprei') ||
        lowerTitle.contains('ember') ||
        lowerTitle.contains('jemuran') ||
        lowerTitle.contains('kardus') ||
        lowerTitle.contains('box') ||
        lowerTitle.contains('sepatu') ||
        lowerTitle.contains('baju') ||
        lowerTitle.contains('kaos') ||
        lowerTitle.contains('jaket')) {
      suggestedCat = 'Perlengkapan Rumah';
    } else if (isFree) {
      suggestedCat = 'Gratis';
    }

    // 2. Draft description
    final buffer = StringBuffer();
    buffer.writeln('Halo calon pembeli/penerima!');
    buffer.writeln();
    if (isFree) {
      buffer.writeln('Saya menawarkan barang ini secara GRATIS untuk siapa saja yang membutuhkan, semoga bisa bermanfaat dan memperpanjang guna pakainya.');
    } else {
      buffer.writeln('Dijual santai $cleanTitle dengan kondisi masih $condition.');
    }
    buffer.writeln();

    buffer.writeln('Detail Barang:');
    if (rawDetails.trim().isNotEmpty) {
      buffer.writeln('• $rawDetails');
    }
    buffer.writeln('• Kondisi fisik: $condition');
    buffer.writeln('• Fungsi dan kelayakan: Masih sangat layak pakai sesuai deskripsi.');
    buffer.writeln('• Lokasi pengambilan: Silakan chat untuk janjian titik temu (COD) di tempat umum yang aman.');
    buffer.writeln();
    buffer.writeln('Berminat atau ingin bertanya detail lebih lanjut? Jangan ragu untuk langsung chat melalui aplikasi jadiGuna ya!');

    // 3. Keywords
    final keywords = <String>{
      cleanTitle,
      suggestedCat,
      condition,
      if (isFree) 'barang gratis',
      if (isFree) 'free give',
      'bekas layak pakai',
      'jogja',
      'kos',
    };

    return AiGenerationResult(
      title: cleanTitle,
      description: buffer.toString(),
      suggestedCategory: suggestedCat,
      suggestedKeywords: keywords.toList(),
      tips: 'Anda dapat meninjau dan mengubah teks hasil rekomendasi AI di atas sebelum memasang iklan.',
    );
  }

  /// Suggest category based on title and brief notes
  Future<String> suggestCategory(String title) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lower = title.toLowerCase();
    if (lower.contains('meja') || lower.contains('kursi') || lower.contains('lemari')) return 'Furnitur';
    if (lower.contains('laptop') || lower.contains('pc') || lower.contains('kipas') || lower.contains('tv')) return 'Elektronik';
    if (lower.contains('buku') || lower.contains('catatan') || lower.contains('novel')) return 'Buku & Alat Tulis';
    if (lower.contains('jaket') || lower.contains('sepatu') || lower.contains('kaos')) return 'Pakaian & Aksesoris';
    if (lower.contains('raket') || lower.contains('sepeda') || lower.contains('olahraga')) return 'Alat Olahraga';
    if (lower.contains('sapu') || lower.contains('sprei') || lower.contains('panci')) return 'Perlengkapan Rumah';
    return 'Lainnya';
  }

  /// Polish existing ad description
  Future<String> polishText(String originalText) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final trimmed = originalText.trim();
    if (trimmed.isEmpty) return 'Deskripsi barang belum diisi.';

    return '✨ Deskripsi yang Diperjelas oleh AI:\n\n'
        '$trimmed\n\n'
        'Catatan tambahan:\n'
        '• Barang siap diambil sesuai kesepakatan di area umum.\n'
        '• Pembayaran dapat dilakukan saat serah terima barang (COD).\n'
        '• Terbuka untuk diskusi kondisi barang melalui fitur Pesan.';
  }
}
