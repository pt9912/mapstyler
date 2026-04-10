# flutter_mapstyler

`flutter_mapstyler` renders [`mapstyler_style`](../mapstyler_style/) styles on top of [`flutter_map`](https://pub.dev/packages/flutter_map).

It is the rendering bridge in this workspace:

- `mapstyler_style` defines format-independent style, rule, symbolizer, filter, expression, and geometry types.
- `flutter_mapstyler` evaluates those types against feature data.
- `flutter_map` receives the final Flutter widgets and layers.

## Status

The package currently supports:

- rule selection by `ScaleDenominator`
- expression evaluation for literal, property, case, step, interpolate, and selected argument functions
- filter evaluation for comparison, logical, spatial, and distance filters
- rendering for `FillSymbolizer`, `LineSymbolizer`, `MarkSymbolizer`, `IconSymbolizer`, `TextSymbolizer`, and `RasterSymbolizer`
- optional tap and long-press callbacks per rendered feature

The package deliberately does not parse GeoJSON itself. Input data is expected as `StyledFeature` objects using the `Geometry` model from `mapstyler_style`.

## Installation

```yaml
dependencies:
  flutter_mapstyler: ^0.1.1
```

## Core Types

- `StyledFeature`: a renderable feature with `id`, `geometry`, and `properties`
- `StyledFeatureCollection`: a typed wrapper used by `StyleRenderer.renderStyle`
- `StyleRenderer`: converts style rules or symbolizers into `flutter_map` widgets

## Example

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

final style = Style(
  rules: [
    Rule(
      name: 'water',
      filter: const ComparisonFilter(
        operator: ComparisonOperator.eq,
        property: LiteralExpression('class'),
        value: LiteralExpression('water'),
      ),
      symbolizers: const [
        FillSymbolizer(
          color: LiteralExpression('#4da6ff'),
          fillOpacity: LiteralExpression(0.7),
        ),
      ],
    ),
    Rule(
      name: 'cities',
      symbolizers: const [
        TextSymbolizer(
          label: FunctionExpression(PropertyGet('name')),
          color: LiteralExpression('#1f2937'),
          size: LiteralExpression(14.0),
        ),
      ],
    ),
  ],
);

const features = StyledFeatureCollection([
  StyledFeature(
    id: 'lake-1',
    geometry: PolygonGeometry([
      [
        (13.35, 52.48),
        (13.50, 52.48),
        (13.50, 52.56),
        (13.35, 52.56),
        (13.35, 52.48),
      ],
    ]),
    properties: {'class': 'water'},
  ),
  StyledFeature(
    id: 'city-1',
    geometry: PointGeometry(13.405, 52.52),
    properties: {'name': 'Berlin'},
  ),
]);

final renderer = StyleRenderer();

FlutterMap(
  options: const MapOptions(
    initialCenter: LatLng(52.52, 13.405),
    initialZoom: 10,
  ),
  children: renderer.renderStyle(
    style: style,
    features: features,
    onFeatureTap: (feature) {
      print('Tapped: ${feature.id}');
    },
  ),
);
```

## Rendering Model

- `renderStyle` preserves rule order and emits one or more `flutter_map` widgets per matching symbolizer.
- `renderRule` is useful when you already selected a single rule elsewhere.
- `symbolizerToLayer` is useful for custom rendering pipelines or targeted tests.

## Raster Input Conventions

Raster rendering is driven by feature properties:

- Tile rasters: set `urlTemplate`, optionally `fallbackUrl`, `additionalOptions`, `subdomains`, `tms`, `minZoom`, `maxZoom`, `minNativeZoom`, `maxNativeZoom`
- Overlay rasters: use an `EnvelopeGeometry` plus one of `image`, `url`, or `asset`

## Development

From the repository root:

```bash
docker build --target flutter-analyze .
docker build --target flutter-test .
docker build --target flutter-coverage-check --no-cache-filter flutter-coverage --progress=plain .
```

## Related Docs

- [Architecture notes](../docs/flutter_mapstyler.md)
- [Workspace README](../README.md)
