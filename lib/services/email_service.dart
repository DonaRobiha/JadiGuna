import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailService {
  static final EmailService instance = EmailService._();
  EmailService._();

  /// Kirim notifikasi sambutan pendaftaran akun ke email pengguna
  Future<bool> sendRegistrationSuccessEmail({
    required String email,
    required String name,
  }) async {
    try {
      debugPrint('[EmailService] Mengirim email notifikasi pendaftaran ke: $email');

      // Mengirimkan email notifikasi melalui REST endpoint
      final response = await http.post(
        Uri.parse('https://formsubmit.co/ajax/$email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          '_subject': 'Selamat Datang di jadiGuna — Pendaftaran Akun Berhasil',
          'Nama': name,
          'Email': email,
          'Pesan': 'Halo $name,\n\nSelamat datang di jadiGuna! Pendaftaran akun Anda telah berhasil. Sekarang Anda dapat mulai mencari, menawar, atau mendonasikan barang bekas berkualitas di sekitar lokasi Anda.',
          'Waktu Pendaftaran': DateTime.now().toString(),
          '_template': 'table',
        }),
      ).timeout(const Duration(seconds: 5));

      final success = response.statusCode == 200;
      debugPrint('[EmailService] Status pengiriman email ke $email: ${response.statusCode}');
      return success;
    } catch (e) {
      debugPrint('[EmailService] Gagal kirim email: $e');
      return false;
    }
  }
}
