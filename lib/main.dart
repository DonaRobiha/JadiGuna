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
        // ignore: deprecated_member_use
        anonKey: SupabaseConstants.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Gagal menginisialisasi Supabase: $e');
    }
  }

  // Jalankan aplikasi dengan penanganan otomatis untuk mode single-view maupun web multi-view.
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  if (dispatcher.implicitView != null) {
    runApp(const JadiGunaApp());
  } else {
    runWidget(const _SafeWebMultiViewApp(child: JadiGunaApp()));
  }
}

/// Pembungkus khusus untuk lingkungan Flutter Web / multi-view
/// ketika platformDispatcher.implicitView bernilai null.
class _SafeWebMultiViewApp extends StatefulWidget {
  final Widget child;
  const _SafeWebMultiViewApp({required this.child});

  @override
  State<_SafeWebMultiViewApp> createState() => _SafeWebMultiViewAppState();
}

class _SafeWebMultiViewAppState extends State<_SafeWebMultiViewApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.implicitView ?? (dispatcher.views.isNotEmpty ? dispatcher.views.first : null);
    if (view == null) {
      return const SizedBox.shrink();
    }
    return View(
      view: view,
      child: widget.child,
    );
  }
}
