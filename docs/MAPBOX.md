# Mapbox GL in `mapstyler`

Dieses Dokument beschreibt den **aktuellen Implementierungsstand** von
`mapbox4dart` und `mapstyler_mapbox_adapter` im Repository. Maßgeblich
ist der Source Code.

## Überblick

Die Mapbox-Unterstützung ist in zwei Pakete getrennt:

```text
Mapbox GL Style JSON
  -> mapbox4dart
     (Codec + Mapbox-nahes Objektmodell)
  -> mapstyler_mapbox_adapter
     (Mapping zwischen Mapbox und mapstyler_style)
  -> mapstyler_style
```

Dabei gilt:

- `mapbox4dart` ist ein pure-Dart-Codec für Mapbox-GL-Style-JSON v8.
- `mapstyler_mapbox_adapter` stellt die öffentliche Konvertierungs-API
  für das mapstyler-Ökosystem bereit.
- `mapstyler_mapbox_adapter` nutzt `mapbox4dart` intern, exponiert
  dessen Objektmodell aber nicht in seiner Public API.

## Paketgrenzen

| Verantwortung | `mapbox4dart` | `mapstyler_mapbox_adapter` |
|---|---|---|
| JSON lesen/schreiben | `ja` | `ja`, über die öffentliche Adapter-API |
| Eigenes Mapbox-Objektmodell | `ja` | `nein`, nur intern genutzt |
| Unknown-/Pass-through-Erhalt auf Mapbox-Ebene | `ja` | `nein` |
| Farb-Normalisierung | `ja` | `nein` |
| Mapbox-Filter in `mapstyler_style.Filter` mappen | `nein` | `ja` |
| Mapbox-Expressions in `mapstyler_style.Expression` mappen | `nein` | `ja` |
| `Style` nach Mapbox-Layern schreiben | `nein` | `ja` |
| Zoom <-> `ScaleDenominator` umrechnen | `nein` | `ja` |

Wichtig: Die Verlusterhaltung unbekannter Felder gilt nur innerhalb
`mapbox4dart`. Sobald ein Style nach `mapstyler_style` gemappt wird, ist
dieser Pass-through nicht mehr Teil des Vertrags.

## `mapbox4dart`

### Aufgabe

`mapbox4dart` liest und schreibt Mapbox-GL-Style-JSON v8 in ein
Mapbox-nahes Dart-Modell. Das Package interpretiert Filter und
Expressions nicht fachlich; `paint`, `layout` und source-spezifische
Properties bleiben roh.

### Öffentliche API

```dart
final class MapboxStyleCodec {
  const MapboxStyleCodec();

  ReadMapboxResult readString(String input);
  ReadMapboxResult readJsonObject(Map<String, Object?> input);

  WriteMapboxResult writeString(MapboxStyle style);
  Map<String, Object?> writeJsonObject(MapboxStyle style);
}
```

```dart
sealed class ReadMapboxResult {
  const ReadMapboxResult();
}

final class ReadMapboxSuccess extends ReadMapboxResult {
  final MapboxStyle output;
  final List<String> warnings;
}

final class ReadMapboxFailure extends ReadMapboxResult {
  final List<String> errors;
}

sealed class WriteMapboxResult {
  const WriteMapboxResult();
}

final class WriteMapboxSuccess extends WriteMapboxResult {
  final String output;
  final List<String> warnings;
}

final class WriteMapboxFailure extends WriteMapboxResult {
  final List<String> errors;
}
```

### Objektmodell

