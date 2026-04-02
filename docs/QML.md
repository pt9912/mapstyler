# QML in `mapstyler`

Diese Datei beschreibt den **aktuellen Implementierungsstand** von
`qml4dart` und `mapstyler_qml_adapter` im Repository. Maßgeblich ist der
Source Code.

## Überblick

Die QML-Unterstützung ist in zwei Pakete getrennt:

```text
QGIS QML XML
  -> qml4dart
     (Codec + QML-Objektmodell)
  -> mapstyler_qml_adapter
     (Mapping zwischen QML und mapstyler_style)
  -> mapstyler_style
```

Dabei gilt:

- `qml4dart` ist ein pure-Dart-Codec für QGIS-`.qml`-Dateien.
- `mapstyler_qml_adapter` ist die öffentliche Konvertierungs-API für das
  mapstyler-Ökosystem.
- `mapstyler_qml_adapter` nutzt `qml4dart` intern, exponiert dessen
  Objektmodell aber nicht in seiner Public API.

## Paketgrenzen

| Verantwortung | `qml4dart` | `mapstyler_qml_adapter` |
|---|---|---|
| QML XML lesen/schreiben | `ja` | `ja`, über die öffentliche Adapter-API |
| Eigenes QML-Objektmodell | `ja` | `nein`, nur intern genutzt |
| Renderer-, Symbol- und Regelmodell für QML | `ja` | `nein`, nur Mapping |
| QML nach `mapstyler_style` mappen | `nein` | `ja` |
| `Style` nach QML schreiben | `nein` | `ja` |
| QGIS-Farbstrings <-> Hex/Opacity mappen | `nein` | `ja` |

Wichtig: Struktur- und Detailtreue innerhalb der QML-Domäne gilt primär
für `qml4dart`. Sobald nach `mapstyler_style` gemappt wird, ist das
Objektmodell bewusst stärker abstrahiert.

## `qml4dart`

### Aufgabe

`qml4dart` liest und schreibt QGIS-QML-XML in ein eigenes Dart-Modell.
Das Package ist kein `mapstyler`-Adapter, sondern ein QML-spezifischer
Codec mit typisiertem Objektmodell.

### Öffentliche API

```dart
abstract class QmlCodec {
  const QmlCodec();

  ReadQmlResult parseString(String xml);
  Future<ReadQmlResult> parseFile(String path);

  WriteQmlResult encodeString(QmlDocument document);
  Future<WriteQmlResult> encodeFile(String path, QmlDocument document);
}
```

Die konkrete Standardimplementierung ist:

```dart
class Qml4DartCodec extends QmlCodec {
  const Qml4DartCodec();
}
```

### Result-Typen

```dart
sealed class ReadQmlResult {
  const ReadQmlResult();
}

final class ReadQmlSuccess extends ReadQmlResult {
  final QmlDocument document;
  final List<String> warnings;
}

final class ReadQmlFailure extends ReadQmlResult {
  final String message;
  final Object? cause;
}

sealed class WriteQmlResult {
  const WriteQmlResult();
}

final class WriteQmlSuccess extends WriteQmlResult {
  final String xml;
  final List<String> warnings;
}

final class WriteQmlFailure extends WriteQmlResult {
  final String message;
  final Object? cause;
}
```

### Kernmodell

Das Objektmodell ist QML-spezifisch aufgebaut. Zentrale Typen sind:

- `QmlDocument`
- `QmlRenderer`
- `QmlRule`
- `QmlSymbol`
- `QmlSymbolLayer`
- `QmlCategory`
- `QmlRange`

Wichtige Enums:

- `QmlRendererType`
- `QmlSymbolType`
- `QmlSymbolLayerType`

### Aktuell unterstützte Renderer

`qml4dart` unterstützt aktuell:

- `singleSymbol`
- `categorizedSymbol`
- `graduatedSymbol`
- `RuleRenderer` inklusive verschachtelter Regeln

### Aktuell unterstützte Symbol-Layer

