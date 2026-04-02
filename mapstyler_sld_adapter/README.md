# mapstyler_sld_adapter

Converts SLD XML into [mapstyler_style](https://github.com/pt9912/mapstyler/tree/main/mapstyler_style) types. Uses [flutter_map_sld](https://pub.dev/packages/flutter_map_sld) internally for XML parsing — that dependency is not exposed in the public API.

Part of the [mapstyler](https://github.com/pt9912/mapstyler) ecosystem.

## Features

- **SldStyleParser** — parses SLD XML directly into mapstyler types.
- **SLD read** — flattens the SLD hierarchy (Layer → UserStyle → FeatureTypeStyle → Rule) into mapstyler rules.
- **Symbolizers** — PointSymbolizer (Mark / ExternalGraphic), LineSymbolizer, PolygonSymbolizer, TextSymbolizer, RasterSymbolizer.
- **Filters** — OGC comparison, combination, negation, spatial, and distance filters.
- **Color conversion** — ARGB integers ↔ `#rrggbb` hex strings with opacity support.

Pure Dart — no Flutter dependency.

## Usage

```dart
import 'package:mapstyler_sld_adapter/mapstyler_sld_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

final parser = SldStyleParser();
final result = await parser.readStyle(sldXml);

if (result case ReadStyleSuccess(:final output, :final warnings)) {
  print('Style: ${output.name}');
  for (final rule in output.rules) {
    print('  ${rule.name}: ${rule.symbolizers.length} symbolizers');
  }
}
```

### Color utilities

```dart
argbToHex(0xFFFF0080);                  // → '#ff0080'
argbToOpacity(0x80FF0000);              // → 0.502…
hexToArgb('#ff0080');                   // → 0xFFFF0080
hexToArgb('#ff0000', opacity: 0.5);    // → 0x80FF0000
```

## License

BSD-2-Clause — see [LICENSE](LICENSE).
