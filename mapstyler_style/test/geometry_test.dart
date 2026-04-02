import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('PointGeometry', () {
    test('fromJson parses coordinates', () {
      final json = {'type': 'Point', 'coordinates': [8.5, 47.3]};
      final geom = Geometry.fromJson(json);
      expect(geom, isA<PointGeometry>());
      final point = geom as PointGeometry;
      expect(point.x, 8.5);
      expect(point.y, 47.3);
    });

    test('fromJson handles int coordinates', () {
      final json = {'type': 'Point', 'coordinates': [8, 47]};
      final point = Geometry.fromJson(json) as PointGeometry;
      expect(point.x, 8.0);
      expect(point.y, 47.0);
    });

    test('toJson produces correct structure', () {
      const point = PointGeometry(8.5, 47.3);
      expect(point.toJson(), {
        'type': 'Point',
        'coordinates': [8.5, 47.3],
      });
    });

    test('round-trip fromJson/toJson', () {
      final json = {'type': 'Point', 'coordinates': [8.5, 47.3]};
      final geom = Geometry.fromJson(json);
      expect(geom.toJson(), json);
    });

    test('equality', () {
      const a = PointGeometry(8.5, 47.3);
      const b = PointGeometry(8.5, 47.3);
      const c = PointGeometry(9.0, 47.3);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EnvelopeGeometry', () {
    test('fromJson parses bbox', () {
      final json = {
        'type': 'Envelope',
        'bbox': [7.0, 46.0, 9.0, 48.0],
      };
      final geom = Geometry.fromJson(json) as EnvelopeGeometry;
      expect(geom.minX, 7.0);
      expect(geom.minY, 46.0);
      expect(geom.maxX, 9.0);
      expect(geom.maxY, 48.0);
    });

    test('round-trip fromJson/toJson', () {
      final json = {
        'type': 'Envelope',
        'bbox': [7.0, 46.0, 9.0, 48.0],
      };
      expect(Geometry.fromJson(json).toJson(), json);
    });

    test('equality', () {
      const a = EnvelopeGeometry(minX: 7, minY: 46, maxX: 9, maxY: 48);
      const b = EnvelopeGeometry(minX: 7, minY: 46, maxX: 9, maxY: 48);
      const c = EnvelopeGeometry(minX: 0, minY: 46, maxX: 9, maxY: 48);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('LineStringGeometry', () {
    test('fromJson parses coordinate list', () {
      final json = {
        'type': 'LineString',
        'coordinates': [
          [8.0, 47.0],
          [9.0, 48.0],
          [10.0, 47.5],
        ],
      };
      final geom = Geometry.fromJson(json) as LineStringGeometry;
      expect(geom.coordinates, [(8.0, 47.0), (9.0, 48.0), (10.0, 47.5)]);
    });

    test('round-trip fromJson/toJson', () {
      final json = {
        'type': 'LineString',
        'coordinates': [
          [8.0, 47.0],
          [9.0, 48.0],
        ],
      };
      expect(Geometry.fromJson(json).toJson(), json);
    });

    test('equality', () {
      const a = LineStringGeometry([(8.0, 47.0), (9.0, 48.0)]);
      const b = LineStringGeometry([(8.0, 47.0), (9.0, 48.0)]);
      const c = LineStringGeometry([(8.0, 47.0)]);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('PolygonGeometry', () {
    test('fromJson parses rings', () {
      final json = {
        'type': 'Polygon',
        'coordinates': [
          [
            [8.0, 47.0],
            [9.0, 47.0],
            [9.0, 48.0],
            [8.0, 47.0],
          ],
        ],
      };
      final geom = Geometry.fromJson(json) as PolygonGeometry;
      expect(geom.rings.length, 1);
      expect(geom.rings[0].length, 4);
    });

    test('fromJson with hole', () {
      final json = {
        'type': 'Polygon',
        'coordinates': [
          [
            [0.0, 0.0],
            [10.0, 0.0],
            [10.0, 10.0],
            [0.0, 0.0],
          ],
          [
            [2.0, 2.0],
            [8.0, 2.0],
            [8.0, 8.0],
            [2.0, 2.0],
          ],
        ],
      };
      final geom = Geometry.fromJson(json) as PolygonGeometry;
      expect(geom.rings.length, 2);
    });

    test('round-trip fromJson/toJson', () {
      final json = {
        'type': 'Polygon',
        'coordinates': [
          [
            [8.0, 47.0],
            [9.0, 47.0],
            [9.0, 48.0],
            [8.0, 47.0],
          ],
        ],
      };
      expect(Geometry.fromJson(json).toJson(), json);
    });

    test('equality', () {
      const a = PolygonGeometry([
        [(8.0, 47.0), (9.0, 47.0), (9.0, 48.0), (8.0, 47.0)],
      ]);
      const b = PolygonGeometry([
        [(8.0, 47.0), (9.0, 47.0), (9.0, 48.0), (8.0, 47.0)],
      ]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('PolygonGeometry equality', () {
    test('not equal with different rings', () {
      const a = PolygonGeometry([
        [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 0.0)],
      ]);
      const b = PolygonGeometry([
        [(0.0, 0.0), (2.0, 0.0), (2.0, 2.0), (0.0, 0.0)],
      ]);
      const c = PolygonGeometry([
        [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 0.0)],
        [(0.2, 0.2), (0.8, 0.2), (0.8, 0.8), (0.2, 0.2)],
      ]);
      expect(a, isNot(equals(b)));
      expect(a, isNot(equals(c)));
    });
  });

  group('LineStringGeometry equality', () {
    test('not equal with different coordinates', () {
      const a = LineStringGeometry([(0.0, 0.0), (1.0, 1.0)]);
      const b = LineStringGeometry([(0.0, 0.0), (2.0, 2.0)]);
      expect(a, isNot(equals(b)));
    });
  });

  group('Geometry.fromJson', () {
    test('throws on unknown type', () {
      expect(
        () => Geometry.fromJson({'type': 'MultiPoint', 'coordinates': []}),
        throwsFormatException,
      );
    });
  });
}
