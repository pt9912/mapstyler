import 'dart:convert';

import 'package:mapstyler_mapbox_adapter/mapstyler_mapbox_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

/// Example: parse Mapbox GL Style JSON, inspect the result, build a style
/// from code, and write it back to Mapbox JSON.
void main() async {
  final adapter = MapboxStyleAdapter();

  // -- Read: Mapbox JSON → mapstyler Style --------------------------------
  print('--- Mapbox → mapstyler_style ---');
  final result = await adapter.readStyle(jsonEncode(_sampleMapbox));

  switch (result) {
    case ReadStyleSuccess(:final output, :final warnings):
      for (final w in warnings) {
        print('  Warning: $w');
      }
      _printStyle(output);

    case ReadStyleFailure(:final errors):
      print('  Failed: $errors');
  }

  // -- Write: mapstyler Style → Mapbox JSON -------------------------------
  print('\n--- mapstyler_style → Mapbox ---');
  final style = _buildStyle();
  final writeResult = await adapter.writeStyle(style);

  switch (writeResult) {
    case WriteStyleSuccess(:final output, :final warnings):
      for (final w in warnings) {
        print('  Warning: $w');
      }
      final json = jsonDecode(output);
      print('  Layers: ${(json['layers'] as List).length}');
      print('  JSON length: ${output.length} chars');

    case WriteStyleFailure(:final errors):
      print('  Failed: $errors');
  }

  // -- Round-trip ----------------------------------------------------------
  print('\n--- Round-trip ---');
  final r1 = await adapter.readStyle(jsonEncode(_sampleMapbox));
  final style1 = (r1 as ReadStyleSuccess).output;
  final w1 = await adapter.writeStyle(style1);
  final r2 = await adapter.readStyle((w1 as WriteStyleSuccess<String>).output);
  final style2 = (r2 as ReadStyleSuccess).output;
  print('  Rules before: ${style1.rules.length}, after: ${style2.rules.length}');
}

// ---------------------------------------------------------------------------
// Build a style programmatically
// ---------------------------------------------------------------------------

Style _buildStyle() {
  return Style(
    name: 'Programmatic Style',
    rules: [
      Rule(
        name: 'water',
        filter: const ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('class'),
          value: LiteralExpression<Object>('ocean'),
        ),
        symbolizers: const [
          FillSymbolizer(
            color: LiteralExpression('#0000ff'),
            opacity: LiteralExpression(0.6),
          ),
        ],
      ),
      Rule(
        name: 'roads',
        symbolizers: const [
          LineSymbolizer(
            color: LiteralExpression('#333333'),
            width: LiteralExpression(2.0),
            cap: 'round',
          ),
        ],
        scaleDenominator: const ScaleDenominator(min: 2133, max: 545979),
      ),
      Rule(
        name: 'pois',
        symbolizers: const [
          MarkSymbolizer(
            wellKnownName: 'circle',
            radius: LiteralExpression(5.0),
            color: LiteralExpression('#ff0000'),
          ),
          TextSymbolizer(
            label: FunctionExpression(PropertyGet('name')),
            size: LiteralExpression(12.0),
            color: LiteralExpression('#333'),
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Pretty-print
// ---------------------------------------------------------------------------

void _printStyle(Style style) {
  print('Style: ${style.name ?? "(unnamed)"}');
  for (final rule in style.rules) {
    final parts = <String>[
      rule.name ?? '(unnamed)',
      '${rule.symbolizers.length} symbolizer(s)',
      if (rule.filter != null) 'filtered',
      if (rule.scaleDenominator != null)
        'scale ${rule.scaleDenominator!.min?.toStringAsFixed(0)}–${rule.scaleDenominator!.max?.toStringAsFixed(0)}',
    ];
    print('  ${parts.join(' | ')}');
    for (final sym in rule.symbolizers) {
      print('    ${sym.kind}');
    }
  }
}

// ---------------------------------------------------------------------------
// Sample Mapbox GL Style
// ---------------------------------------------------------------------------

const _sampleMapbox = {
  'version': 8,
  'name': 'Sample',
  'sources': {
    'osm': {'type': 'vector', 'url': 'https://example.com/tiles.json'},
  },
  'layers': [
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
      'layout': {'line-cap': 'round'},
      'paint': {'line-color': '#e892a2', 'line-width': 2},
    },
    {
      'id': 'pois',
      'type': 'circle',
      'source': 'osm',
      'source-layer': 'poi',
      'paint': {'circle-radius': 4, 'circle-color': '#ff6600'},
    },
    {
      'id': 'labels',
      'type': 'symbol',
      'source': 'osm',
      'source-layer': 'poi',
      'minzoom': 14,
      'layout': {
        'text-field': ['get', 'name'],
        'text-size': 12,
      },
      'paint': {
        'text-color': '#333',
        'text-halo-color': '#fff',
        'text-halo-width': 1.5,
      },
    },
  ],
};
