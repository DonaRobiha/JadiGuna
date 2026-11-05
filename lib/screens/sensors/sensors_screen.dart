import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/sensor_service.dart';
import '../listing/compass_screen.dart';
import 'item_measurement_screen.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  final SensorService _sensorService = SensorService();

  @override
  void initState() {
    super.initState();
    _sensorService.startListening();
  }

  @override
  void dispose() {
    _sensorService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fitur Sensor & Hardware jadiGuna',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Membaca nilai sensor gerak (Accelerometer & Gyroscope) secara waktu nyata dari gawai fisik Anda.',
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextColor,
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

            // ── LIVE SENSOR MONITOR (Accelerometer & Gyroscope) ───────────────
            Text(
              'MONITOR SENSOR REAL-TIME',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status Sensor: Aktif',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Live Stream',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 14),

                  // 1. Accelerometer Section
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Accelerometer (Akselerasi & Gravitasi)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<SensorData>(
                    valueListenable: _sensorService.accelerometerData,
                    builder: (context, data, _) {
                      final gForce = sqrt(data.x * data.x + data.y * data.y + data.z * data.z);
                      return Column(
                        children: [
                          _buildAxisBar('Sumbu X (Lateral)', data.x, Colors.redAccent, textColor, subTextColor, borderColor),
                          _buildAxisBar('Sumbu Y (Vertikal)', data.y, Colors.green, textColor, subTextColor, borderColor),
                          _buildAxisBar('Sumbu Z (Depan-Belakang)', data.z, Colors.blueAccent, textColor, subTextColor, borderColor),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Resultan Gaya: ${gForce.toStringAsFixed(2)} m/s²',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 14),

                  // 2. Gyroscope Section
                  Row(
                    children: [
                      const Icon(Icons.screen_rotation_rounded, size: 18, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Gyroscope (Kecepatan Sudut Rotasi)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<SensorData>(
                    valueListenable: _sensorService.gyroscopeData,
                    builder: (context, data, _) {
                      return Column(
                        children: [
                          _buildAxisBar('Pitch (X)', data.x, Colors.deepOrange, textColor, subTextColor, borderColor, unit: 'rad/s', maxVal: 5),
                          _buildAxisBar('Roll (Y)', data.y, Colors.teal, textColor, subTextColor, borderColor, unit: 'rad/s', maxVal: 5),
                          _buildAxisBar('Yaw (Z)', data.z, Colors.purpleAccent, textColor, subTextColor, borderColor, unit: 'rad/s', maxVal: 5),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 14),

                  // 3. Shake Detection Badge & Button
                  ValueListenableBuilder<bool>(
                    valueListenable: _sensorService.isShakeDetected,
                    builder: (context, isShaken, _) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isShaken
                              ? AppColors.success.withValues(alpha: 0.15)
                              : (isDark ? AppColors.darkBackground : AppColors.background),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isShaken ? AppColors.success : borderColor,
                            width: isShaken ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isShaken ? Icons.check_circle_rounded : Icons.vibration_rounded,
                              color: isShaken ? AppColors.success : AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isShaken
                                        ? '🎉 GOYANGAN TERDETEKSI (SHAKE)!'
                                        : 'Deteksi Goyangan (Shake-to-Shuffle)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isShaken ? AppColors.success : textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isShaken
                                        ? 'Gaya g-force > 14 m/s² berhasil memicu event!'
                                        : 'Goyangkan ponsel untuk mengacak rekomendasi barang.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.primary),
                        foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        _sensorService.simulateShake();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Simulasi Shake berhasil dipicu!'),
                            duration: Duration(milliseconds: 900),
                          ),
                        );
                      },
                      icon: const Icon(Icons.touch_app_rounded, size: 16),
                      label: const Text('Uji Simulasi Goyang (Trigger Shake)', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'FITUR HARDWARE TERKAIT',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
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
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subTextColor: subTextColor,
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
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subTextColor: subTextColor,
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
            Text(
              'INFORMASI IZIN & KOMPATIBILITAS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildCompatibilityRow(
                    icon: Icons.explore_rounded,
                    title: 'Sensor Magnetometer (Kompas)',
                    desc: 'Dibutuhkan untuk membaca orientasi mata angin perangkat secara real-time. Jika perangkat atau emulator tidak memiliki sensor magnetik, sistem beralih ke simulasi orientasi.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  Divider(height: 22, color: borderColor),
                  _buildCompatibilityRow(
                    icon: Icons.photo_camera_rounded,
                    title: 'Kamera & Privasi Pengukuran',
                    desc: 'Izin kamera hanya digunakan saat Anda aktif mengukur barang. Gambar diproses secara lokal di ponsel dan tidak diunggah ke server tanpa izin eksplisit Anda.',
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  Divider(height: 22, color: borderColor),
                  _buildCompatibilityRow(
                    icon: Icons.location_on_rounded,
                    title: 'Layanan Lokasi (GPS)',
                    desc: 'Digunakan untuk menghitung jarak presisi serta sudut azimuth menuju koordinat titik temu COD barang.',
                    textColor: textColor,
                    subTextColor: subTextColor,
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

  Widget _buildAxisBar(
    String label,
    double value,
    Color color,
    Color textColor,
    Color subTextColor,
    Color borderColor, {
    String unit = 'm/s²',
    double maxVal = 15,
  }) {
    final clamped = (value.abs() / maxVal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11.5, color: subTextColor, fontWeight: FontWeight.w500)),
              Text(
                '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} $unit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 5,
              backgroundColor: borderColor.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
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
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
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
            style: TextStyle(
              fontSize: 12.5,
              color: subTextColor,
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
    required Color textColor,
    required Color subTextColor,
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
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: subTextColor,
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
