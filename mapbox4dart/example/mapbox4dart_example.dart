import 'dart:convert';

import 'package:mapbox4dart/mapbox4dart.dart';

/// Example: parse a Mapbox GL Style JSON, inspect it, modify it,
/// and write it back.
void main() {
  const codec = MapboxStyleCodec();

  // -- Read ----------------------------------------------------------------
  print('--- Read ---');
  final result = codec.readString(jsonEncode(_sampleStyle));

  switch (result) {
    case ReadMapboxSuccess(:final output, :final warnings):
      for (final w in warnings) {
        print('  Warning: $w');
      }
      _printStyle(output);

      // -- Write back ------------------------------------------------------
      print('\n--- Write ---');
      final writeResult = codec.writeString(output);
      if (writeResult case WriteMapboxSuccess(:final output)) {
        print('JSON length: ${output.length} chars');
      }

    case ReadMapboxFailure(:final errors):
      print('  Failed: $errors');
  }

  // -- Color normalization ------------------------------------------------
  print('\n--- Colors ---');
  for (final color in [
    '#ff0000',
    '#f00',
    'rgb(0, 128, 255)',
    'rgba(255, 0, 0, 0.5)',
    'hsl(120, 100%, 50%)',
    'hsla(240, 100%, 50%, 0.8)',
    'steelblue',
    'transparent',
  ]) {
    final result = normalizeColor(color);
    print('  $color → ${result?.hex} (opacity: ${result?.opacity})');
  }
}

// ---------------------------------------------------------------------------
// Pretty-print
// ---------------------------------------------------------------------------

void _printStyle(MapboxStyle style) {
  print('Style: ${style.name ?? "(unnamed)"}');
  print('Version: ${style.version}');
  print('Sources: ${style.sources.length}');
  for (final entry in style.sources.entries) {
    print('  ${entry.key}: ${entry.value.type}');
  }
  print('Layers: ${style.layers.length}');
  for (final layer in style.layers) {
    final parts = <String>[
      layer.id,
      layer.rawType,
      if (layer.source != null) 'source: ${layer.source}',
      if (layer.minzoom != null) 'zoom: ${layer.minzoom}–${layer.maxzoom}',
    ];
    print('  ${parts.join(' | ')}');
  }
  if (style.extra.isNotEmpty) {
    print('Extra fields: ${style.extra.keys.join(', ')}');
  }
}

// ---------------------------------------------------------------------------
// Sample Mapbox GL Style
// ---------------------------------------------------------------------------

const _sampleStyle = {
  'version': 8,
  'name': 'Example Style',
  'sources': {
    'osm': {
      'type': 'vector',
      'url': 'https://example.com/tiles.json',
    },
    'satellite': {
      'type': 'raster',
      'tiles': ['https://example.com/satellite/{z}/{x}/{y}.jpg'],
      'tileSize': 256,
    },
  },
  'sprite': 'https://example.com/sprite',
  'glyphs': 'https://example.com/fonts/{fontstack}/{range}.pbf',
  'layers': [
    {
      'id': 'background',
      'type': 'background',
      'paint': {'background-color': '#f0f0f0'},
    },
    {
      'id': 'water',
      'type': 'fill',
      'source': 'osm',
      'source-layer': 'water',
      'paint': {'fill-color': '#a0c8f0', 'fill-opacity': 0.8},
    },
    {
      'id': 'roads',
      'type': 'line',
      'source': 'osm',
      'source-layer': 'transportation',
      'filter': ['==', 'class', 'motorway'],
      'minzoom': 5,
      'maxzoom': 22,
      'layout': {'line-cap': 'round', 'line-join': 'round'},
      'paint': {'line-color': '#e892a2', 'line-width': 2},
    },
    {
      'id': 'poi-labels',
      'type': 'symbol',
      'source': 'osm',
      'source-layer': 'poi',
      'minzoom': 14,
      'layout': {
        'text-field': ['get', 'name'],
        'text-font': ['Noto Sans Regular'],
        'text-size': 12,
        'icon-image': ['concat', ['get', 'class'], '-15'],
      },
      'paint': {
        'text-color': '#333',
        'text-halo-color': '#fff',
        'text-halo-width': 1.5,
      },
    },
  ],
  // Unknown field — preserved in roundtrip
  'transition': {'duration': 300, 'delay': 0},
};
