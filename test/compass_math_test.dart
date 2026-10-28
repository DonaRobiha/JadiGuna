import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

double computeHeading({
  required double ax,
  required double ay,
  required double az,
  required double mx,
  required double my,
  required double mz,
}) {
  final normsqA = ax * ax + ay * ay + az * az;
  if (normsqA < 0.01) return 0.0;

  // H = M x A (East vector)
  final hx = my * az - mz * ay;
  final hy = mz * ax - mx * az;
  final hz = mx * ay - my * ax;

  final normsqH = hx * hx + hy * hy + hz * hz;
  if (normsqH < 0.0001) return 0.0;

  final invH = 1.0 / math.sqrt(normsqH);
  final normHx = hx * invH;
  final normHy = hy * invH;
  final normHz = hz * invH;

  final invA = 1.0 / math.sqrt(normsqA);
  final normAx = ax * invA;
  final normAy = ay * invA;
  final normAz = az * invA;

  // M' = A x H (North vector)
  final myNorth = normAz * normHx - normAx * normHz;

  // Azimuth = atan2(hy, myNorth)
  final azimuth = math.atan2(normHy, myNorth) * 180.0 / math.pi;
  return (azimuth + 360.0) % 360.0;
}

void main() {
  const g = 9.81;
  const bh = 30.0; // horizontal magnetic field
  const bv = -15.0; // vertical magnetic field (Indonesia has upward inclination ~ -30 deg)

  group('Compass Math Tests', () {
    test('Flat facing North (0 deg)', () {
      // Flat: ax = 0, ay = 0, az = g
      // Facing North: mx = 0, my = bh, mz = bv
      final heading = computeHeading(
        ax: 0, ay: 0, az: g,
        mx: 0, my: bh, mz: bv,
      );
      expect(heading, closeTo(0.0, 0.01));
    });

    test('Flat facing East (90 deg)', () {
      // Facing East: top of phone (+Y) points East, so North is to the left (-X)
      // mx = -bh, my = 0, mz = bv
      final heading = computeHeading(
        ax: 0, ay: 0, az: g,
        mx: -bh, my: 0, mz: bv,
      );
      expect(heading, closeTo(90.0, 0.01));
    });

    test('Flat facing South (180 deg)', () {
      // Facing South: top (+Y) points South, North is -Y
      // mx = 0, my = -bh, mz = bv
      final heading = computeHeading(
        ax: 0, ay: 0, az: g,
        mx: 0, my: -bh, mz: bv,
      );
      expect(heading, closeTo(180.0, 0.01));
    });

    test('Flat facing West (270 deg)', () {
      // Facing West: top (+Y) points West, North is to the right (+X)
      // mx = bh, my = 0, mz = bv
      final heading = computeHeading(
        ax: 0, ay: 0, az: g,
        mx: bh, my: 0, mz: bv,
      );
      expect(heading, closeTo(270.0, 0.01));
    });

    test('Tilted 45 deg facing North (0 deg)', () {
      // Tilted up 45 deg around X:
      // ay = -g * sin(45 deg), az = g * cos(45 deg)
      // my = bh * cos(45) - bv * sin(45)
      // mz = bh * sin(45) + bv * cos(45)
      const rad45 = 45.0 * math.pi / 180.0;
      final ay = -g * math.sin(rad45);
      final az = g * math.cos(rad45);
      final my = bh * math.cos(rad45) - bv * math.sin(rad45);
      final mz = bh * math.sin(rad45) + bv * math.cos(rad45);

      final heading = computeHeading(
        ax: 0, ay: ay, az: az,
        mx: 0, my: my, mz: mz,
      );
      expect(heading, closeTo(0.0, 0.01));
    });

    test('Tilted 45 deg facing East (90 deg)', () {
      const rad45 = 45.0 * math.pi / 180.0;
      final ay = -g * math.sin(rad45);
      final az = g * math.cos(rad45);
      // North is -X in world
      final mx = -bh;
      final my = -bv * math.sin(rad45);
      final mz = bv * math.cos(rad45);

      final heading = computeHeading(
        ax: 0, ay: ay, az: az,
        mx: mx, my: my, mz: mz,
      );
      expect(heading, closeTo(90.0, 0.01));
    });
  });
}
