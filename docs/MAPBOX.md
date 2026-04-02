# mapbox4dart — Mapbox GL Style JSON in Dart

Eigenständiges Pure-Dart-Package für das Lesen, Modellieren und Schreiben von Mapbox GL Style JSON (Version 8). Analog zu `qml4dart` für QGIS QML.

## Ausgangslage

Mapbox GL Style JSON (v8) ist das dominante Style-Format für Webkarten (Mapbox, MapLibre GL JS, MapLibre Native, react-map-gl, flutter_map mit vector tiles). Es gibt kein existierendes Pure-Dart-Package, das ein typisiertes Objektmodell für Mapbox Styles bereitstellt.

```
Mapbox GL JSON ──→ mapbox4dart (Objektmodell + Codec) ──→ mapstyler_mapbox_adapter
                                                              ↓
                                                        mapstyler_style
```

## Mapbox GL Style Spec (v8) — Überblick

### Root-Struktur

```json
{
  "version": 8,
  "name": "My Style",
  "metadata": {},
  "sources": {
    "openmaptiles": { "type": "vector", "url": "..." }
  },
  "sprite": "https://...",
  "glyphs": "https://.../{fontstack}/{range}.pbf",
  "layers": [ ... ]
}
```

| Feld | Typ | Beschreibung |
|---|---|---|
| `version` | `int` | Immer `8` |
| `name` | `String?` | Human-readable Name |
| `metadata` | `Map?` | Beliebige Metadaten (u.a. `geostyler:ref`) |
| `sources` | `Map<String, Source>` | Datenquellen (vector, raster, geojson, ...) |
| `sprite` | `String?` | URL zum Sprite-Atlas |
| `glyphs` | `String?` | URL-Template für Glyphen (Fonts) |
| `layers` | `List<Layer>` | Geordnete Liste der Style-Layer |
| `center` | `[lng, lat]?` | Initiale Kartenposition |
| `zoom` | `double?` | Initiale Zoomstufe |
| `bearing` | `double?` | Initiale Rotation |
| `pitch` | `double?` | Initialer Neigungswinkel |

### Source-Typen

| Typ | Beschreibung |
|---|---|
| `vector` | Vector Tiles (PBF) |
| `raster` | Raster Tiles (PNG/JPEG) |
| `raster-dem` | Höhenmodell-Tiles |
| `geojson` | Inline GeoJSON oder URL |
| `image` | Einzelbild mit Koordinaten |
| `video` | Video mit Koordinaten |

### Layer-Typen

Jeder Layer hat: `id`, `type`, `source?`, `source-layer?`, `filter?`, `paint`, `layout`, `minzoom?`, `maxzoom?`, `metadata?`.

| Typ | Beschreibung | Paint-Eigenschaften (Auswahl) | Layout (Auswahl) |
|---|---|---|---|
| `background` | Hintergrund-Füllung | `background-color`, `background-opacity`, `background-pattern` | `visibility` |
| `fill` | Polygon-Füllung | `fill-color`, `fill-opacity`, `fill-outline-color`, `fill-pattern`, `fill-antialias` | `visibility`, `fill-sort-key` |
| `line` | Linien/Striche | `line-color`, `line-width`, `line-opacity`, `line-dasharray`, `line-blur`, `line-gap-width`, `line-offset` | `visibility`, `line-cap`, `line-join`, `line-miter-limit`, `line-round-limit`, `line-sort-key` |
| `circle` | Punkt-Kreise | `circle-radius`, `circle-color`, `circle-opacity`, `circle-stroke-color`, `circle-stroke-width`, `circle-blur` | `visibility`, `circle-sort-key` |
| `symbol` | Text + Icons | `text-color`, `text-opacity`, `text-halo-color`, `text-halo-width`, `icon-opacity`, `icon-color` | `text-field`, `text-font`, `text-size`, `text-rotate`, `icon-image`, `icon-size`, `icon-rotate`, `symbol-placement`, `symbol-spacing` |
| `raster` | Raster-Tiles | `raster-opacity`, `raster-hue-rotate`, `raster-brightness-min`, `raster-brightness-max`, `raster-saturation`, `raster-contrast` | `visibility` |
| `fill-extrusion` | 3D-Gebäude | `fill-extrusion-color`, `fill-extrusion-height`, `fill-extrusion-base` | `visibility` |
| `hillshade` | Schummerung | `hillshade-illumination-direction`, `hillshade-shadow-color` | `visibility` |
| `heatmap` | Heatmap | `heatmap-radius`, `heatmap-weight`, `heatmap-intensity`, `heatmap-color` | `visibility` |

**Hinweis:** `fill-extrusion`, `hillshade`, `heatmap` und `sky` werden im Objektmodell als `MapboxLayer` mit `type: unknown` durchgereicht, aber nicht in typisierte Paint-Klassen zerlegt. Forward-kompatibel über `paint`/`layout` als `Map<String, dynamic>`.

### Besonderheit: `symbol`-Layer

