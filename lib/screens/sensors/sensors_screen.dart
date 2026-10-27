import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../listing/compass_screen.dart';
import 'item_measurement_screen.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sensor Perangkat',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header / Intro description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sensors_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fitur Sensor & Kamera jadiGuna',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gunakan sensor dan kamera perangkat untuk membantu menemukan serta memeriksa barang di jadiGuna.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'FITUR UTAMA',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            // ── CARD 1: Kompas Digital ─────────────────────────────────────────
            _buildFeatureCard(
              context: context,
              icon: Icons.explore_rounded,
              badgeText: 'Navigasi Titik Temu',
              badgeColor: AppColors.primarySurface,
              badgeTextColor: AppColors.primaryDark,
              title: 'Kompas Digital',
              description: 'Temukan arah menuju lokasi pengambilan barang dengan bantuan kompas perangkat Anda.',
              buttonLabel: 'Buka Kompas',
              buttonIcon: Icons.explore_outlined,
              buttonColor: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompassScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── CARD 2: Pengukur Ukuran Barang ────────────────────────────────
            _buildFeatureCard(
              context: context,
              icon: Icons.straighten_rounded,
              badgeText: 'Kamera & Dimensi',
              badgeColor: const Color(0xFFFDF4E6),
              badgeTextColor: const Color(0xFFB45309),
              title: 'Pengukur Ukuran Barang',
              description: 'Perkirakan panjang, lebar, dan tinggi barang sebelum mengambilnya.',
              buttonLabel: 'Mulai Mengukur',
              buttonIcon: Icons.camera_alt_outlined,
              buttonColor: const Color(0xFF1B281E),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemMeasurementScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 22),

            // ── Petunjuk Izin & Kompatibilitas Perangkat ───────────────────────
            const Text(
              'INFORMASI IZIN & KOMPATIBILITAS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildCompatibilityRow(
                    icon: Icons.explore_rounded,
                    title: 'Sensor Magnetometer (Kompas)',
                    desc: 'Dibutuhkan untuk membaca orientasi mata angin perangkat secara real-time. Jika perangkat atau emulator tidak memiliki sensor magnetik, sistem beralih ke simulasi orientasi.',
                  ),
                  const Divider(height: 22),
                  _buildCompatibilityRow(
                    icon: Icons.photo_camera_rounded,
                    title: 'Kamera & Privasi Pengukuran',
                    desc: 'Izin kamera hanya digunakan saat Anda aktif mengukur barang. Gambar diproses secara lokal di ponsel dan tidak diunggah ke server tanpa izin eksplisit Anda.',
                  ),
                  const Divider(height: 22),
                  _buildCompatibilityRow(
                    icon: Icons.location_on_rounded,
                    title: 'Layanan Lokasi (GPS)',
                    desc: 'Digunakan untuk menghitung jarak presisi serta sudut azimuth menuju koordinat titik temu COD barang.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String description,
    required String buttonLabel,
    required IconData buttonIcon,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onTap,
              icon: Icon(buttonIcon, size: 18),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
