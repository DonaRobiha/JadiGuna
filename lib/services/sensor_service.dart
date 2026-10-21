import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorData {
  final double x;
  final double y;
  final double z;

  SensorData({this.x = 0, this.y = 0, this.z = 0});
}

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final ValueNotifier<SensorData> accelerometerData = ValueNotifier(SensorData());
  final ValueNotifier<SensorData> gyroscopeData = ValueNotifier(SensorData());
  final ValueNotifier<bool> isShakeDetected = ValueNotifier(false);
  final ValueNotifier<bool> isSensorsAvailable = ValueNotifier(true);

  DateTime _lastShakeTime = DateTime.now();
  VoidCallback? onShakeCallback;

  void startListening({VoidCallback? onShake}) {
    onShakeCallback = onShake;

    try {
      _accelSub = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          accelerometerData.value = SensorData(x: event.x, y: event.y, z: event.z);

          // Calculate acceleration magnitude (excluding base 9.8 m/s^2 gravity approx)
          final gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          // Shake threshold (typically > 13 m/s^2 or dynamic change)
          if (gForce > 14.0) {
            final now = DateTime.now();
            if (now.difference(_lastShakeTime) > const Duration(milliseconds: 1000)) {
              _lastShakeTime = now;
              isShakeDetected.value = true;
              onShakeCallback?.call();
              Future.delayed(const Duration(milliseconds: 500), () {
                isShakeDetected.value = false;
              });
            }
          }
        },
        onError: (err) {
          isSensorsAvailable.value = false;
        },
      );

      _gyroSub = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          gyroscopeData.value = SensorData(x: event.x, y: event.y, z: event.z);
        },
        onError: (err) {
          isSensorsAvailable.value = false;
        },
      );
    } catch (_) {
      isSensorsAvailable.value = false;
    }
  }

  /// Manually trigger shake event (useful for emulator or testing)
  void simulateShake() {
    isShakeDetected.value = true;
    onShakeCallback?.call();
    Future.delayed(const Duration(milliseconds: 500), () {
      isShakeDetected.value = false;
    });
  }

  /// Manually update gyroscope tilt angles (pitch, roll, yaw) for emulator testing
  void simulateTilt(double x, double y, double z) {
    gyroscopeData.value = SensorData(x: x, y: y, z: z);
  }

  void stopListening() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
  }
}
