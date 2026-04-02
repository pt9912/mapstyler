# mapstyler_qml_adapter

Converts QGIS QML XML into [mapstyler_style](https://github.com/pt9912/mapstyler/tree/main/mapstyler_style) types and back. Uses [qml4dart](https://github.com/pt9912/mapstyler/tree/main/qml4dart) internally for XML parsing — that dependency is not exposed in the public API.

Part of the [mapstyler](https://github.com/pt9912/mapstyler) ecosystem.

## Features

- **QmlStyleParser** — parses QML XML directly into mapstyler types and writes mapstyler styles back to QML XML.
- **QML read** — singleSymbol, categorizedSymbol, graduatedSymbol, and RuleRenderer (incl. nested rules).
- **QML write** — converts rules back to QML XML with automatic renderer type selection.
- **Symbol layers** — SimpleFill, SimpleLine, SimpleMarker, SvgMarker, RasterFill.
- **Filters** — comparison and combination filter conversion in both directions.
- **Scale visibility** — document-level and rule-level scale denominators.
- **Color conversion** — QGIS `"r,g,b,a"` ↔ `"#rrggbb"` with opacity support.
- **Multi-layer symbols** — multiple symbol layers map to multiple symbolizers per rule.

Pure Dart — no Flutter dependency.

## Usage

```dart
import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

final parser = QmlStyleParser();
final result = await parser.readStyle(qmlXml);

if (result case ReadStyleSuccess(:final output, :final warnings)) {
  print('Style: ${output.name}');
  for (final rule in output.rules) {
    print('  ${rule.name}: ${rule.symbolizers.length} symbolizers');
  }
}
```

### Writing QML

```dart
final result = await parser.writeStyle(style);

if (result case WriteStyleSuccess(:final output)) {
  print(output); // QGIS-importable QML XML string
}
```

### Color utilities

```dart
qgisColorToHex('255,204,0,255');  // → '#ffcc00'
qgisColorToOpacity('255,0,0,128'); // → 0.502…
hexToQgisColor('#ffcc00', opacity: 0.5); // → '255,204,0,128'
```

## License

MIT — see [LICENSE](LICENSE).