Ein `symbol`-Layer kann **gleichzeitig** Text und Icons enthalten:
- `text-field` + `text-size` + `text-color` → Textdarstellung
- `icon-image` + `icon-size` → Icondarstellung
- `symbol-placement` ("point" / "line" / "line-center") gilt für beides

Bei der Konvertierung nach mapstyler_style entsteht daraus ein `TextSymbolizer` und/oder ein `IconSymbolizer` — im selben Rule.

### Filter

**Expression-basiert (v2, empfohlen):**
```json
["all",
  ["==", ["get", "type"], "residential"],
  [">", ["get", "area"], 1000]
]
```

**Legacy (v1, deprecated aber weit verbreitet):**
```json
["all",
  ["==", "type", "residential"],
  [">", "area", 1000]
]
```

Unterschied: v1 verwendet blanke Property-Namen als Strings, v2 verwendet `["get", "prop"]`-Expressions.

| Mapbox-Operator | Typ |
|---|---|
| `==`, `!=`, `<`, `>`, `<=`, `>=` | Vergleich |
| `all`, `any` | Logische Kombination |
| `!` | Negation |
| `has`, `!has` | Property-Existenzprüfung |
| `in`, `!in` | Wert in Liste |
| `none` | Alias für `!any` |

### Expression-System

Mapbox GL Expressions sind Array-basiert: `[operator, ...args]`. Sie können in Paint- und Layout-Properties sowie in Filtern vorkommen.

**Kategorien:**

| Kategorie | Operatoren (Auswahl) |
|---|---|
| **Lookup** | `get`, `has`, `id`, `geometry-type`, `properties`, `at`, `length` |
| **Math** | `+`, `-`, `*`, `/`, `%`, `^`, `abs`, `ceil`, `floor`, `round`, `sqrt`, `log`, `log2`, `ln`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `min`, `max`, `pi`, `e` |
| **String** | `concat`, `downcase`, `upcase`, `trim` |
| **Color** | `rgb`, `rgba`, `to-rgba` |
| **Entscheidung** | `case`, `match`, `coalesce`, `step`, `interpolate`, `interpolate-hcl`, `interpolate-lab` |
| **Vergleich** | `==`, `!=`, `<`, `>`, `<=`, `>=` |
| **Logik** | `all`, `any`, `!` |
| **Typ** | `typeof`, `to-string`, `to-number`, `to-boolean`, `to-color`, `literal` |
| **Variable** | `let`, `var` |
| **Zoom/Feature** | `zoom`, `feature-state` |

**Wichtige Expressions für mapstyler-Mapping:**

```
["get", "fieldname"]             → PropertyGet("fieldname")
["interpolate", mode, input, …]  → InterpolateFunction
["step", input, default, …]      → StepFunction
["case", c1, v1, c2, v2, fb]    → CaseFunction
["match", input, v1, o1, …, fb] → CaseFunction (umgeschrieben als Gleichheits-Kette)
["concat", a, b, c]              → ArgsFunction("strConcat")
["literal", value]               → LiteralExpression(value)
["zoom"]                          → ArgsFunction("zoom") (spezieller Input)
```

### Zoom ↔ ScaleDenominator

Mapbox verwendet Zoom-Level (0–24), OGC/GeoStyler verwendet Scale Denominators. Umrechnung (Web Mercator, 96 DPI):

```
scaleDenominator = 559_082_264.028 / 2^zoom
```

| Zoom | Scale Denominator |
|---|---|
| 0 | 559.082.264 |
| 5 | 17.471.321 |
| 10 | 545.979 |
| 15 | 17.062 |
| 18 | 2.133 |
| 22 | 133 |

**Achtung Inversions-Mapping:**
- `minzoom` (niedrigste erlaubte Zoomstufe = weitester Blick) → `ScaleDenominator.max` (größter Wert)
- `maxzoom` (höchste erlaubte Zoomstufe = nächster Blick) → `ScaleDenominator.min` (kleinster Wert)

### Farben

Mapbox unterstützt mehrere Farbformate:

| Format | Beispiel |
|---|---|
| Hex | `#ff0000`, `#f00` |
| RGB | `rgb(255, 0, 0)` |
| RGBA | `rgba(255, 0, 0, 0.5)` |
| HSL | `hsl(0, 100%, 50%)` |
| HSLA | `hsla(0, 100%, 50%, 0.5)` |
| CSS Named | `red`, `blue`, `transparent` |

Alle werden auf `#rrggbb` normalisiert (GeoStyler-Konvention). Opacity aus RGBA/HSLA wird separat extrahiert.

## Objektmodell — mapbox4dart

### Typübersicht

```
MapboxStyle
 ├── version: int (8)
 ├── name: String?
 ├── metadata: Map<String, dynamic>?
 ├── sources: Map<String, MapboxSource>
 ├── sprite: String?
 ├── glyphs: String?
 ├── layers: List<MapboxLayer>
 ├── center: (double, double)?
 ├── zoom: double?
 ├── bearing: double?
 └── pitch: double?

MapboxSource
 ├── type: MapboxSourceType (vector, raster, raster-dem, geojson, image, video)
 └── properties: Map<String, dynamic>  (url, tiles, data, etc.)

MapboxLayer
 ├── id: String
 ├── type: MapboxLayerType
 ├── source: String?
 ├── sourceLayer: String?
 ├── filter: dynamic (Expression oder null)
 ├── paint: Map<String, dynamic>
 ├── layout: Map<String, dynamic>
 ├── minzoom: double?
 ├── maxzoom: double?
 └── metadata: Map<String, dynamic>?
```

