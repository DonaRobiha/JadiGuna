import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../auth/login_screen.dart';
import '../listing/my_listings_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'help_privacy_screen.dart';
import '../converters/currency_converter_screen.dart';
import '../converters/time_converter_screen.dart';
import '../sensors/sensors_screen.dart';
import '../mini_game/pilah_barang_game_screen.dart';
import '../blockchain/blockchain_history_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../feedback/feedback_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final listingProvider = Provider.of<ListingProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil & Akun'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: user?.profilePhotoPath != null
                            ? NetworkImage(user!.profilePhotoPath!)
                            : null,
                        child: user?.profilePhotoPath == null
                            ? const Icon(Icons.person, size: 34, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Pengguna jadiGuna',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'email@jadiguna.id',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                const SizedBox(width: 2),
                                Text(
                                  user?.city ?? listingProvider.userCityName,
                                  style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Quick stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Iklan Saya', '${listingProvider.myListings.length}', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()));
                      }),
                      Container(height: 24, width: 1, color: AppColors.divider),
                      _buildStatColumn('Favorit', '${listingProvider.favorites.length}', null),
                      Container(height: 24, width: 1, color: AppColors.divider),
                      _buildStatColumn('Status', 'Terverifikasi', null),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fitur Tambahan Tugas Akhir (Special Features Section)
            _buildSectionHeader('Fitur Tambahan Tugas Akhir'),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.currency_exchange_rounded,
                    iconColor: Colors.blueAccent,
                    title: 'Konversi Mata Uang',
                    subtitle: 'IDR, USD, JPY, EUR & kurs waktu nyata',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencyConverterScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.access_time_filled_rounded,
                    iconColor: Colors.orangeAccent,
                    title: 'Konversi Waktu & Zona',
                    subtitle: 'WIB, WITA, WIT, dan London (DST)',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeConverterScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.sensors_rounded,
                    iconColor: Colors.purpleAccent,
                    title: 'Sensor Perangkat',
                    subtitle: 'Accelerometer (Shake) & Gyroscope (Tilt)',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SensorsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.sports_esports_rounded,
                    iconColor: AppColors.primary,
                    title: 'Mini Game: Pilah Barang',
                    subtitle: 'Game edukasi pengelompokan barang bekas',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PilahBarangGameScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.history_rounded,
                    iconColor: Colors.teal,
                    title: 'Riwayat Aktivitas Barang',
                    subtitle: 'Pencatatan riwayat status barang yang aman & terverifikasi',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockchainHistoryScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: Colors.amber,
                    title: 'Asisten AI / LLM',
                    subtitle: 'Generator draf deskripsi dan saran kategori iklan',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings & Support
            _buildSectionHeader('Pengaturan & Bantuan'),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    iconColor: AppColors.textPrimary,
                    title: 'Pengaturan Aplikasi',
                    subtitle: 'Biometrik, notifikasi, dan tema',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.rate_review_outlined,
                    iconColor: AppColors.secondary,
                    title: 'Saran dan Kesan',
                    subtitle: 'Kirimkan masukan Anda untuk aplikasi jadiGuna',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    iconColor: Colors.indigo,
                    title: 'Bantuan, Panduan & Privasi',
                    subtitle: 'FAQ transaksi aman, syarat dan ketentuan',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPrivacyScreen()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    title: 'Keluar (Logout)',
                    subtitle: 'Akhiri sesi login saat ini',
                    textColor: AppColors.error,
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Konfirmasi Logout'),
                          content: const Text('Apakah Anda yakin ingin keluar dari akun jadiGuna?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Keluar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await authProvider.logout();
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56);
  }
}
