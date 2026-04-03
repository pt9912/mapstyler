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
      final result = loadVectorFileSync(_fixture('points.geojson'));
      expect(result.features.features, hasLength(2));
      expect(result.warnings, isEmpty);

      final berlin = result.features.features[0];
      expect(berlin.geometry, isA<PointGeometry>());
      expect((berlin.geometry as PointGeometry).x, closeTo(13.4, 0.01));
      expect(berlin.properties['name'], 'Berlin');
      expect(berlin.properties['population'], 3645000);
    });

    test('loads mixed geometry types and reports warnings', () {
      final result = loadVectorFileSync(_fixture('mixed.geojson'));
      // 7 features in file:
      //  - Feature 7 has null geometry → skipped with warning
      //  - Feature 4 is MultiPoint(2) → split into 2
      //  - Feature 5 is MultiLineString(2) → split into 2
      //  - Feature 6 is MultiPolygon(2) → split into 2
      // Total: 3 simple + 2 + 2 + 2 = 9
      expect(result.features.features, hasLength(9));
      // Null geometry produces a warning.
      expect(result.warnings, hasLength(1));
      expect(result.warnings.first, contains('null geometry'));
    });

    test('skips features with null geometry', () {
      final result = loadVectorFileSync(_fixture('mixed.geojson'));
      for (final f in result.features.features) {
        expect(f.geometry, isNotNull);
      }
    });

    test('multi-geometry features get split IDs', () {
      final result = loadVectorFileSync(_fixture('mixed.geojson'));
      final multiIds = result.features.features
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
      expect(
        simplified.features.features.length,
        original.features.features.length,
      );
    });

    test('applies spatial filter', () {
      final result = loadVectorFileSync(
        _fixture('points.geojson'),
        spatialFilter: (minX: 13.0, minY: 52.0, maxX: 14.0, maxY: 53.0),
      );
      expect(result.features.features, hasLength(1));
      expect(result.features.features.first.properties['name'], 'Berlin');
    });

    test('applies attribute filter', () {
      final result = loadVectorFileSync(
        _fixture('points.geojson'),
        attributeFilter: 'population > 2000000',
      );
      expect(result.features.features, hasLength(1));
      expect(result.features.features.first.properties['name'], 'Berlin');
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
      final result = await loadVectorFile(_fixture('points.geojson'));
      expect(result.features.features, hasLength(2));
      expect(result.features.features.first.properties['name'], 'Berlin');
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
      expect(layer.fields.any((f) => f.name == 'name'), isTrue);
      expect(layer.fields.any((f) => f.name == 'population'), isTrue);
      expect(layer.extent, isNotNull);
    });

    test('returns CRS when available', () {
      final layers = inspectVectorFileSync(_fixture('points.geojson'));
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
      final layers = inspectVectorFileSync(_fixture('points.geojson'));
      final name = layers.first.name;
      final result = loadVectorFileSync(
        _fixture('points.geojson'),
        layerName: name,
      );
      expect(result.features.features, hasLength(2));
    });

    test('simplifyToleranceMeters converts to native CRS', () {
      final result = loadVectorFileSync(
        _fixture('points.geojson'),
        simplifyToleranceMeters: 1000,
      );
      expect(result.features.features, hasLength(2));
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
