import 'package:gdal_dart/gdal_dart.dart' as gd;
import 'package:mapstyler_gdal_adapter/mapstyler_gdal_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('VectorLayerInfo', () {
    test('const construction with all fields', () {
      const info = VectorLayerInfo(
        name: 'places',
        featureCount: 42,
        fields: [(name: 'name', type: 'string')],
        extent: (minX: 0, minY: 0, maxX: 10, maxY: 10),
        geometryType: 'Point',
        crs: 'EPSG:4326',
      );
      expect(info.name, 'places');
      expect(info.featureCount, 42);
      expect(info.fields, hasLength(1));
      expect(info.extent?.minX, 0);
      expect(info.geometryType, 'Point');
      expect(info.crs, 'EPSG:4326');
    });

    test('default values', () {
      const info = VectorLayerInfo(name: 'empty', featureCount: -1);
      expect(info.fields, isEmpty);
      expect(info.extent, isNull);
      expect(info.geometryType, isNull);
      expect(info.crs, isNull);
    });
  });

  group('convertGeometry', () {
    test('converts Point', () {
      final result = convertGeometry(const gd.Point(13.4, 52.5));
      expect(result, hasLength(1));
      final p = result.first as PointGeometry;
      expect(p.x, 13.4);
      expect(p.y, 52.5);
    });

    test('converts LineString', () {
      const geom = gd.LineString([
        gd.Point(0, 0),
        gd.Point(1, 1),
        gd.Point(2, 0),
      ]);
      final result = convertGeometry(geom);
      expect(result, hasLength(1));
      final ls = result.first as LineStringGeometry;
      expect(ls.coordinates, [(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)]);
    });

    test('converts Polygon', () {
      const ring = gd.LineString([
        gd.Point(0, 0),
        gd.Point(1, 0),
        gd.Point(1, 1),
        gd.Point(0, 0),
      ]);
      const geom = gd.Polygon([ring]);
      final result = convertGeometry(geom);
      expect(result, hasLength(1));
      final poly = result.first as PolygonGeometry;
      expect(poly.rings, hasLength(1));
      expect(poly.rings.first, hasLength(4));
    });

    test('splits MultiPoint into individual features', () {
      const geom = gd.MultiPoint([gd.Point(1, 2), gd.Point(3, 4)]);
      final result = convertGeometry(geom);
      expect(result, hasLength(2));
      expect(result[0], isA<PointGeometry>());
      expect(result[1], isA<PointGeometry>());
      expect((result[0] as PointGeometry).x, 1);
      expect((result[1] as PointGeometry).x, 3);
    });

    test('splits MultiLineString', () {
      const geom = gd.MultiLineString([
        gd.LineString([gd.Point(0, 0), gd.Point(1, 1)]),
        gd.LineString([gd.Point(2, 2), gd.Point(3, 3)]),
      ]);
      final result = convertGeometry(geom);
      expect(result, hasLength(2));
      expect(result[0], isA<LineStringGeometry>());
      expect(result[1], isA<LineStringGeometry>());
    });

    test('splits MultiPolygon', () {
      const geom = gd.MultiPolygon([
        gd.Polygon([
          gd.LineString(
              [gd.Point(0, 0), gd.Point(1, 0), gd.Point(1, 1), gd.Point(0, 0)])
        ]),
        gd.Polygon([
          gd.LineString(
              [gd.Point(5, 5), gd.Point(6, 5), gd.Point(6, 6), gd.Point(5, 5)])
        ]),
      ]);
      final result = convertGeometry(geom);
      expect(result, hasLength(2));
      expect(result[0], isA<PolygonGeometry>());
      expect(result[1], isA<PolygonGeometry>());
    });

    test('returns empty list for GeometryCollection', () {
      const geom = gd.GeometryCollection([gd.Point(0, 0)]);
      final result = convertGeometry(geom);
      expect(result, isEmpty);
    });

    test('simplifies LineString with tolerance', () {
      // Collinear points — should reduce to 2.
      final geom = gd.LineString([
        for (var i = 0; i < 20; i++) gd.Point(i.toDouble(), 0),
      ]);
      final original = convertGeometry(geom);
      final simplified = convertGeometry(geom, tolerance: 0.1);
      final origLine = original.first as LineStringGeometry;
      final simpLine = simplified.first as LineStringGeometry;
      expect(simpLine.coordinates.length, lessThan(origLine.coordinates.length));
      expect(simpLine.coordinates.first, origLine.coordinates.first);
      expect(simpLine.coordinates.last, origLine.coordinates.last);
    });

    test('simplifies Polygon rings with tolerance', () {
      // Square with many intermediate points on edges.
      final ringPoints = <gd.Point>[];
      for (var i = 0; i < 20; i++) ringPoints.add(gd.Point(i.toDouble(), 0));
      for (var i = 0; i < 20; i++) ringPoints.add(gd.Point(20, i.toDouble()));
      for (var i = 20; i > 0; i--) ringPoints.add(gd.Point(i.toDouble(), 20));
      for (var i = 20; i > 0; i--) ringPoints.add(gd.Point(0, i.toDouble()));
      ringPoints.add(const gd.Point(0, 0)); // close

      final geom = gd.Polygon([gd.LineString(ringPoints)]);
      final original = convertGeometry(geom);
      final simplified = convertGeometry(geom, tolerance: 0.1);
      final origPoly = original.first as PolygonGeometry;
      final simpPoly = simplified.first as PolygonGeometry;
      expect(
        simpPoly.rings.first.length,
        lessThan(origPoly.rings.first.length),
      );
      expect(simpPoly.rings.first.first, simpPoly.rings.first.last);
    });

    test('no simplification when tolerance is null or <= 0', () {
      final geom = gd.LineString([
        for (var i = 0; i < 10; i++) gd.Point(i.toDouble(), 0),
      ]);
      final noTol = convertGeometry(geom);
      final zeroTol = convertGeometry(geom, tolerance: 0);
      final negTol = convertGeometry(geom, tolerance: -1);
      expect((noTol.first as LineStringGeometry).coordinates.length, 10);
      expect((zeroTol.first as LineStringGeometry).coordinates.length, 10);
      expect((negTol.first as LineStringGeometry).coordinates.length, 10);
    });

    test('Polygon with interior ring survives simplification', () {
      // simplifyRing returns the original when the result would
      // degenerate (< 3 unique points), so tiny interior rings
      // survive as unsimplified originals rather than being discarded.
      const exterior = gd.LineString([
        gd.Point(0, 0),
        gd.Point(100, 0),
        gd.Point(100, 100),
        gd.Point(0, 100),
        gd.Point(0, 0),
      ]);
      const interior = gd.LineString([
        gd.Point(40, 40),
        gd.Point(60, 40),
        gd.Point(60, 60),
        gd.Point(40, 60),
        gd.Point(40, 40),
      ]);
      const geom = gd.Polygon([exterior, interior]);

      final result = convertGeometry(geom, tolerance: 1.0);
      expect(result, hasLength(1));
      final poly = result.first as PolygonGeometry;
      expect(poly.rings, hasLength(2));
      // Both rings remain closed.
      expect(poly.rings[0].first, poly.rings[0].last);
      expect(poly.rings[1].first, poly.rings[1].last);
    });
  });
}