### Design-Entscheidungen

**Paint/Layout als `Map<String, dynamic>` (nicht typisierte Klassen):**
- Mapbox hat ~120 verschiedene Paint/Layout-Properties über alle Layer-Typen
- Jeder Property-Wert kann ein Literal oder eine Expression sein
- Typisierte Klassen für jeden Layer-Typ wären ~500 Zeilen Boilerplate mit geringem Mehrwert
- Properties werden vom Adapter sowieso einzeln ausgelesen
- Unbekannte Properties werden durchgereicht (Forward-Kompatibilität)

**Filter als `dynamic` (nicht typisiertes Expression-Modell):**
- Mapbox-Filter sind JSON-Arrays mit beliebiger Verschachtelung
- Die Expression-Semantik wird erst im Adapter interpretiert
- `mapbox4dart` bewahrt die Filter exakt wie im Original-JSON

**Sources als schwach typisierte Map:**
- Source-Typen haben unterschiedliche Felder (url, tiles, data, bounds, etc.)
- Ein vollständig typisiertes Source-Modell wäre umfangreich ohne klaren Mehrwert
- `MapboxSource.type` reicht für die Dispatch-Logik

### Codec-API

```dart
const codec = Mapbox4DartCodec();

// Lesen
final result = codec.parseString(jsonString);
switch (result) {
  case ReadMapboxSuccess(:final style, :final warnings): ...
  case ReadMapboxFailure(:final message): ...
}

// Schreiben
final result = codec.encodeString(style);
switch (result) {
  case WriteMapboxSuccess(:final json): ...
  case WriteMapboxFailure(:final message): ...
}
```

### Farb-Utilities

```dart
normalizeColor('rgba(255, 0, 0, 0.5)');  // → (hex: '#ff0000', opacity: 0.5)
normalizeColor('#f00');                    // → (hex: '#ff0000', opacity: null)
normalizeColor('red');                     // → (hex: '#ff0000', opacity: null)
```

## Dateistruktur

```
mapbox4dart/
├── lib/
│   ├── mapbox4dart.dart                    # Library-Export
│   └── src/
│       ├── model/
│       │   ├── mapbox_style.dart           # MapboxStyle (Root)
│       │   ├── mapbox_layer.dart           # MapboxLayer
│       │   ├── mapbox_source.dart          # MapboxSource
│       │   └── mapbox_types.dart           # Enums (LayerType, SourceType)
│       ├── read/
│       │   ├── read_result.dart            # ReadMapboxResult (sealed)
│       │   └── mapbox_reader.dart          # JSON → MapboxStyle
│       ├── write/
│       │   ├── write_result.dart           # WriteMapboxResult (sealed)
│       │   └── mapbox_writer.dart          # MapboxStyle → JSON
│       └── color_util.dart                 # Farb-Normalisierung
├── test/
│   ├── mapbox4dart_test.dart
│   └── color_util_test.dart
├── example/
│   └── mapbox4dart_example.dart
├── pubspec.yaml
├── CHANGELOG.md
├── README.md
└── LICENSE
```

## Abgrenzung

| Verantwortung | mapbox4dart | mapstyler_mapbox_adapter |
|---|---|---|
| JSON parsing/encoding | ✅ | ❌ |
| Typisiertes Objektmodell | ✅ | ❌ |
| Farb-Normalisierung | ✅ | ❌ |
| Expression → GeoStyler-Function | ❌ | ✅ |
| Filter → mapstyler-Filter | ❌ | ✅ |
| Layer → Symbolizer-Mapping | ❌ | ✅ |
| Zoom → ScaleDenominator | ❌ | ✅ |
| geostyler:ref Grouping | ❌ | ✅ |

## Implementierungsreihenfolge

1. Enums und Typen (`mapbox_types.dart`)
2. Modell-Klassen (`mapbox_style.dart`, `mapbox_layer.dart`, `mapbox_source.dart`)
3. Reader (`mapbox_reader.dart`) — JSON → MapboxStyle
4. Writer (`mapbox_writer.dart`) — MapboxStyle → JSON
5. Result-Typen (`read_result.dart`, `write_result.dart`)
6. Codec-Fassade (`mapbox4dart_codec.dart`)
7. Farb-Utilities (`color_util.dart`)
8. Tests + Fixtures
9. README, CHANGELOG, Example

## Aufwand

Geschätzt ~600–900 Zeilen Dart (deutlich weniger als `qml4dart`, da kein XML-Parsing — nur JSON-Mapping auf typisiertes Modell).

Die Komplexität liegt primär im **Adapter** (Expression-Konvertierung, Layer→Symbolizer-Mapping), nicht im Codec selbst.
