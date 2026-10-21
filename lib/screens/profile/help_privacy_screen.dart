import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HelpPrivacyScreen extends StatelessWidget {
  const HelpPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bantuan & Kebijakan Privasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Safety Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panduan Transaksi Aman (COD)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '1. Utamakan bertemu langsung di tempat umum yang ramai (kampus, minimarket, kafe).\n2. Cek fisik barang secara menyeluruh sebelum melakukan pembayaran atau serah terima.\n3. Jangan pernah mentransfer uang muka (DP) kepada penjual yang belum dikenal.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Pertanyaan Umum (FAQ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _buildFaqItem(
            'Bagaimana cara kerja barang gratis di jadiGuna?',
            'Pengguna yang memiliki barang layak pakai yang tidak lagi digunakan dapat mencentang opsi "Barang Gratis (Rp 0)" saat memasang iklan. Calon penerima dapat menghubungi pemilik langsung melalui fitur chat untuk menyepakati waktu pengambilan.',
          ),
          _buildFaqItem(
            'Apakah ada biaya admin atau komisi?',
            'Tidak ada. jadiGuna bertujuan mendukung circular economy dan membantu komunitas lokal serta mahasiswa menemukan barang hemat tanpa potongan biaya transaksi.',
          ),
          _buildFaqItem(
            'Mengapa lokasi saya dibutuhkan?',
            'Fitur lokasi (LBS) digunakan hanya untuk menghitung perkiraan jarak barang terdekat ke tempat tinggal Anda, bukan untuk melacak keberadaan Anda secara berkelanjutan.',
          ),
          _buildFaqItem(
            'Apa fungsi pencatatan Blockchain pada barang?',
            'Setiap perubahan status barang (Dibuat, Dalam Kesepakatan, Selesai) dirangkai menggunakan algoritma kriptografi SHA-256 sehingga riwayat transaksi terbukti otentik dan tidak dapat dimanipulasi secara sepihak.',
          ),
          const SizedBox(height: 24),

          const Text('Kebijakan Privasi & Ketentuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'jadiGuna menjaga kerahasiaan data pribadi Anda. Kata sandi diamankan melalui mekanisme hashing backend, alamat rumah detail tidak dipublikasikan secara terbuka, dan data biometrik dikelola secara lokal oleh sensor perangkat Anda tanpa pernah dikirimkan ke jaringan internet.\n\nDengan menggunakan aplikasi jadiGuna, Anda setuju untuk menjaga etika bertransaksi, tidak mengunggah barang terlarang, serta bertanggung jawab penuh atas kesepakatan serah terima barang.',
              style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        children: [
          Text(answer, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
