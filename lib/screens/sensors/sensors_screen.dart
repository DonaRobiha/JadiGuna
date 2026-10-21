import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/sensor_service.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  final SensorService _sensorService = SensorService();
  int _shakeCounter = 0;
  bool _isSensorsEnabled = true;

  // Manual tilt sliders for emulator testing
  final double _manualTiltX = 0.0;
  double _manualTiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  void _startSensors() {
    _sensorService.startListening(
      onShake: () {
        if (mounted) {
          setState(() => _shakeCounter++);
        }
      },
    );
  }

  @override
  void dispose() {
    _sensorService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sensor Perangkat'),
        actions: [
          IconButton(
            icon: Icon(_isSensorsEnabled ? Icons.sensors_rounded : Icons.sensors_off_rounded),
            tooltip: _isSensorsEnabled ? 'Nonaktifkan Sensor' : 'Aktifkan Sensor',
            onPressed: () {
              setState(() {
                _isSensorsEnabled = !_isSensorsEnabled;
                if (_isSensorsEnabled) {
                  _startSensors();
                } else {
                  _sensorService.stopListening();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SENSOR 1: ACCELEROMETER
            _buildSectionHeader('Sensor 1 — Accelerometer (Deteksi Goyangan)'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Implementasi di jadiGuna: Menggoyangkan (shake) perangkat untuk me-refresh dan mengacak rekomendasi barang di beranda.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  ValueListenableBuilder<SensorData>(
                    valueListenable: _sensorService.accelerometerData,
                    builder: (context, data, _) {
                      final gForce = sqrt(data.x * data.x + data.y * data.y + data.z * data.z);
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAxisGauge('Axis X', data.x.toStringAsFixed(2), Colors.blue),
                              _buildAxisGauge('Axis Y', data.y.toStringAsFixed(2), Colors.green),
                              _buildAxisGauge('Axis Z', data.z.toStringAsFixed(2), Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: (gForce / 30.0).clamp(0.0, 1.0),
                            backgroundColor: AppColors.background,
                            color: gForce > 14.0 ? AppColors.secondary : AppColors.primary,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('G-Force: ${gForce.toStringAsFixed(1)} m/s²', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              Text('Ambang Shake: > 14.0', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vibration_rounded, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Shake Terdeteksi: $_shakeCounter kali', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                      // Alternative button for emulator
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primarySurface,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          _sensorService.simulateShake();
                        },
                        icon: const Icon(Icons.touch_app_rounded, size: 16),
                        label: const Text('Simulasi Shake', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SENSOR 2: GYROSCOPE
            _buildSectionHeader('Sensor 2 — Gyroscope (Deteksi Orientasi / Kemiringan)'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Implementasi di jadiGuna: Miringkan perangkat Anda untuk melihat efek interaktif pratinjau 3D kemiringan foto barang.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  ValueListenableBuilder<SensorData>(
                    valueListenable: _sensorService.gyroscopeData,
                    builder: (context, data, _) {
                      // Apply sensor tilt or fallback to manual slider
                      final tiltX = (data.x.abs() > 0.05 ? data.x * 0.15 : _manualTiltX).clamp(-0.4, 0.4);
                      final tiltY = (data.y.abs() > 0.05 ? data.y * 0.15 : _manualTiltY).clamp(-0.4, 0.4);

                      return Center(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateX(tiltX)
                            ..rotateY(tiltY),
                          alignment: FractionalOffset.center,
                          child: Container(
                            width: 220,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: Offset(tiltY * 30, tiltX * 30),
                                ),
                              ],
                              image: const DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=600'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.bottomLeft,
                              child: const Text(
                                'Efek Pratinjau 3D Tilt',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Manual Tilt Slider for Emulator
                  const Text('Simulasi Kemiringan Manual (Untuk Emulator):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Slider(
                    value: _manualTiltY,
                    min: -0.4,
                    max: 0.4,
                    divisions: 20,
                    label: 'Kemiringan: ${(_manualTiltY * 100).round()}%',
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _manualTiltY = val);
                      _sensorService.simulateTilt(_manualTiltX, val, 0);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildAxisGauge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
