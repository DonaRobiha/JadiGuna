import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// Smooth compass heading service using accelerometer + magnetometer fusion.
/// Falls back gracefully if the magnetometer is unavailable.
class CompassService {
  bool _isListening = false;
  bool _hasGyroscope = false;

  // Sensor subscriptions
  dynamic _accelSub;
  dynamic _magnetSub;

  // Raw sensor data
  double _ax = 0, _ay = 0, _az = 9.81;
  double _mx = 0, _my = 0, _mz = 0;

  // Smoothed heading state
  double _smoothedHeading = 0.0;
  double _lastReportedHeading = 0.0;
  static const double _alpha = 0.15; // Low-pass filter coefficient

  bool get hasGyroscope => _hasGyroscope;

  /// Start listening to compass (magnetometer + accelerometer).
  void startListening({required void Function(double heading) onUpdate}) {
    if (_isListening) return;
    _isListening = true;

    // Listen to accelerometer for gravity vector
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen((event) {
        _ax = event.x;
        _ay = event.y;
        _az = event.z;
      });
    } catch (_) {}

    // Listen to magnetometer for magnetic field vector
    try {
      _magnetSub = magnetometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen((event) {
        _mx = event.x;
        _my = event.y;
        _mz = event.z;
        _hasGyroscope = true;

        final heading = _computeHeading();
        // Low-pass smooth the heading
        double diff = heading - _smoothedHeading;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        _smoothedHeading += _alpha * diff;
        _smoothedHeading = (_smoothedHeading + 360) % 360;

        // Only fire callback if heading changed meaningfully (>= 0.5 deg)
        if ((_smoothedHeading - _lastReportedHeading).abs() >= 0.5) {
          _lastReportedHeading = _smoothedHeading;
          onUpdate(_smoothedHeading);
        }
      });
    } catch (_) {
      // Magnetometer not available — fallback: report 0 deg fixed heading
      _hasGyroscope = false;
      onUpdate(0.0);
    }
  }

  /// Compute azimuth/heading from accelerometer (gravity) + magnetometer vectors.
  double _computeHeading() {
    // Gravity (normalise accelerometer)
    final gNorm = math.sqrt(_ax * _ax + _ay * _ay + _az * _az);
    if (gNorm == 0) return _smoothedHeading;

    final gx = _ax / gNorm;
    final gy = _ay / gNorm;
    final gz = _az / gNorm;

    // East vector: cross product of gravity and magnetic field
    final ex = gy * _mz - gz * _my;
    final ey = gz * _mx - gx * _mz;
    final ez = gx * _my - gy * _mx;

    final eNorm = math.sqrt(ex * ex + ey * ey + ez * ez);
    if (eNorm == 0) return _smoothedHeading;

    final exN = ex / eNorm;
    final eyN = ey / eNorm;

    // North vector: cross product of east and gravity
    final nx = eyN * gz - (ez / eNorm) * gy;

    // Azimuth
    final azimuth = math.atan2(exN, nx) * 180.0 / math.pi;
    return (azimuth + 360) % 360;
  }

  void stopListening() {
    _isListening = false;
    _accelSub?.cancel();
    _magnetSub?.cancel();
    _accelSub = null;
    _magnetSub = null;
  }
}
