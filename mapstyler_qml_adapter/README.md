# mapstyler_qml_adapter

Bidirectional adapter between [qml4dart](https://github.com/pt9912/mapstyler/tree/main/qml4dart) QML types and [mapstyler_style](https://github.com/pt9912/mapstyler/tree/main/mapstyler_style) — converts QGIS QML styles to the common GeoStyler-based type system and back.

Part of the [mapstyler](https://github.com/pt9912/mapstyler) ecosystem.

## Features

- **QmlStyleParser** — implements the `StyleParser<QmlDocument>` interface for full read/write support.
- **QML read (QML → mapstyler)** — singleSymbol, categorizedSymbol, graduatedSymbol, and RuleRenderer (incl. nested rules).
- **QML write (mapstyler → QML)** — converts rules back to QML with automatic renderer type selection.
- **Symbol layers** — SimpleFill, SimpleLine, SimpleMarker, SvgMarker, RasterFill.
- **Filters** — comparison and combination filter conversion in both directions.
- **Scale visibility** — document-level and rule-level scale denominators.
- **Color conversion** — QGIS `"r,g,b,a"` ↔ `"#rrggbb"` with opacity support.
- **Multi-layer symbols** — multiple symbol layers map to multiple symbolizers per rule.

Pure Dart — no Flutter dependency.

## Usage

```dart
import 'package:qml4dart/qml4dart.dart';
import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';

// Parse QML XML, then convert to mapstyler types.
final codec = Qml4DartCodec();
final parseResult = codec.parseString(qmlXml);

if (parseResult case ReadQmlSuccess(:final document)) {
  final parser = QmlStyleParser();
  final result = await parser.readStyle(document);

  if (result case ReadStyleSuccess(:final output, :final warnings)) {
    print('Style: ${output.name}');
    for (final rule in output.rules) {
      print('  ${rule.name}: ${rule.symbolizers.length} symbolizers');
    }
    for (final w in warnings) {
      print('  Warning: $w');
    }
  }
}
```

### Writing QML

```dart
import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';

const style = Style(
  name: 'Land use',
  rules: [
    Rule(
      name: 'Residential',
      filter: ComparisonFilter(
        operator: ComparisonOperator.eq,
        property: LiteralExpression('landuse'),
        value: LiteralExpression<Object>('residential'),
      ),
      symbolizers: [
        FillSymbolizer(
          color: LiteralExpression('#ffcc00'),
          opacity: LiteralExpression(0.5),
        ),
      ],
    ),
  ],
);

final parser = QmlStyleParser();
final result = await parser.writeStyle(style);

if (result case WriteStyleSuccess(:final output)) {
  final codec = Qml4DartCodec();
  final qmlResult = codec.encodeString(output);
  // → QGIS-importable QML XML
}
```

### Low-level API

```dart
// Direct conversion without the async StyleParser wrapper:
final readResult = convertDocument(qmlDocument);
final writeResult = convertStyle(style);
```

### Color utilities

```dart
qgisColorToHex('255,204,0,255');  // → '#ffcc00'
qgisColorToOpacity('255,0,0,128'); // → 0.502…
hexToQgisColor('#ffcc00', opacity: 0.5); // → '255,204,0,128'
```

## License

MIT — see [LICENSE](LICENSE).
