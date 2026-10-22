import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';
import 'core/database/local_database.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi SQLite sesuai platform.
  if (kIsWeb) {
    // Untuk Flutter Web di Edge atau browser lain.
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS) {
    // Untuk aplikasi desktop.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inisialisasi format tanggal Indonesia.
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}

  // Mengatur orientasi layar.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Mengatur tampilan status bar.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inisialisasi notifikasi lokal.
  try {
    await NotificationService.instance.init();
  } catch (_) {}

  // Inisialisasi database lokal.
  try {
    await LocalDatabase.instance.database;
  } catch (e) {
    debugPrint('Gagal menginisialisasi database: $e');
  }

  // Inisialisasi Supabase jika kredensial sudah dikonfigurasi.
  if (SupabaseConstants.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        anonKey: SupabaseConstants.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Gagal menginisialisasi Supabase: $e');
    }
  }

  runApp(const JadiGunaApp());
}
