# Mapbox GL Spezifikation für `mapbox4dart` und `mapstyler_mapbox_adapter`

Dieses Dokument ist keine Bestandsbeschreibung, sondern die verbindliche
Implementierungsspezifikation für die noch ausstehenden Mapbox-Pakete im
Workspace.

## Zielbild

Die Mapbox-Unterstützung wird bewusst in zwei Pakete getrennt:

```text
Mapbox GL Style JSON
  -> mapbox4dart
     (Codec + eigenes Mapbox-Objektmodell)
  -> mapstyler_mapbox_adapter
     (Transformation Mapbox -> mapstyler_style)
  -> mapstyler_style
```

`mapbox4dart` besitzt ein eigenes Objektmodell für Mapbox-Styles. Es hängt
nicht von `mapstyler_style` ab.

`mapstyler_mapbox_adapter` hängt von `mapbox4dart` und `mapstyler_style` ab
und übernimmt ausschließlich die semantische Transformation.

Hinweis zum aktuellen Repo-Stand:
Im Workspace existiert derzeit ein Platzhalter-Package
`mapstyler_mapbox_adapter`. Fachlich ist hiermit das in diesem Dokument
beschriebene Adapter-Package gemeint, bis das Naming vereinheitlicht ist.

## Paketgrenzen

| Verantwortung | `mapbox4dart` | `mapstyler_mapbox_adapter` |
|---|---|---|
| JSON lesen/schreiben | `ja` | `nein` |
| Eigenes Mapbox-Objektmodell | `ja` | `nein` |
| Unknown-/Pass-through-Erhalt | `ja` | `nein` |
| Farb-Parsing und -Normalisierung | `ja` | `nein` |
| Mapbox-Filter interpretieren | `nein` | `ja` |
| Mapbox-Expressions interpretieren | `nein` | `ja` |
| Layer -> `mapstyler_style.Symbolizer` | `nein` | `ja` |
| Zoom -> `ScaleDenominator` | `nein` | `ja` |
| Rückschreiben von `Style` nach Mapbox | `nein` | `ja` |

## `mapbox4dart` MVP

### Zweck

`mapbox4dart` liest und schreibt Mapbox GL Style JSON v8 als unverfälschtes,
Mapbox-nahes Modell. Das Package bewertet keine Expressions fachlich und mappt
nichts nach `mapstyler_style`.

### Öffentliche API

```dart
library mapbox4dart;

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
  const ReadMapboxSuccess({
    required this.output,
    this.warnings = const [],
  });
}

final class ReadMapboxFailure extends ReadMapboxResult {
  final List<String> errors;
  const ReadMapboxFailure({required this.errors});
}

sealed class WriteMapboxResult {
  const WriteMapboxResult();
}

final class WriteMapboxSuccess extends WriteMapboxResult {
  final String output;
  final List<String> warnings;
  const WriteMapboxSuccess({
    required this.output,
    this.warnings = const [],
  });
}

final class WriteMapboxFailure extends WriteMapboxResult {
  final List<String> errors;
  const WriteMapboxFailure({required this.errors});
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
  final List<double>? center; // [lng, lat]
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

### Modell-Regeln

- Alle Klassen sind immutable und vergleichbar per `==`.
- `version` muss beim Lesen exakt `8` sein, sonst `ReadMapboxFailure`.
- `paint`, `layout`, `filter` und source-spezifische Felder bleiben Mapbox-nah
  und werden nicht in Fachtypen zerlegt.
- Unknown root fields landen in `MapboxStyle.extra`.
- Unknown layer fields landen in `MapboxLayer.extra`.
- Unknown source fields bleiben in `MapboxSource.properties`.
- Unknown layer/source types werden nicht verworfen, sondern als
  `unknown + rawType` erhalten.

### Read/Write-Vertrag

- Ziel ist semantischer Roundtrip, nicht byte-identischer Roundtrip.
- Reihenfolge von `layers` bleibt erhalten.
- Reihenfolge von `sources` und Map-Feldern soll beim Schreiben nach Möglichkeit
  erhalten bleiben; sie ist aber kein API-Vertrag.
- Unbekannte Felder müssen beim Roundtrip erhalten bleiben.
- JSON, das strukturell kein Mapbox-v8-Style ist, führt zu `Failure`.
- Typabweichungen in Pflichtfeldern führen zu `Failure`.
- Typabweichungen in optionalen oder unbekannten Feldern dürfen als Warning plus
  Ignorieren behandelt werden, aber nicht stillschweigend die Struktur brechen.

### Unterstützter Scope in `mapbox4dart`

| Bereich | MVP |
|---|---|
| Root-Felder `version`, `name`, `metadata`, `sources`, `sprite`, `glyphs`, `layers`, `center`, `zoom`, `bearing`, `pitch` | `ja` |
| Source-Typen `vector`, `raster`, `raster-dem`, `geojson`, `image`, `video` | `ja` |
| Layer-Typen `background`, `fill`, `line`, `circle`, `symbol`, `raster`, `fill-extrusion`, `hillshade`, `heatmap`, `sky` | `ja`, aber nur als Typ + Map-Felder |
| Fachliche Interpretation von `filter` | `nein` |
| Fachliche Interpretation von Expressions in `paint`/`layout` | `nein` |

## `mapstyler_mapbox_adapter` MVP

### Zweck

Der Adapter interpretiert `mapbox4dart`-Modelle und transformiert sie in
`mapstyler_style.Style` und zurück.

### Öffentliche API

Das Package implementiert das bestehende `StyleParser<String>`-Interface aus
`mapstyler_style` und bietet zusätzlich typsichere Ein-/Ausgänge auf Basis von
`MapboxStyle`.

```dart
final class MapboxStyleAdapter implements StyleParser<String> {
  const MapboxStyleAdapter({
    this.codec = const MapboxStyleCodec(),
  });