```dart
final class MapboxStyle {
  final int version;
  final String? name;
  final Map<String, Object?> metadata;
  final Map<String, MapboxSource> sources;
  final String? sprite;
  final String? glyphs;
  final List<MapboxLayer> layers;
  final List<double>? center;
  final double? zoom;
  final double? bearing;
  final double? pitch;
  final Map<String, Object?> extra;
}

enum MapboxSourceType {
  vector,
  raster,
  rasterDem,
  geojson,
  image,
  video,
  unknown,
}

final class MapboxSource {
  final MapboxSourceType type;
  final String rawType;
  final Map<String, Object?> properties;
}

enum MapboxLayerType {
  background,
  fill,
  line,
  circle,
  symbol,
  raster,
  fillExtrusion,
  hillshade,
  heatmap,
  sky,
  unknown,
}

final class MapboxLayer {
  final String id;
  final MapboxLayerType type;
  final String rawType;
  final String? source;
  final String? sourceLayer;
  final List<Object?>? filter;
  final Map<String, Object?> paint;
  final Map<String, Object?> layout;
  final double? minzoom;
  final double? maxzoom;
  final Map<String, Object?> metadata;
  final Map<String, Object?> extra;
}
```

### Aktuelles Verhalten

- `version` muss beim Lesen exakt `8` sein, sonst `ReadMapboxFailure`.
- `layers` muss eine Liste sein, sonst `ReadMapboxFailure`.
- `sources` wird gelesen, wenn es ein JSON-Objekt ist; fehlerhafte
  einzelne Sources erzeugen Warnings.
- unbekannte Root-Felder landen in `MapboxStyle.extra`
- unbekannte Layer-Felder landen in `MapboxLayer.extra`
- unbekannte Source-Felder bleiben in `MapboxSource.properties`
- unbekannte Layer-/Source-Typen bleiben als `unknown + rawType`
  erhalten
- `writeString` erzeugt formatiertes JSON
- `writeJsonObject` und `writeString` schreiben `sources` immer als Map;
  bei leerem Inhalt also als leeres Objekt

### Scope

| Bereich | Aktueller Stand |
|---|---|
| Root-Felder `version`, `name`, `metadata`, `sources`, `sprite`, `glyphs`, `layers`, `center`, `zoom`, `bearing`, `pitch` | unterstützt |
| Source-Typen `vector`, `raster`, `raster-dem`, `geojson`, `image`, `video` | unterstützt |
| Layer-Typen `background`, `fill`, `line`, `circle`, `symbol`, `raster`, `fill-extrusion`, `hillshade`, `heatmap`, `sky` | unterstützt als Typ + rohe Felder |
| Fachliche Interpretation von `filter` | nicht Teil von `mapbox4dart` |
| Fachliche Interpretation von Expressions in `paint`/`layout` | nicht Teil von `mapbox4dart` |

## `mapstyler_mapbox_adapter`

### Aufgabe

`mapstyler_mapbox_adapter` konvertiert zwischen Mapbox-GL-Style-JSON und
`mapstyler_style.Style`.

Die öffentliche API arbeitet aktuell auf JSON-String-Basis:

```dart
class MapboxStyleAdapter {
  const MapboxStyleAdapter();

  String get title;

  Future<ReadStyleResult> readStyle(String input);
  Future<WriteStyleResult<String>> writeStyle(Style style);
}
```

Intern sieht der Datenfluss so aus:

```text
readStyle(String)
  -> mapbox4dart.MapboxStyleCodec.readString
  -> MapboxStyle
  -> mapstyler_style.Style

writeStyle(Style)
  -> MapboxStyle
  -> mapbox4dart.MapboxStyleCodec.writeString
  -> String
```

### Wichtige Folgen dieser Architektur

- Die Public API des Adapters exponiert `MapboxStyle` nicht.
- Informationen wie `source`, `source-layer`, `metadata`, `sprite`,
  `glyphs` oder unbekannte Felder werden beim Mapping nach
  `mapstyler_style` nicht erhalten.
- Der Write-Pfad erzeugt ein neues Mapbox-Style-Modell aus dem
  `Style`. Standardmäßig setzt er nur `version`, optional `name` und die
  generierten `layers`.

## Layer-Mapping: Lesen

Aktuell werden diese Layer-Typen gelesen:

