import 'dart:io';

import 'package:mapstyler_gdal_adapter/mapstyler_gdal_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

/// Resolves a fixture path relative to the test directory.
String _fixture(String name) {
  // dart test runs from the package root.
  final f = File('test/fixtures/$name');
  if (!f.existsSync()) {
    throw StateError('Fixture not found: ${f.path}');
  }
  return f.path;
}

void main() {
  group('loadVectorFileSync', () {
    test('loads points from GeoJSON', () {
      final collection = loadVectorFileSync(_fixture('points.geojson'));
      expect(collection.features, hasLength(2));

      final berlin = collection.features[0];
      expect(berlin.geometry, isA<PointGeometry>());
      expect((berlin.geometry as PointGeometry).x, closeTo(13.4, 0.01));
      expect(berlin.properties['name'], 'Berlin');
      expect(berlin.properties['population'], 3645000);
    });

    test('loads mixed geometry types', () {
      final collection = loadVectorFileSync(_fixture('mixed.geojson'));
      // 7 features in file, but:
      //  - Feature 7 has null geometry → skipped
      //  - Feature 4 is MultiPoint(2) → split into 2
      //  - Feature 5 is MultiLineString(2) → split into 2
      //  - Feature 6 is MultiPolygon(2) → split into 2
      // Total: 3 simple + 2 + 2 + 2 = 9
      expect(collection.features, hasLength(9));

      // First feature: Point
      expect(collection.features[0].geometry, isA<PointGeometry>());
      // Second: LineString
      expect(collection.features[1].geometry, isA<LineStringGeometry>());
      // Third: Polygon
      expect(collection.features[2].geometry, isA<PolygonGeometry>());
    });

    test('skips features with null geometry', () {
      final collection = loadVectorFileSync(_fixture('mixed.geojson'));
      // No feature should have null geometry in the result.
      for (final f in collection.features) {
        expect(f.geometry, isNotNull);
      }
    });

    test('multi-geometry features get split IDs', () {
      final collection = loadVectorFileSync(_fixture('mixed.geojson'));
      // MultiPoint (id=4) should produce '4-0' and '4-1'.
      final multiIds = collection.features
          .where((f) => f.id.toString().startsWith('4'))
          .map((f) => f.id)
          .toList();
      expect(multiIds, hasLength(2));
      expect(multiIds[0], '4-0');
      expect(multiIds[1], '4-1');
    });

    test('applies simplifyTolerance', () {
      final original = loadVectorFileSync(_fixture('mixed.geojson'));
      final simplified = loadVectorFileSync(
        _fixture('mixed.geojson'),
        simplifyTolerance: 0.5,
      );
      // Same number of features (simplification doesn't remove features).
      expect(simplified.features.length, original.features.length);
    });

    test('applies spatial filter', () {
      final collection = loadVectorFileSync(
        _fixture('points.geojson'),
        spatialFilter: (minX: 13.0, minY: 52.0, maxX: 14.0, maxY: 53.0),
      );
      // Only Berlin (13.4, 52.5) is in the bbox; Hamburg (10.0, 53.55) is not.
      expect(collection.features, hasLength(1));
      expect(collection.features.first.properties['name'], 'Berlin');
    });

    test('applies attribute filter', () {
      final collection = loadVectorFileSync(
        _fixture('points.geojson'),
        attributeFilter: 'population > 2000000',
      );
      // Only Berlin has population > 2M.
      expect(collection.features, hasLength(1));
      expect(collection.features.first.properties['name'], 'Berlin');
    });

    test('asserts when both tolerance params set', () {
      expect(
        () => loadVectorFileSync(
          _fixture('points.geojson'),
          simplifyTolerance: 0.1,
          simplifyToleranceMeters: 100,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('loadVectorFile (async)', () {
    test('loads features asynchronously', () async {
      final collection = await loadVectorFile(_fixture('points.geojson'));
      expect(collection.features, hasLength(2));
      expect(collection.features.first.properties['name'], 'Berlin');
    });
  });

  group('inspectVectorFileSync', () {
    test('returns layer metadata', () {
      final layers = inspectVectorFileSync(_fixture('points.geojson'));
      expect(layers, hasLength(1));

      final layer = layers.first;
      expect(layer.name, isNotEmpty);
      expect(layer.featureCount, 2);
      expect(layer.fields, isNotEmpty);
      expect(
        layer.fields.any((f) => f.name == 'name'),
        isTrue,
      );
      expect(
        layer.fields.any((f) => f.name == 'population'),
        isTrue,
      );
      expect(layer.extent, isNotNull);
    });

    test('returns CRS when available', () {
      final layers = inspectVectorFileSync(_fixture('points.geojson'));
      // GeoJSON is always EPSG:4326.
      expect(layers.first.crs, contains('4326'));
    });
  });

  group('inspectVectorFile (async)', () {
    test('returns layer metadata asynchronously', () async {
      final layers = await inspectVectorFile(_fixture('points.geojson'));
      expect(layers, hasLength(1));
      expect(layers.first.featureCount, 2);
    });
  });

  group('loadVectorFileSync (additional paths)', () {
    test('selects layer by name', () {
      // GeoJSON layers are named after the file.
      final layers = inspectVectorFileSync(_fixture('points.geojson'));
      final name = layers.first.name;
      final collection = loadVectorFileSync(
        _fixture('points.geojson'),
        layerName: name,
      );
      expect(collection.features, hasLength(2));
    });

    test('simplifyToleranceMeters converts to native CRS', () {
      // GeoJSON is EPSG:4326 (geographic) → meters get converted to degrees.
      final collection = loadVectorFileSync(
        _fixture('points.geojson'),
        simplifyToleranceMeters: 1000,
      );
      expect(collection.features, hasLength(2));
    });
  });

  group('loadVectorFileMultiScaleSync', () {
    test('returns multiple LOD levels with tolerances', () {
      final result = loadVectorFileMultiScaleSync(
        _fixture('mixed.geojson'),
        tolerances: [1.0, 0.1],
      );
      expect(result.keys, containsAll([0.0, 1.0, 0.1]));
      final originalCount = result[0.0]!.features.length;
      expect(result[1.0]!.features.length, originalCount);
      expect(result[0.1]!.features.length, originalCount);
    });

    test('returns multiple LOD levels with tolerancesMeters', () {
      final result = loadVectorFileMultiScaleSync(
        _fixture('points.geojson'),
        tolerancesMeters: [10000, 1000],
      );
      // 3 keys: 0.0 + 2 converted tolerances.
      expect(result.keys, hasLength(3));
      expect(result.containsKey(0.0), isTrue);
    });

    test('applies spatial and attribute filters', () {
      final result = loadVectorFileMultiScaleSync(
        _fixture('points.geojson'),
        tolerances: [0.5],
        spatialFilter: (minX: 13.0, minY: 52.0, maxX: 14.0, maxY: 53.0),
        attributeFilter: 'population > 1000000',
      );
      // Only Berlin passes both filters.
      expect(result[0.0]!.features, hasLength(1));
    });

    test('selects layer by name', () {
      final layers = inspectVectorFileSync(_fixture('points.geojson'));
      final result = loadVectorFileMultiScaleSync(
        _fixture('points.geojson'),
        tolerances: [0.5],
        layerName: layers.first.name,
      );
      expect(result[0.0]!.features, hasLength(2));
    });

    test('asserts when neither tolerances nor tolerancesMeters set', () {
      expect(
        () => loadVectorFileMultiScaleSync(_fixture('points.geojson')),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('loadVectorFileMultiScale (async)', () {
    test('returns multiple LOD levels asynchronously', () async {
      final result = await loadVectorFileMultiScale(
        _fixture('points.geojson'),
        tolerances: [0.5],
      );
      expect(result.keys, containsAll([0.0, 0.5]));
    });
  });
}
