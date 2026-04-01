# mapstyler_style

Core types for cartographic styling — compatible with the [GeoStyler](https://geostyler.org/) JSON format.

Part of the [mapstyler](https://github.com/pt9912/mapstyler) ecosystem.

## Features

- **Style / Rule / ScaleDenominator** — top-level style structure with zoom-level control.
- **Symbolizers** — Fill, Line, Mark, Icon, Text, Raster.
- **Filters** — Comparison, Combination, Negation, Spatial, Distance (OGC extension).
- **Expressions** — Literal values and GeoStyler functions (math, string, boolean, case/step/interpolate).
- **Geometry model** — Point, LineString, Polygon, Envelope for spatial filters.
- **StyleParser interface** — common contract for format-specific parsers.

Pure Dart — no Flutter dependency. Usable in Flutter apps, CLI tools, and server applications.

## Usage

```dart
import 'package:mapstyler_style/mapstyler_style.dart';

final style = Style.fromJson({
  'name': 'Land use',
  'rules': [
    {
      'name': 'Residential',
      'filter': ['==', 'landuse', 'residential'],
      'symbolizers': [
        {'kind': 'Fill', 'color': '#ffcc00', 'opacity': 0.5},
      ],
    },
  ],
});

for (final rule in style.rules) {
  print('${rule.name}: ${rule.symbolizers.length} symbolizer(s)');
}
```

## License

BSD-2-Clause — see [LICENSE](LICENSE).
