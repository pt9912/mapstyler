import 'dart:convert';

import 'package:mapbox4dart/mapbox4dart.dart';
import 'package:test/test.dart';

void main() {
  const codec = MapboxStyleCodec();

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------
  group('readString', () {
    test('parses minimal valid style', () {
      final json = jsonEncode({
        'version': 8,
        'sources': <String, dynamic>{},
        'layers': <dynamic>[],
      });
      final result = codec.readString(json);
      expect(result, isA<ReadMapboxSuccess>());
      final style = (result as ReadMapboxSuccess).output;
      expect(style.version, 8);
      expect(style.layers, isEmpty);
      expect(style.sources, isEmpty);
    });

    test('parses complete style with all root fields', () {
      final json = jsonEncode({
        'version': 8,
        'name': 'Test Style',
        'metadata': {'editor': 'test'},
        'sources': {
          'osm': {'type': 'vector', 'url': 'https://example.com/tiles.json'},
        },
        'sprite': 'https://example.com/sprite',
        'glyphs': 'https://example.com/fonts/{fontstack}/{range}.pbf',
        'center': [11.5, 48.1],
        'zoom': 12.0,
        'bearing': 45.0,
        'pitch': 30.0,
        'layers': [
          {
            'id': 'bg',
            'type': 'background',
            'paint': {'background-color': '#f0f0f0'},
          },
        ],
      });

      final result = codec.readString(json);
      expect(result, isA<ReadMapboxSuccess>());
      final style = (result as ReadMapboxSuccess).output;

      expect(style.name, 'Test Style');
      expect(style.metadata['editor'], 'test');
      expect(style.sources['osm']?.type, MapboxSourceType.vector);
      expect(style.sprite, 'https://example.com/sprite');
      expect(style.glyphs, contains('{fontstack}'));
      expect(style.center, [11.5, 48.1]);
      expect(style.zoom, 12.0);
      expect(style.bearing, 45.0);
      expect(style.pitch, 30.0);
      expect(style.layers, hasLength(1));
      expect(style.layers.first.id, 'bg');
      expect(style.layers.first.type, MapboxLayerType.background);
    });

    test('fails on wrong version', () {
      final json = jsonEncode({'version': 7, 'sources': {}, 'layers': []});
      final result = codec.readString(json);
      expect(result, isA<ReadMapboxFailure>());
      expect((result as ReadMapboxFailure).errors.first, contains('version'));
    });

    test('fails on invalid JSON', () {
      final result = codec.readString('not json');
      expect(result, isA<ReadMapboxFailure>());
    });

    test('fails on missing layers', () {
      final json = jsonEncode({'version': 8, 'sources': {}});
      final result = codec.readString(json);
      expect(result, isA<ReadMapboxFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // Layer types
  // ---------------------------------------------------------------------------
  group('layer types', () {
    test('parses all known layer types', () {
      for (final entry in {
        'background': MapboxLayerType.background,
        'fill': MapboxLayerType.fill,
        'line': MapboxLayerType.line,
        'circle': MapboxLayerType.circle,
        'symbol': MapboxLayerType.symbol,
        'raster': MapboxLayerType.raster,
        'fill-extrusion': MapboxLayerType.fillExtrusion,
        'hillshade': MapboxLayerType.hillshade,
        'heatmap': MapboxLayerType.heatmap,
        'sky': MapboxLayerType.sky,
      }.entries) {
        final json = jsonEncode({
          'version': 8,
          'sources': {},
          'layers': [
            {'id': 'l', 'type': entry.key},
          ],
        });
        final result = codec.readString(json) as ReadMapboxSuccess;
        expect(result.output.layers.first.type, entry.value,
            reason: entry.key);
        expect(result.output.layers.first.rawType, entry.key);
      }
    });

    test('preserves unknown layer type as unknown + rawType', () {
      final json = jsonEncode({
        'version': 8,
        'sources': {},
        'layers': [
          {'id': 'l', 'type': 'custom-3d'},
        ],
      });
      final result = codec.readString(json) as ReadMapboxSuccess;
      expect(result.output.layers.first.type, MapboxLayerType.unknown);
      expect(result.output.layers.first.rawType, 'custom-3d');
    });
  });

  // ---------------------------------------------------------------------------
  // Source types
  // ---------------------------------------------------------------------------
  group('source types', () {
    test('parses all known source types', () {
      for (final entry in {
        'vector': MapboxSourceType.vector,
        'raster': MapboxSourceType.raster,
        'raster-dem': MapboxSourceType.rasterDem,
        'geojson': MapboxSourceType.geojson,
        'image': MapboxSourceType.image,
        'video': MapboxSourceType.video,
      }.entries) {
        final json = jsonEncode({
          'version': 8,
          'sources': {
            's': {'type': entry.key, 'url': 'https://example.com'},
          },
          'layers': [],
        });
        final result = codec.readString(json) as ReadMapboxSuccess;
        expect(result.output.sources['s']?.type, entry.value,
            reason: entry.key);
        expect(result.output.sources['s']?.rawType, entry.key);
      }
    });

    test('preserves unknown source type', () {
      final json = jsonEncode({
        'version': 8,
        'sources': {
          's': {'type': 'custom-source'},
        },
        'layers': [],
      });
      final result = codec.readString(json) as ReadMapboxSuccess;
      expect(result.output.sources['s']?.type, MapboxSourceType.unknown);
      expect(result.output.sources['s']?.rawType, 'custom-source');
    });

    test('source properties preserved', () {
      final json = jsonEncode({
        'version': 8,
        'sources': {
          's': {
            'type': 'geojson',
            'data': 'https://example.com/data.json',
            'cluster': true,
            'clusterRadius': 50,
          },
        },
        'layers': [],
      });
      final result = codec.readString(json) as ReadMapboxSuccess;
      final props = result.output.sources['s']!.properties;
      expect(props['data'], 'https://example.com/data.json');
      expect(props['cluster'], true);
      expect(props['clusterRadius'], 50);
    });
  });

  // ---------------------------------------------------------------------------
  // Layer fields
  // ---------------------------------------------------------------------------
  group('layer fields', () {
    test('parses paint, layout, filter, zoom, metadata', () {
      final json = jsonEncode({
        'version': 8,
        'sources': {},
        'layers': [
          {
            'id': 'roads',
            'type': 'line',
            'source': 'osm',
            'source-layer': 'transportation',
            'filter': ['==', 'class', 'motorway'],
            'minzoom': 5,
            'maxzoom': 18,
            'metadata': {'geostyler:ref': 'group1'},
            'paint': {'line-color': '#ff0000', 'line-width': 2},
            'layout': {'line-cap': 'round'},
          },
        ],
      });
      final result = codec.readString(json) as ReadMapboxSuccess;
      final layer = result.output.layers.first;

      expect(layer.id, 'roads');
      expect(layer.source, 'osm');
      expect(layer.sourceLayer, 'transportation');
      expect(layer.filter, ['==', 'class', 'motorway']);
      expect(layer.minzoom, 5.0);
      expect(layer.maxzoom, 18.0);
      expect(layer.metadata['geostyler:ref'], 'group1');
      expect(layer.paint['line-color'], '#ff0000');
      expect(layer.paint['line-width'], 2);
      expect(layer.layout['line-cap'], 'round');
    });

    test('preserves unknown layer fields in extra', () {
      final json = jsonEncode({
        'version': 8,
        'sources': {},
        'layers': [
          {
            'id': 'l',
            'type': 'fill',
            'custom-field': 'custom-value',
            'another': 42,
          },
        ],
      });
      final result = codec.readString(json) as ReadMapboxSuccess;
      final layer = result.output.layers.first;
      expect(layer.extra['custom-field'], 'custom-value');
      expect(layer.extra['another'], 42);
    });
  });

  // ---------------------------------------------------------------------------
  // Unknown root fields (roundtrip)
  // ---------------------------------------------------------------------------
  group('unknown root fields', () {
    test('preserved in extra', () {
      final json = jsonEncode({
        'version': 8,
        'sources': {},
        'layers': [],
        'transition': {'duration': 300, 'delay': 0},
        'fog': {'range': [1, 10]},
      });
      final result = codec.readString(json) as ReadMapboxSuccess;
      expect(result.output.extra['transition'], {'duration': 300, 'delay': 0});
      expect(result.output.extra['fog'], {
        'range': [1, 10]
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Roundtrip
  // ---------------------------------------------------------------------------
  group('roundtrip', () {
    test('read → write → read preserves structure', () {
      final original = {
        'version': 8,
        'name': 'Roundtrip Test',
        'sources': {
          'osm': {'type': 'vector', 'url': 'https://example.com'},
        },
        'sprite': 'https://example.com/sprite',
        'glyphs': 'https://example.com/fonts/{fontstack}/{range}.pbf',
        'layers': [
          {
            'id': 'water',
            'type': 'fill',
            'source': 'osm',
            'source-layer': 'water',
            'paint': {'fill-color': '#0000ff', 'fill-opacity': 0.8},
          },
          {
            'id': 'roads',
            'type': 'line',
            'source': 'osm',
            'source-layer': 'transportation',
            'filter': [
              'all',
              ['==', 'class', 'motorway'],
              ['>', 'width', 5],
            ],
            'layout': {'line-cap': 'round', 'line-join': 'round'},
            'paint': {'line-color': '#333', 'line-width': 2},
            'minzoom': 5,
            'maxzoom': 18,
          },
        ],
      };

      // Read
      final r1 = codec.readJsonObject(original) as ReadMapboxSuccess;
      // Write
      final jsonOut = codec.writeJsonObject(r1.output);
      // Read again
      final r2 = codec.readJsonObject(jsonOut) as ReadMapboxSuccess;

      expect(r2.output.name, r1.output.name);
      expect(r2.output.layers.length, r1.output.layers.length);
      for (var i = 0; i < r1.output.layers.length; i++) {
        expect(r2.output.layers[i].id, r1.output.layers[i].id);
        expect(r2.output.layers[i].type, r1.output.layers[i].type);
        expect(r2.output.layers[i].rawType, r1.output.layers[i].rawType);
        expect(r2.output.layers[i].source, r1.output.layers[i].source);
        expect(r2.output.layers[i].sourceLayer, r1.output.layers[i].sourceLayer);
        expect(r2.output.layers[i].minzoom, r1.output.layers[i].minzoom);
        expect(r2.output.layers[i].maxzoom, r1.output.layers[i].maxzoom);
      }
    });

    test('unknown root and layer fields survive roundtrip', () {
      final original = {
        'version': 8,
        'sources': {},
        'layers': [
          {
            'id': 'l',
            'type': 'fill',
            'custom-prop': 'value',
          },
        ],
        'transition': {'duration': 500},
      };

      final r1 = codec.readJsonObject(original) as ReadMapboxSuccess;
      final jsonOut = codec.writeJsonObject(r1.output);
      final r2 = codec.readJsonObject(jsonOut) as ReadMapboxSuccess;

      expect(r2.output.extra['transition'], {'duration': 500});
      expect(r2.output.layers.first.extra['custom-prop'], 'value');
    });
  });

  // ---------------------------------------------------------------------------
  // writeString
  // ---------------------------------------------------------------------------
  group('writeString', () {
    test('produces valid JSON', () {
      const style = MapboxStyle(
        version: 8,
        name: 'Write Test',
        layers: [
          MapboxLayer(id: 'bg', type: MapboxLayerType.background, rawType: 'background'),
        ],
      );
      final result = codec.writeString(style);
      expect(result, isA<WriteMapboxSuccess>());
      final json = jsonDecode((result as WriteMapboxSuccess).output);
      expect(json['version'], 8);
      expect(json['name'], 'Write Test');
      expect(json['layers'], hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // readJsonObject
  // ---------------------------------------------------------------------------
  group('readJsonObject', () {
    test('works with pre-decoded map', () {
      final map = <String, Object?>{
        'version': 8,
        'sources': <String, dynamic>{},
        'layers': <dynamic>[
          {'id': 'l', 'type': 'fill'},
        ],
      };
      final result = codec.readJsonObject(map);
      expect(result, isA<ReadMapboxSuccess>());
      expect((result as ReadMapboxSuccess).output.layers.first.id, 'l');
    });
  });

  // ---------------------------------------------------------------------------
  // Type serialization (toJsonString)
  // ---------------------------------------------------------------------------
  group('type serialization', () {
    test('MapboxLayerType toJsonString roundtrips', () {
      for (final t in MapboxLayerType.values) {
        final s = t.toJsonString();
        if (t != MapboxLayerType.unknown) {
          expect(MapboxLayerType.fromString(s), t, reason: s);
        }
      }
    });

    test('MapboxSourceType toJsonString roundtrips', () {
      for (final t in MapboxSourceType.values) {
        final s = t.toJsonString();
        if (t != MapboxSourceType.unknown) {
          expect(MapboxSourceType.fromString(s), t, reason: s);
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // MapboxLayer.toJson completeness
  // ---------------------------------------------------------------------------
  group('MapboxLayer.toJson', () {
    test('includes all populated fields', () {
      const layer = MapboxLayer(
        id: 'roads',
        type: MapboxLayerType.line,
        rawType: 'line',
        source: 'osm',
        sourceLayer: 'transportation',
        filter: ['==', 'class', 'motorway'],
        paint: {'line-color': '#ff0000'},
        layout: {'line-cap': 'round'},
        minzoom: 5,
        maxzoom: 18,
        metadata: {'key': 'value'},
        extra: {'custom': true},
      );
      final json = layer.toJson();
      expect(json['id'], 'roads');
      expect(json['type'], 'line');
      expect(json['source'], 'osm');
      expect(json['source-layer'], 'transportation');
      expect(json['filter'], ['==', 'class', 'motorway']);
      expect(json['paint'], {'line-color': '#ff0000'});
      expect(json['layout'], {'line-cap': 'round'});
      expect(json['minzoom'], 5.0);
      expect(json['maxzoom'], 18.0);
      expect(json['metadata'], {'key': 'value'});
      expect(json['custom'], true);
    });

    test('omits empty/null fields', () {
      const layer = MapboxLayer(
        id: 'bg',
        type: MapboxLayerType.background,
        rawType: 'background',
      );
      final json = layer.toJson();
      expect(json.containsKey('source'), isFalse);
      expect(json.containsKey('source-layer'), isFalse);
      expect(json.containsKey('filter'), isFalse);
      expect(json.containsKey('minzoom'), isFalse);
      expect(json.containsKey('maxzoom'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // MapboxStyle equality
  // ---------------------------------------------------------------------------
  group('MapboxStyle equality', () {
    test('equal styles', () {
      final a = MapboxStyle(
        version: 8,
        name: 'Test',
        layers: [
          MapboxLayer(id: 'l', type: MapboxLayerType.fill, rawType: 'fill'),
        ],
      );
      final b = MapboxStyle(
        version: 8,
        name: 'Test',
        layers: [
          MapboxLayer(id: 'l', type: MapboxLayerType.fill, rawType: 'fill'),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different names', () {
      const a = MapboxStyle(version: 8, name: 'A');
      const b = MapboxStyle(version: 8, name: 'B');
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // WriteMapboxFailure
  // ---------------------------------------------------------------------------
  group('WriteMapboxFailure', () {
    test('codec handles encoding errors gracefully', () {
      // writeString with a valid style should succeed
      const style = MapboxStyle(version: 8);
      final result = codec.writeString(style);
      expect(result, isA<WriteMapboxSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------
  group('equality', () {
    test('MapboxSource equality', () {
      final a = MapboxSource.fromJson({'type': 'vector', 'url': 'https://a.com'});
      final b = MapboxSource.fromJson({'type': 'vector', 'url': 'https://a.com'});
      final c = MapboxSource.fromJson({'type': 'raster', 'url': 'https://a.com'});
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('MapboxLayer equality', () {
      const a = MapboxLayer(id: 'x', type: MapboxLayerType.fill, rawType: 'fill');
      const b = MapboxLayer(id: 'x', type: MapboxLayerType.fill, rawType: 'fill');
      const c = MapboxLayer(id: 'y', type: MapboxLayerType.fill, rawType: 'fill');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });
}
