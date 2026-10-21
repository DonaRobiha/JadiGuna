import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool(AppConstants.keyBiometricEnabled) ?? true;
      _notificationsEnabled = prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
    });
  }

  Future<void> _toggleBiometric(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyBiometricEnabled, val);
    setState(() => _biometricEnabled = val);
  }

  Future<void> _toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotificationsEnabled, val);
    setState(() => _notificationsEnabled = val);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _buildSectionTitle('Keamanan & Autentikasi'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                  title: const Text('Login Biometrik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    authProvider.isBiometricsSupported
                        ? 'Gunakan sidik jari / wajah untuk masuk lebih cepat'
                        : 'Perangkat ini belum mendukung biometrik perangkat',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _biometricEnabled && authProvider.isBiometricsSupported,
                  activeColor: AppColors.primary,
                  onChanged: authProvider.isBiometricsSupported ? _toggleBiometric : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Preferensi Tampilan & Notifikasi'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                  title: const Text('Notifikasi Aplikasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pesan masuk dan perubahan status barang', style: TextStyle(fontSize: 12)),
                  value: _notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: _toggleNotifications,
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tampilan gelap hemat baterai dan ramah mata', style: TextStyle(fontSize: 12)),
                  value: themeProvider.isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Arsitektur & Status Database'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Database Lokal (SQLite)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const Text('Aktif (sqflite) - Caching offline-first', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SupabaseConstants.isConfigured ? AppColors.primarySurface : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.cloud_done_rounded,
                        color: SupabaseConstants.isConfigured ? AppColors.primary : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Backend Supabase', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(
                            SupabaseConstants.isConfigured
                                ? 'Terhubung (Cloud PostgreSQL & Auth)'
                                : 'Mode SQLite Lokal Aktif (Offline First)',
                            style: TextStyle(
                              fontSize: 11,
                              color: SupabaseConstants.isConfigured ? AppColors.success : Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // App Info
          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}\nTugas Akhir Pemrograman Aplikasi Mobile',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }
}
