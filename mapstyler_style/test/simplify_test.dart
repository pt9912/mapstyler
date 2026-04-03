import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // simplifyLine
  // ---------------------------------------------------------------------------

  group('simplifyLine', () {
    test('returns original for tolerance <= 0', () {
      final coords = [(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)];
      expect(simplifyLine(coords, 0), same(coords));
      expect(simplifyLine(coords, -1), same(coords));
    });

    test('returns original for 2 or fewer points', () {
      final two = [(0.0, 0.0), (10.0, 10.0)];
      expect(simplifyLine(two, 100), same(two));
      expect(simplifyLine([(0.0, 0.0)], 1), hasLength(1));
      expect(simplifyLine(<(double, double)>[], 1), isEmpty);
    });

    test('preserves start and end', () {
      final coords = [
        (0.0, 0.0),
        (1.0, 0.1),
        (2.0, -0.1),
        (3.0, 0.05),
        (4.0, 0.0),
      ];
      final result = simplifyLine(coords, 1.0);
      expect(result.first, coords.first);
      expect(result.last, coords.last);
    });

    test('removes collinear points', () {
      // Points on a straight line — all intermediate points should be removed.
      final coords = [
        for (var i = 0; i < 100; i++) (i.toDouble(), 0.0),
      ];
      final result = simplifyLine(coords, 0.1);
      expect(result, [(0.0, 0.0), (99.0, 0.0)]);
    });

    test('keeps points that deviate beyond tolerance', () {
      final coords = [
        (0.0, 0.0),
        (5.0, 10.0), // large deviation
        (10.0, 0.0),
      ];
      final result = simplifyLine(coords, 1.0);
      expect(result, hasLength(3));
      expect(result, coords);
    });

    test('reduces a complex polyline', () {
      // Zigzag with small deviations.
      final coords = [
        (0.0, 0.0),
        (1.0, 0.001),
        (2.0, -0.001),
        (3.0, 0.001),
        (4.0, -0.001),
        (5.0, 0.0),
      ];
      final result = simplifyLine(coords, 0.01);
      expect(result.length, lessThan(coords.length));
      expect(result.first, coords.first);
      expect(result.last, coords.last);
    });

    test('handles large tolerance that removes all intermediate points', () {
      final coords = [
        (0.0, 0.0),
        (1.0, 0.5),
        (2.0, -0.5),
        (3.0, 0.3),
        (4.0, 0.0),
      ];
      final result = simplifyLine(coords, 100.0);
      expect(result, [(0.0, 0.0), (4.0, 0.0)]);
    });

    test('radial filter removes clustered points before DP', () {
      // Many points very close together, then a distant point.
      final coords = [
        (0.0, 0.0),
        (0.001, 0.001),
        (0.002, 0.0),
        (0.001, -0.001),
        (0.003, 0.001),
        (10.0, 10.0),
      ];
      final result = simplifyLine(coords, 0.01);
      // Clustered points should be filtered, distant point kept.
      expect(result.length, lessThan(coords.length));
      expect(result.first, (0.0, 0.0));
      expect(result.last, (10.0, 10.0));
    });
  });

  // ---------------------------------------------------------------------------
  // simplifyRing
  // ---------------------------------------------------------------------------

  group('simplifyRing', () {
    test('returns original for tolerance <= 0', () {
      final ring = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 0.0)];
      expect(simplifyRing(ring, 0), same(ring));
      expect(simplifyRing(ring, -1), same(ring));
    });

    test('returns original for 4 or fewer points', () {
      final triangle = [(0.0, 0.0), (1.0, 0.0), (0.5, 1.0), (0.0, 0.0)];
      expect(simplifyRing(triangle, 100), same(triangle));
    });

    test('preserves ring closure', () {
      final ring = [
        (0.0, 0.0),
        (5.0, 0.0),
        (5.0, 5.0),
        (2.5, 5.1), // slight deviation
        (0.0, 5.0),
        (0.0, 0.0),
      ];
      final result = simplifyRing(ring, 0.5);
      expect(result.first, result.last);
    });

    test('simplifies a ring with many points', () {
      // Square with many intermediate points on each edge.
      final ring = <(double, double)>[];
      for (var i = 0; i < 25; i++) ring.add((i.toDouble(), 0.0));
      for (var i = 0; i < 25; i++) ring.add((25.0, i.toDouble()));
      for (var i = 25; i > 0; i--) ring.add((i.toDouble(), 25.0));
      for (var i = 25; i > 0; i--) ring.add((0.0, i.toDouble()));
      ring.add((0.0, 0.0)); // close

      final result = simplifyRing(ring, 0.1);
      // Should reduce to ~4 corners + closure.
      expect(result.length, lessThanOrEqualTo(6));
      expect(result.first, result.last);
      expect(result.length, greaterThanOrEqualTo(4));
    });

    test('returns original when simplification degenerates', () {
      // Ring where all points are very close — simplification would
      // leave fewer than 3 unique points.
      final ring = [
        (0.0, 0.0),
        (0.001, 0.0),
        (0.001, 0.001),
        (0.0, 0.001),
        (0.0, 0.0),
      ];
      final result = simplifyRing(ring, 10.0);
      expect(result, ring);
    });

    test('handles open ring (no closure)', () {
      final open = [
        (0.0, 0.0),
        (5.0, 0.0),
        (5.0, 5.0),
        (2.5, 5.1),
        (0.0, 5.0),
      ];
      final result = simplifyRing(open, 0.5);
      // Open ring: no closure added.
      expect(result.first, isNot(result.last));
      expect(result.length, lessThan(open.length));
    });

    test('minimum 4 points for closed ring', () {
      // Pentagon — after aggressive simplification should keep at
      // least 3 unique + closure = 4 points.
      final ring = [
        (0.0, 0.0),
        (3.0, 0.0),
        (4.0, 2.0),
        (2.0, 4.0),
        (0.0, 2.0),
        (0.0, 0.0),
      ];
      final result = simplifyRing(ring, 0.5);
      expect(result.first, result.last);
      expect(result.length, greaterThanOrEqualTo(4));
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------

  group('edge cases', () {
    test('simplifyLine with coincident start and end', () {
      // Douglas-Peucker special case: lenSq == 0.
      final coords = [
        (5.0, 5.0),
        (6.0, 6.0),
        (5.0, 5.0),
      ];
      final result = simplifyLine(coords, 0.5);
      expect(result.first, (5.0, 5.0));
      expect(result.last, (5.0, 5.0));
      // (6,6) is ~1.4 away from (5,5) which exceeds tolerance 0.5.
      expect(result, hasLength(3));
    });

    test('simplifyLine with coincident start and end within tolerance', () {
      final coords = [
        (5.0, 5.0),
        (5.1, 5.1),
        (5.0, 5.0),
      ];
      final result = simplifyLine(coords, 1.0);
      expect(result, [(5.0, 5.0), (5.0, 5.0)]);
    });

    test('tolerance exactly at point distance', () {
      // Point at exactly tolerance distance — should be removed
      // (< comparison, not <=).
      final coords = [
        (0.0, 0.0),
        (0.0, 1.0), // distance 1.0 from line (0,0)→(2,0)
        (2.0, 0.0),
      ];
      // tolerance = 1.0 → distSq (1.0) < tolSq (1.0) is false → kept? No:
      // distSq (1.0) < tolSq (1.0) is false so point is NOT removed.
      final result = simplifyLine(coords, 1.0);
      expect(result, hasLength(3));

      // tolerance = 1.01 → distSq (1.0) < tolSq (1.0201) is true → removed.
      final result2 = simplifyLine(coords, 1.01);
      expect(result2, hasLength(2));
    });
  });
}
