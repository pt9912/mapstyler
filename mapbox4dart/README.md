# mapbox4dart

Pure Dart codec and object model for Mapbox GL Style JSON (v8). Reads and writes Mapbox styles with full roundtrip preservation of unknown fields.

Part of the [mapstyler](https://github.com/pt9912/mapstyler) ecosystem.

## Features

- **MapboxStyleCodec** — reads and writes Mapbox GL Style JSON v8.
- **Typed object model** — `MapboxStyle`, `MapboxLayer`, `MapboxSource` with immutable classes.
- **Unknown field preservation** — unknown root/layer/source fields survive roundtrip via `extra` maps.
- **Forward-compatible** — unknown layer and source types preserved as `unknown + rawType`.
- **Color normalization** — hex, rgb(), rgba(), hsl(), hsla(), 140+ CSS named colors → `#rrggbb`.
- **Version validation** — rejects non-v8 styles with clear error messages.

Pure Dart — no Flutter dependency. No dependencies beyond `dart:convert`.

## Usage

```dart
import 'package:mapbox4dart/mapbox4dart.dart';

const codec = MapboxStyleCodec();

// Read
final result = codec.readString(mapboxJson);
if (result case ReadMapboxSuccess(:final output)) {
  print('${output.name}: ${output.layers.length} layers');
  for (final layer in output.layers) {
    print('  ${layer.id}: ${layer.type}');
  }
}

// Write
final writeResult = codec.writeString(style);
if (writeResult case WriteMapboxSuccess(:final output)) {
  print(output); // JSON string
}
```

### Color normalization

```dart
normalizeColor('rgba(255, 0, 0, 0.5)');  // → (hex: '#ff0000', opacity: 0.5)
normalizeColor('#f00');                    // → (hex: '#ff0000', opacity: null)
normalizeColor('hsl(120, 100%, 50%)');     // → (hex: '#00ff00', opacity: null)
normalizeColor('steelblue');               // → (hex: '#4682b4', opacity: null)
```

## License

MIT — see [LICENSE](LICENSE).