  @override
  String get title;

  @override
  Future<ReadStyleResult> readStyle(String input);

  @override
  Future<WriteStyleResult<String>> writeStyle(Style style);

  Future<ReadStyleResult> readMapboxStyle(MapboxStyle input);
  Future<WriteStyleResult<MapboxStyle>> writeMapboxStyle(Style style);
}
```

### Mapping-Regeln

| Mapbox Layer | `mapstyler_style` |
|---|---|
| `fill` | `FillSymbolizer` |
| `line` | `LineSymbolizer` |
| `circle` | `MarkSymbolizer` mit `wellKnownName: "circle"` |
| `symbol` mit `text-*` | `TextSymbolizer` |
| `symbol` mit `icon-*` | `IconSymbolizer` |
| `symbol` mit Text und Icon | ein `Rule` mit zwei Symbolizers |
| `raster` | `RasterSymbolizer` |
| `background` | nicht unterstützt, Warning |
| `fill-extrusion`, `hillshade`, `heatmap`, `sky` | nicht unterstützt, Warning |

### Source-Regeln

- `source` und `source-layer` bleiben im Adapter als Mapbox-spezifische
  Information relevant, werden aber nicht Teil von `mapstyler_style.Style`.
- Informationen, die für einen verlustärmeren Rückweg nötig sind, dürfen in
  `Rule.name` oder `Rule`-nahen Metadaten nicht versteckt werden.
- Wenn der Rückweg zusätzliche Mapbox-Metadaten braucht, sollen diese über
  dokumentierte Adapter-Hilfsstrukturen oder `metadata["geostyler:*"]`
  transportiert werden.

### Zoom -> `ScaleDenominator`

Die Umrechnung ist verbindlich:

```text
scaleDenominator = 559_082_264.028 / 2^zoom
```

Das Mapping lautet:

- `minzoom` -> `ScaleDenominator.max`
- `maxzoom` -> `ScaleDenominator.min`

### Filter-MVP

Beim Lesen müssen mindestens diese Mapbox-Filter unterstützt werden:

- Vergleich: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Kombination: `all`, `any`, `none`
- Negation: `!`
- Property-Existenz: `has`, `!has`
- Listenvergleich: `in`, `!in`
- Legacy-v1-Filter und expression-basierte v2-Filter

Nicht unterstützte Filter führen zu Warning und Überspringen des betroffenen
Layers. Sie führen nicht zu einem partiell falschen Filter.

### Expression-MVP

Beim Lesen und Schreiben müssen mindestens diese Expressions unterstützt werden:

- `get`
- `literal`
- `concat`
- `case`
- `match`
- `step`
- `interpolate` mit `linear` und `exponential`
- `zoom`
- einfache Literale: `String`, `num`, `bool`

Diese Expressions sind explizit nicht Teil des MVP:

- `let`, `var`
- `feature-state`
- `interpolate-hcl`, `interpolate-lab`
- `rgb`, `rgba`, `to-rgba`, `to-color`
- `geometry-type`, `id`, `properties`
- `collator`, `format`, `image`

Nicht unterstützte Expressions führen zu Warning und dazu, dass die konkrete
Property oder der Layer übersprungen wird. Das Verhalten muss pro Property
deterministisch dokumentiert sein.

### Schreibregeln (`Style` -> Mapbox)

- Pro `Rule` wird standardmäßig pro Symbolizer ein Mapbox-Layer erzeugt.
- Sonderfall: `TextSymbolizer` und `IconSymbolizer` im selben `Rule` dürfen zu
  einem gemeinsamen `symbol`-Layer zusammengeführt werden, wenn beide denselben
  Zoombereich und kompatible Layout-Werte haben.
- `MarkSymbolizer(wellKnownName: "circle")` wird als `circle`-Layer geschrieben.
- Andere `MarkSymbolizer`-Formen sind im MVP nicht schreibbar und führen zu
  Warning oder `WriteStyleFailure`, wenn kein degradierter Export definiert ist.
- `RasterSymbolizer` wird nur geschrieben, wenn genügend Mapbox-spezifische
  Source-/Layer-Information verfügbar ist.

### Error-/Warning-Vertrag im Adapter

- Invalides Mapbox-JSON oder invalides `MapboxStyle`-Modell -> `Failure`
- Nicht unterstützte, aber überspringbare Layer -> `Success` mit Warning
- Nicht unterstützte Expressions in einer einzelnen Property -> `Success` mit
  Warning, wenn der restliche Layer sinnvoll weiterverarbeitet werden kann
- Nicht schreibbare `Style`-Konstrukte ohne definierte Degradierung ->
  `WriteStyleFailure`

## Farben

`mapbox4dart` stellt Farb-Utilities bereit. Sie müssen mindestens diese Formate
verstehen:

- Hex
- RGB
- RGBA
- HSL
- HSLA
- CSS Named Colors

Verbindlicher Utility-Vertrag:

```dart
({String hex, double? opacity}) normalizeColor(String input);
```

`hex` ist immer `#rrggbb`. Alpha wird als `opacity` separat zurückgegeben.

