import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';

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
      _biometricEnabled =
          prefs.getBool(AppConstants.keyBiometricEnabled) ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleBiometric(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyBiometricEnabled, val);
    setState(() => _biometricEnabled = val);
  }

  Future<void> _toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', val);
    setState(() => _notificationsEnabled = val);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _buildSectionTitle('Keamanan & Autentikasi', subTextColor),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Login Biometrik',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    authProvider.isBiometricsSupported
                        ? 'Gunakan sidik jari / wajah untuk masuk lebih cepat'
                        : 'Perangkat ini belum mendukung biometrik perangkat',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  value:
                      _biometricEnabled && authProvider.isBiometricsSupported,
                  activeThumbColor: AppColors.primary,
                  onChanged: authProvider.isBiometricsSupported
                      ? _toggleBiometric
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Preferensi Tampilan & Notifikasi', subTextColor),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Notifikasi Aplikasi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Pesan masuk dan perubahan status barang',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  value: _notificationsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleNotifications,
                ),
                Divider(height: 1, indent: 56, color: borderColor),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.dark_mode_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Mode Gelap (Dark Mode)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Tampilan gelap hemat baterai dan ramah mata',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  value: themeProvider.isDarkMode,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
                Divider(height: 1, indent: 56, color: borderColor),
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Uji Notifikasi Status Bar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Kirim notifikasi sistem sekarang untuk pengujian',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await NotificationService.instance.requestPermission();
                      final success = await NotificationService.instance
                          .showNotification(
                            id: 9999,
                            title: 'Notifikasi jadiGuna 🔔',
                            body: 'Pesan baru: Calon pembeli berminat dengan iklan Anda! Titik temu COD telah ditentukan.',
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Notifikasi dikirim! Silakan tarik tirai status bar atas HP Anda.'
                                  : 'Notifikasi dicegah sistem HP. Pastikan izin notifikasi diaktifkan di Pengaturan HP Anda.',
                            ),
                            backgroundColor: success
                                ? AppColors.primary
                                : AppColors.error,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Kirim Tes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Arsitektur & Status Database', subTextColor),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
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
                      child: const Icon(
                        Icons.storage_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Database Lokal (SQLite)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const Text(
                            'Aktif (sqflite) - Caching offline-first',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SupabaseConstants.isConfigured
                            ? AppColors.primarySurface
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.cloud_done_rounded,
                        color: SupabaseConstants.isConfigured
                            ? AppColors.primary
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backend Supabase',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            SupabaseConstants.isConfigured
                                ? 'Terhubung (Cloud PostgreSQL & Auth)'
                                : 'Mode SQLite Lokal Aktif (Offline First)',
                            style: TextStyle(
                              fontSize: 11,
                              color: SupabaseConstants.isConfigured
                                  ? AppColors.success
                                  : Colors.orange.shade800,
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
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
