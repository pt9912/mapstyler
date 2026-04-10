# mapstyler_mapbox_adapter

Converts Mapbox GL Style JSON into [mapstyler_style](https://github.com/pt9912/mapstyler/tree/main/mapstyler_style) types and back. Uses [mapbox4dart](https://github.com/pt9912/mapstyler/tree/main/mapbox4dart) internally for JSON parsing — that dependency is not exposed in the public API.

Part of the [mapstyler](https://github.com/pt9912/mapstyler) ecosystem.

## Features

- **MapboxStyleAdapter** — parses Mapbox GL Style JSON directly into mapstyler types and writes styles back to Mapbox JSON.
- **Layer mapping** — fill, line, circle, symbol (text + icon splitting), raster.
- **Expression MVP** — get, literal, interpolate, step, case, match, concat, zoom.
- **Filter MVP** — ==, !=, <, >, <=, >=, all, any, none, !, has, !has, in, !in (legacy v1 + expression v2).
- **Zoom ↔ ScaleDenominator** — Web Mercator conversion.
- **Unsupported layers** — background, fill-extrusion, hillshade, heatmap, sky produce warnings.

Pure Dart — no Flutter dependency.

## Usage

```dart
import 'package:mapstyler_mapbox_adapter/mapstyler_mapbox_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

final adapter = MapboxStyleAdapter();
final result = await adapter.readStyle(mapboxJson);

if (result case ReadStyleSuccess(:final output, :final warnings)) {
  print('Style: ${output.name}');
  for (final rule in output.rules) {
    print('  ${rule.name}: ${rule.symbolizers.length} symbolizers');
  }
}
```

### Writing Mapbox JSON

```dart
final result = await adapter.writeStyle(style);

if (result case WriteStyleSuccess(:final output)) {
  print(output); // Mapbox GL Style JSON string
}
```

## License

MIT — see [LICENSE](LICENSE).