## Dateistruktur

### `mapbox4dart`

```text
mapbox4dart/
├── lib/
│   ├── mapbox4dart.dart
│   └── src/
│       ├── model/
│       │   ├── mapbox_style.dart
│       │   ├── mapbox_layer.dart
│       │   ├── mapbox_source.dart
│       │   └── mapbox_types.dart
│       ├── read/
│       │   ├── read_result.dart
│       │   └── mapbox_reader.dart
│       ├── write/
│       │   ├── write_result.dart
│       │   └── mapbox_writer.dart
│       ├── codec/
│       │   └── mapbox_style_codec.dart
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
│       │   ├── filter_mapper.dart
│       │   ├── expression_mapper.dart
│       │   └── layer_to_rule_mapper.dart
│       └── write/
│           ├── symbolizer_mapper.dart
│           └── zoom_mapper.dart
├── test/
├── example/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Testmatrix

Vor einer ersten Veröffentlichung müssen mindestens diese Tests existieren:

- `mapbox4dart`: Root-Read für vollständigen v8-Style
- `mapbox4dart`: Roundtrip mit unbekannten Root-/Layer-Feldern
- `mapbox4dart`: Unknown Layer Type bleibt als `unknown + rawType` erhalten
- `mapbox4dart`: Farb-Normalisierung für Hex/RGB/RGBA/HSL/HSLA/named colors
- Adapter: `fill`, `line`, `circle`, `symbol(text)`, `symbol(icon)`, `raster`
- Adapter: `symbol` mit Text und Icon in einem Layer
- Adapter: Legacy-v1-Filter und Expression-v2-Filter
- Adapter: `minzoom`/`maxzoom` <-> `ScaleDenominator`
- Adapter: unsupported layer types erzeugen Warnings
- Adapter: `Style` -> Mapbox für `Fill`, `Line`, `circle`, `Text`, `Icon`
- Adapter: deterministische Warnings bei unsupported expressions

## Implementierungsreihenfolge

1. `mapbox4dart` Modell und Enums
2. `mapbox4dart` Reader
3. `mapbox4dart` Writer
4. `mapbox4dart` Codec und Result-Typen
5. `mapbox4dart` Farb-Utilities und Roundtrip-Tests
6. Adapter-Grundgerüst mit `StyleParser<String>`
7. Layer-Mapping `fill`, `line`, `circle`, `symbol`, `raster`
8. Filter-Mapping MVP
9. Expression-Mapping MVP
10. Write-Pfad `Style` -> Mapbox
11. Warnings, unsupported handling, Examples, README

## Nicht-Ziele für v1

- Vollständige Abdeckung der gesamten Mapbox-Expression-Sprache
- Vollständiger Support für `background`, `fill-extrusion`, `hillshade`,
  `heatmap`, `sky`
- Byte-identischer JSON-Roundtrip
- Rendern oder Auswerten von Sprites und Glyphen