`qml4dart` unterstützt aktuell:

- `SimpleMarker`
- `SvgMarker`
- `SimpleLine`
- `SimpleFill`
- `RasterFill`

Zusätzlich werden unterstützt:

- altes Property-Format mit `<prop k="..." v="...">`
- neues Property-Format mit `<Option type="Map">`
- Scale Visibility auf Dokument- und Regel-Ebene

### Schreib- und Roundtrip-Ziel

`qml4dart` zielt auf semantisch stabilen Roundtrip innerhalb der
QML-Domäne, nicht auf byte-identische Reproduktion der Eingabe.

## `mapstyler_qml_adapter`

### Aufgabe

`mapstyler_qml_adapter` konvertiert zwischen QGIS-QML-XML und
`mapstyler_style.Style`.

Die öffentliche API arbeitet aktuell auf XML-String-Basis:

```dart
class QmlStyleParser {
  const QmlStyleParser();

  String get title;

  Future<ReadStyleResult> readStyle(String qmlXml);
  Future<WriteStyleResult<String>> writeStyle(Style style);
}
```

Intern sieht der Datenfluss so aus:

```text
readStyle(String)
  -> qml4dart.Qml4DartCodec.parseString
  -> QmlDocument
  -> mapstyler_style.Style

writeStyle(Style)
  -> QmlDocument
  -> qml4dart.Qml4DartCodec.encodeString
  -> String
```

## Mapping: QML -> mapstyler

### Renderer

Aktuell werden diese QML-Renderer gelesen:

| QML | Ergebnis in `mapstyler_style` |
|---|---|
| `singleSymbol` | eine Regel ohne Filter |
| `categorizedSymbol` | eine Regel pro Kategorie mit Equality-Filter |
| `graduatedSymbol` | eine Regel pro Range mit Bereichsfilter |
| `RuleRenderer` | Regeln aus QML-Regeln, inklusive verschachtelter Regeln |
| `unknown` | Warning, keine Konvertierung |

Zusätzlich gilt:

- dokumentweite Scale Visibility wird in `ScaleDenominator` übersetzt
- bei `RuleRenderer` werden Parent- und Child-Filter kombiniert
- der erzeugte `Style.name` wird aktuell aus `QmlDocument.version`
  gesetzt, nicht aus einem fachlichen Layernamen

### Symbol-Layer

Aktuell mappt der Read-Pfad:

| QML Symbol-Layer | `mapstyler_style` |
|---|---|
| `SimpleFill` | `FillSymbolizer` |
| `SimpleLine` | `LineSymbolizer` |
| `SimpleMarker` | `MarkSymbolizer` |
| `SvgMarker` | `IconSymbolizer` |
| `RasterFill` | derzeit nicht gemappt, Warning |
| `unknown` | Warning |

Wichtige Details:

- `SimpleMarker.size` wird von QGIS-Durchmesser auf
  `MarkSymbolizer.radius` halbiert
- QGIS-Farben wie `"255,204,0,255"` werden in Hex plus Opacity
  übersetzt
- mehrere QML-Symbol-Layer ergeben mehrere Symbolizer innerhalb einer
  Regel

### Filter

Der Adapter erzeugt beim Lesen aktuell:

- Equality-Filter für `categorizedSymbol`
- Bereichsfilter mit `>=` und `<` für `graduatedSymbol`
- einfache kombinierte Filter aus `RuleRenderer`

Nicht alles aus der QGIS-Expressionsprache wird verstanden. Nicht
parsebare Filterstrings erzeugen Warnings.

## Mapping: mapstyler -> QML

### Renderer-Auswahl

Der Write-Pfad baut aktuell nicht alle QML-Renderer-Typen nach, sondern
verwendet eine einfache Strategie:

- keine Regeln -> `singleSymbol`
- genau eine Regel ohne Filter -> `singleSymbol`
- sonst -> `RuleRenderer`

Das heißt:

- `categorizedSymbol` und `graduatedSymbol` werden aktuell nicht gezielt
  erzeugt
