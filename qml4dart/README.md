# qml4dart

Pure Dart Codec und Objektmodell für QGIS-`.qml`-Layer-Style-Dateien.

Liest, modelliert und schreibt QML — ohne Flutter-Abhängigkeit und ohne QGIS-Laufzeit.

## Features

- **Renderer:** singleSymbol, categorizedSymbol, graduatedSymbol, RuleRenderer (inkl. verschachtelte Regeln)
- **Symbol-Layer:** SimpleMarker, SimpleLine, SimpleFill, SvgMarker, RasterFill
- **Geometrietypen:** Punkt (marker), Linie (line), Polygon (fill)
- **Properties:** Farbe, Opacity, Linienbreite, Dash Pattern, Join/Cap, Marker-Größe, Outline, Rotation
- **Beide QML-Formate:** altes `<prop k v>`-Format und neues `<Option type="Map">`-Format (QGIS >= 3.26)
- **Scale Visibility:** auf Dokument- und Regel-Ebene
- **Result-Typen:** `ReadQmlSuccess(document, warnings)` / `ReadQmlFailure(message, cause)`

## Beispiel

```dart
import 'package:qml4dart/qml4dart.dart';

const codec = Qml4DartCodec();

// QML-String parsen
final result = codec.parseString(qmlXmlString);
if (result case ReadQmlSuccess(:final document, :final warnings)) {
  print('Renderer: ${document.renderer.type}');
  print('Symbole: ${document.renderer.symbols.length}');
  for (final w in warnings) {
    print('Warning: $w');
  }
}

// QML-Datei lesen
final fileResult = await codec.parseFile('style.qml');

// Objekt → QML-String
final writeResult = codec.encodeString(document);
if (writeResult case WriteQmlSuccess(:final xml)) {
  print(xml);
}

// Objekt → QML-Datei
await codec.encodeFile('output.qml', document);
```

## Abhängigkeiten

- [`xml`](https://pub.dev/packages/xml) — XML-Parsing und -Erzeugung

## Lizenz

MIT — siehe [LICENSE](LICENSE).
