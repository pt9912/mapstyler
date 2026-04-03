import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('StyledFeature', () {
    test('const construction with all fields', () {
      const feature = StyledFeature(
        id: 'f-1',
        geometry: PointGeometry(13.4, 52.5),
        properties: {'name': 'Berlin', 'population': 3645000},
      );
      expect(feature.id, 'f-1');
      expect(feature.geometry, isA<PointGeometry>());
      expect(feature.properties['name'], 'Berlin');
    });

    test('default properties is empty map', () {
      const feature = StyledFeature(
        geometry: PointGeometry(0, 0),
      );
      expect(feature.id, isNull);
      expect(feature.properties, isEmpty);
    });

    test('identity-based equality (no == override)', () {
      // Use final (not const) to avoid canonicalization —
      // const objects with the same fields are identical in Dart.
      final a = StyledFeature(
        id: '1',
        geometry: const PointGeometry(0, 0),
      );
      final b = StyledFeature(
        id: '1',
        geometry: const PointGeometry(0, 0),
      );
      // Same fields but different instances — not equal by design.
      expect(identical(a, b), isFalse);
      expect(a == b, isFalse);
    });

    test('supports different geometry types', () {
      const point = StyledFeature(geometry: PointGeometry(0, 0));
      const line = StyledFeature(
        geometry: LineStringGeometry([(0, 0), (1, 1)]),
      );
      const polygon = StyledFeature(
        geometry: PolygonGeometry([
          [(0, 0), (1, 0), (1, 1), (0, 0)],
        ]),
      );
      expect(point.geometry, isA<PointGeometry>());
      expect(line.geometry, isA<LineStringGeometry>());
      expect(polygon.geometry, isA<PolygonGeometry>());
    });
  });

  group('StyledFeatureCollection', () {
    test('const construction', () {
      const collection = StyledFeatureCollection([
        StyledFeature(id: 'a', geometry: PointGeometry(0, 0)),
        StyledFeature(id: 'b', geometry: PointGeometry(1, 1)),
      ]);
      expect(collection.features, hasLength(2));
      expect(collection.features[0].id, 'a');
      expect(collection.features[1].id, 'b');
    });

    test('empty collection', () {
      const collection = StyledFeatureCollection([]);
      expect(collection.features, isEmpty);
    });

    test('preserves feature order', () {
      final features = List.generate(
        5,
        (i) => StyledFeature(id: 'f-$i', geometry: PointGeometry(i.toDouble(), 0)),
      );
      final collection = StyledFeatureCollection(features);
      for (var i = 0; i < 5; i++) {
        expect(collection.features[i].id, 'f-$i');
      }
    });
  });
}