| Mapbox Layer | Ergebnis in `mapstyler_style` |
|---|---|
| `fill` | `FillSymbolizer` |
| `line` | `LineSymbolizer` |
| `circle` | `MarkSymbolizer` mit `wellKnownName: "circle"` |
| `symbol` mit `text-field` | `TextSymbolizer` |
| `symbol` mit `icon-image` | `IconSymbolizer` |
| `symbol` mit Text und Icon | ein `Rule` mit zwei Symbolizern |
| `raster` | `RasterSymbolizer` |
| `background` | Warning, Layer wird ausgelassen |
| `fill-extrusion`, `hillshade`, `heatmap`, `sky`, `unknown` | Warning, Layer wird ausgelassen |

Zusätzlich gilt:

- `Rule.name` wird aus `layer.id` übernommen.
- `minzoom` und `maxzoom` werden in `ScaleDenominator` übersetzt.
- `source` und `source-layer` werden aktuell nicht in das Kernmodell
  übertragen.

## Layer-Mapping: Schreiben

Der Write-Pfad erzeugt aktuell pro Symbolizer genau einen Mapbox-Layer.

| `mapstyler_style` | Mapbox-Ausgabe |
|---|---|
| `FillSymbolizer` | `fill` |
| `LineSymbolizer` | `line` |
| `MarkSymbolizer(wellKnownName: "circle")` | `circle` |
| anderer `MarkSymbolizer` | Warning, Symbolizer wird ausgelassen |
| `IconSymbolizer` | `symbol` mit `icon-*` |
| `TextSymbolizer` | `symbol` mit `text-*` |
| `RasterSymbolizer` | `raster` |

Wichtig:

- `TextSymbolizer` und `IconSymbolizer` werden aktuell **nicht** in
  einen gemeinsamen `symbol`-Layer zusammengeführt.
- Nicht schreibbare Mark-Symbolizer führen derzeit zu Warning und werden
  ausgelassen, nicht zu `WriteStyleFailure`.
- Der aktuelle Raster-Export erzeugt zwar `raster`-Layer, setzt aber
  keine passenden `sources`.

## Zoom <-> `ScaleDenominator`

Die Umrechnung verwendet aktuell:

```text
scaleDenominator = 559_082_264.028 / 2^zoom
```

Das Mapping lautet:

- `minzoom` -> `ScaleDenominator.max`
- `maxzoom` -> `ScaleDenominator.min`
- `ScaleDenominator.max` -> `minzoom`
- `ScaleDenominator.min` -> `maxzoom`

## Filter-Mapping

### Lesen

Aktuell unterstützt der Reader:

- Vergleich: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Kombination: `all`, `any`, `none`
- Negation: `!`
- Property-Existenz: `has`, `!has`
- Listenvergleich: `in`, `!in`
- Legacy-v1-Filter und expression-basierte Varianten mit `["get", ...]`

Einschränkungen des aktuellen Codes:

- `has` wird als `!= ''` approximiert
- `!has` wird als `== ''` approximiert
- unbekannte Filteroperatoren erzeugen eine Warning
- bei nicht unterstützten Filtern wird der Layer **nicht** verworfen;
  stattdessen entsteht eine `Rule` ohne Filter, sofern der Layer-Typ
  selbst unterstützt wird

### Schreiben

Aktuell unterstützt der Writer:

- `ComparisonFilter`
- `CombinationFilter`
- `NegationFilter`

Nicht unterstützt beim Schreiben:

- `SpatialFilter`
- `DistanceFilter`

Für diese beiden Fälle wird eine Warning erzeugt und der Filter im
Mapbox-Layer weggelassen.

## Expression-Mapping

### Lesen

Aktuell unterstützt der Reader diese Mapbox-Expressions:

- `get`
- `literal`
- `interpolate`
- `step`
- `case`
- `match`
- `concat`
- `zoom`
- `to-string`
- einfache Literale: `String`, `num`, `bool`

Nicht unterstützte Expressions erzeugen eine Warning und führen auf
Property-Ebene zu `null`. Das Verhalten hängt vom jeweiligen Mapping ab:

- bei optionalen Properties entfällt der Wert
- bei `text-field` wird auf einen leeren Literal-String zurückgefallen