- mehrere Regeln werden generell als `RuleRenderer` geschrieben

### Symbolizer

Aktuell werden diese Symbolizer geschrieben:

| `mapstyler_style` | QML-Ausgabe |
|---|---|
| `FillSymbolizer` | `SimpleFill` |
| `LineSymbolizer` | `SimpleLine` |
| `MarkSymbolizer` | `SimpleMarker` |
| `IconSymbolizer` | `SvgMarker` |
| `TextSymbolizer` | derzeit nicht unterstützt, Warning |
| `RasterSymbolizer` | derzeit nicht unterstützt, Warning |

Wichtige Details:

- `MarkSymbolizer.radius` wird beim Schreiben wieder zu QGIS-`size`
  verdoppelt
- `Style`-Regelfilter werden als QGIS-Filterstrings serialisiert, soweit
  es der aktuelle Mapper unterstützt
- `SpatialFilter` und `DistanceFilter` werden nicht als QGIS-Ausdruck
  geschrieben

## Farben

Die QML-Adapter-Schicht enthält Hilfsfunktionen zur Farbkonvertierung
zwischen QGIS-Strings und `mapstyler`-Werten.

Typische Richtung:

- QGIS `"r,g,b,a"` -> `"#rrggbb"` plus Opacity
- Hex plus Opacity -> QGIS `"r,g,b,a"`

Diese Utilities gehören bewusst in den Adapter und nicht in das
allgemeine Kernmodell.

## Dateistruktur

### `qml4dart`

```text
qml4dart/
├── lib/
│   ├── qml4dart.dart
│   └── src/
│       ├── model/
│       │   ├── qml_category.dart
│       │   ├── qml_document.dart
│       │   ├── qml_range.dart
│       │   ├── qml_renderer.dart
│       │   ├── qml_rule.dart
│       │   ├── qml_symbol.dart
│       │   ├── qml_symbol_layer.dart
│       │   └── qml_types.dart
│       ├── read/
│       │   └── read_result.dart
│       ├── write/
│       │   └── write_result.dart
│       ├── xml/
│       │   ├── xml_helpers.dart
│       │   ├── xml_reader.dart
│       │   └── xml_writer.dart
│       ├── qml_codec.dart
│       └── qml4dart_codec.dart
├── test/
├── example/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### `mapstyler_qml_adapter`

```text
mapstyler_qml_adapter/
├── lib/
│   ├── mapstyler_qml_adapter.dart
│   └── src/
│       ├── color_util.dart
│       ├── mapstyler_to_qml.dart
│       ├── qml_style_parser.dart
│       └── qml_to_mapstyler.dart
├── test/
├── example/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Testabdeckung im aktuellen Repo

Vorhandene Tests decken aktuell unter anderem ab:

- `qml4dart`: Parsing für `singleSymbol`, `categorizedSymbol`,
  `graduatedSymbol`, `RuleRenderer` und verschachtelte Regeln
- `qml4dart`: Roundtrips für mehrere Fixture-Typen
- `qml4dart`: Datei-Read/Write
- `mapstyler_qml_adapter`: Read-Mapping für Fill, Line, Marker,
  SvgMarker, Kategorien und Ranges
- `mapstyler_qml_adapter`: Write-Mapping für `singleSymbol` und
  `RuleRenderer`
- `mapstyler_qml_adapter`: Warnings bei fehlenden Symbolen oder nicht
  unterstützten Konstrukten

## Aktuelle Nicht-Ziele und Lücken

- vollständige Abdeckung der gesamten QGIS-Expressionsprache
- gezieltes Schreiben von `categorizedSymbol` oder `graduatedSymbol`
- vollständige Unterstützung von `TextSymbolizer` im QML-Write-Pfad
- vollständige Unterstützung von `RasterSymbolizer` im QML-Write-Pfad
- verlustfreier Roundtrip über `mapstyler_style`
- Erhalt aller QGIS-spezifischen Metadaten durch den Adapter
