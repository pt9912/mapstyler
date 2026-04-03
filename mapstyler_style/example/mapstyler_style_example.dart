import 'package:mapstyler_style/mapstyler_style.dart';

/// Example: build styles from JSON and from code, inspect them,
/// and round-trip through JSON serialization.
void main() {
  _fromJson();
  _fromCode();
  _withFunctions();
  _withSpatialFilter();
}

// ---------------------------------------------------------------------------
// Build a style from GeoStyler JSON
// ---------------------------------------------------------------------------

void _fromJson() {
  print('--- From GeoStyler JSON ---');

  final style = Style.fromJson({
    'name': 'Land use',
    'rules': [
      {
        'name': 'Residential',
        'filter': ['==', 'landuse', 'residential'],
        'scaleDenominator': {'min': 0, 'max': 50000},
        'symbolizers': [
          {
            'kind': 'Fill',
            'color': '#ffcc00',
            'opacity': 0.5,
            'outlineColor': '#aa8800',
            'outlineWidth': 1.5,
          },
        ],
      },
      {
        'name': 'Roads',
        'filter': [
          '&&',
          ['==', 'type', 'road'],
          ['>', 'width', 3],
        ],
        'symbolizers': [
          {
            'kind': 'Line',
            'color': '#333333',
            'width': 2.0,
            'dasharray': [10.0, 5.0],
            'cap': 'round',
          },
        ],
      },
      {
        'name': 'Hospitals',
        'filter': ['==', 'amenity', 'hospital'],
        'symbolizers': [
          {
            'kind': 'Mark',
            'wellKnownName': 'cross',
            'color': '#ff0000',
            'radius': 8.0,
          },
          {
            'kind': 'Text',
            'label': {'name': 'property', 'args': ['name']},
            'size': 12.0,
            'haloColor': '#ffffff',
            'haloWidth': 2.0,
          },
        ],
      },
    ],
  });

  _printStyle(style);

  // Round-trip: Style → JSON → Style
  final json = style.toJson();
  final restored = Style.fromJson(json);
  print('  Round-trip equal: ${restored == style}');
}

// ---------------------------------------------------------------------------
// Build a style programmatically
// ---------------------------------------------------------------------------

void _fromCode() {
  print('\n--- From code ---');

  final style = Style(
    name: 'Points of interest',
    rules: [
      Rule(
        name: 'Default marker',
        symbolizers: [
          MarkSymbolizer(
            wellKnownName: 'circle',
            radius: LiteralExpression(6.0),
            color: LiteralExpression('#3388ff'),
            strokeColor: LiteralExpression('#ffffff'),
            strokeWidth: LiteralExpression(2.0),
          ),
        ],
      ),
      Rule(
        name: 'Icon marker',
        filter: ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('type'),
          value: LiteralExpression<Object>('restaurant'),
        ),
        symbolizers: [
          IconSymbolizer(
            image: LiteralExpression('restaurant.svg'),
            size: LiteralExpression(24.0),
          ),
        ],
      ),
    ],
  );

  _printStyle(style);

  // Serialize to JSON string
  final jsonString = style.toJsonString();
  print('  JSON length: ${jsonString.length} chars');
}

// ---------------------------------------------------------------------------
// Function expressions: case, step, interpolate
// ---------------------------------------------------------------------------

void _withFunctions() {
  print('\n--- Function expressions ---');

  // Color based on feature property using case()
  final caseStyle = Style(
    name: 'Dynamic color',
    rules: [
      Rule(
        name: 'Color by type',
        symbolizers: [
          FillSymbolizer(
            color: FunctionExpression(
              CaseFunction(
                cases: [
                  CaseParameter(
                    condition: FunctionExpression<Object>(
                      ArgsFunction(name: 'equalTo', args: [
                        FunctionExpression<Object>(PropertyGet('type')),
                        LiteralExpression<Object>('forest'),
                      ]),
                    ),
                    value: LiteralExpression<Object>('#228B22'),
                  ),
                  CaseParameter(
                    condition: FunctionExpression<Object>(
                      ArgsFunction(name: 'equalTo', args: [
                        FunctionExpression<Object>(PropertyGet('type')),
                        LiteralExpression<Object>('water'),
                      ]),
                    ),
                    value: LiteralExpression<Object>('#4444ff'),
                  ),
                ],
                fallback: LiteralExpression<Object>('#cccccc'),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  _printStyle(caseStyle);

  // Width interpolated by zoom level
  final interpStyle = Style(
    name: 'Interpolated width',
    rules: [
      Rule(
        symbolizers: [
          LineSymbolizer(
            color: LiteralExpression('#333333'),
            width: FunctionExpression(
              InterpolateFunction(
                mode: ['linear'],
                input: FunctionExpression<Object>(PropertyGet('zoom')),
                stops: [
                  InterpolateParameter(
                    stop: LiteralExpression<Object>(5),
                    value: LiteralExpression<Object>(1.0),
                  ),
                  InterpolateParameter(
                    stop: LiteralExpression<Object>(15),
                    value: LiteralExpression<Object>(8.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );

  final json = interpStyle.toJson();
  print('  Interpolate rule JSON keys: ${json['rules'][0]['symbolizers'][0].keys.toList()}');
}

// ---------------------------------------------------------------------------
// Spatial and distance filters (OGC extension)
// ---------------------------------------------------------------------------

void _withSpatialFilter() {
  print('\n--- Spatial filter ---');

  final style = Style(
    name: 'Spatial query',
    rules: [
      Rule(
        name: 'Near point',
        filter: DistanceFilter(
          operator: DistanceOperator.dWithin,
          geometry: PointGeometry(8.5, 47.3),
          distance: 1000,
          units: 'm',
        ),
        symbolizers: [
          FillSymbolizer(color: LiteralExpression('#ff0000')),
        ],
      ),
      Rule(
        name: 'Inside bbox',
        filter: SpatialFilter(
          operator: SpatialOperator.bbox,
          geometry: EnvelopeGeometry(
            minX: 7, minY: 46, maxX: 9, maxY: 48,
          ),
        ),
        symbolizers: [
          FillSymbolizer(color: LiteralExpression('#00ff00')),
        ],
      ),
    ],
  );

  _printStyle(style);

  // Round-trip through JSON
  final json = style.toJson();
  final restored = Style.fromJson(json);
  print('  Spatial round-trip equal: ${restored == style}');
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
        'scale ${rule.scaleDenominator!.min}–${rule.scaleDenominator!.max}',
    ];
    print('  ${parts.join(' | ')}');
    for (final sym in rule.symbolizers) {
      print('    ${sym.kind}');
    }
  }
}