### Schreiben

Der Writer serialisiert aktuell:

- `LiteralExpression`
- `FunctionExpression(PropertyGet)`
- `FunctionExpression(ArgsFunction)`
- `FunctionExpression(InterpolateFunction)`
- `FunctionExpression(StepFunction)`
- `FunctionExpression(CaseFunction)`

Für `ArgsFunction` werden derzeit nur diese Namen aktiv umgeschrieben:

- `strConcat` -> `concat`
- `toString` -> `to-string`
- `zoom` -> `zoom`

Andere Funktionsnamen werden unverändert in das Mapbox-Array geschrieben.
Der Writer validiert nicht, ob diese Namen in Mapbox tatsächlich erlaubt
sind.

## Farben

`mapbox4dart` exportiert `normalizeColor(String input)`.

Aktueller Vertrag:

```dart
({String hex, double? opacity})? normalizeColor(String input);
```

Unterstützte Formate:

- Hex (`#rgb`, `#rrggbb`, `#rgba`, `#rrggbbaa`)
- `rgb(...)`
- `rgba(...)`
- `hsl(...)`
- `hsla(...)`
- CSS Named Colors

Rückgabeverhalten:

- `hex` ist immer `#rrggbb`
- Alpha wird als separates `opacity` zurückgegeben
- bei nicht parsebaren Eingaben ist das Ergebnis `null`

## Dateistruktur

### `mapbox4dart`

```text
mapbox4dart/
├── lib/
│   ├── mapbox4dart.dart
│   └── src/
│       ├── codec/
│       │   └── mapbox_style_codec.dart
│       ├── model/
│       │   ├── mapbox_layer.dart
│       │   ├── mapbox_source.dart
│       │   ├── mapbox_style.dart
│       │   └── mapbox_types.dart
│       ├── read/
│       │   ├── mapbox_reader.dart
│       │   └── read_result.dart
│       ├── write/
│       │   ├── mapbox_writer.dart
│       │   └── write_result.dart
│       └── color_util.dart
├── test/
├── example/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### `mapstyler_mapbox_adapter`

```text
mapstyler_mapbox_adapter/
├── lib/
│   ├── mapstyler_mapbox_adapter.dart
│   └── src/
│       ├── mapbox_style_adapter.dart
│       ├── read/
│       │   ├── expression_mapper.dart
│       │   ├── filter_mapper.dart
│       │   ├── layer_to_rule_mapper.dart
│       │   └── zoom_mapper.dart
│       └── write/
│           └── symbolizer_mapper.dart
├── test/
├── example/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Testabdeckung im aktuellen Repo

Vorhandene Tests decken aktuell unter anderem ab:

- `mapbox4dart`: Lesen, Schreiben, Version-Validierung und Roundtrip
- `mapbox4dart`: Erhalt unbekannter Root-/Layer-/Source-Felder
- `mapbox4dart`: unbekannte Layer- und Source-Typen
- `mapbox4dart`: Farb-Normalisierung
- Adapter: `fill`, `line`, `circle`, `symbol(text)`, `symbol(icon)`,
  `raster`
- Adapter: Filter-Mapping
- Adapter: `minzoom`/`maxzoom` <-> `ScaleDenominator`
- Adapter: Warning-Verhalten bei unsupported layers
- Adapter: Write-Pfad für `Fill`, `Line`, `Mark(circle)`, `Text`
- Adapter: einfacher Read-Write-Read-Roundtrip

## Aktuelle Nicht-Ziele und Lücken

- vollständige Abdeckung der gesamten Mapbox-Expression-Sprache
- verlustfreier Roundtrip über `mapstyler_style`
- Unterstützung für `background`, `fill-extrusion`, `hillshade`,
  `heatmap`, `sky`
- automatischer Erhalt oder Wiederaufbau von `sources`, `source-layer`,
  `sprite`, `glyphs` im Adapter-Write-Pfad
- Validierung beliebiger `ArgsFunction`-Namen gegen die Mapbox-Spezifikation
