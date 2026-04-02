# mapstyler — Kartographische Stile in Dart

Eigenständiges Dart-Ökosystem für kartographische Style-Formate, inspiriert von [GeoStyler](https://geostyler.org/) (TypeScript). Kompatibel mit dem GeoStyler-JSON-Zwischenformat, aber mit eigenen Erweiterungen (Spatial Filters, OGC-konforme Geometrie-Modelle) und unabhängiger Weiterentwicklung.

## Ausgangslage

GeoStyler ist ein OSGeo-Projekt, das als universaler Konverter zwischen kartographischen Style-Formaten dient. Es besteht aus einem Kern-Typsystem und modularen Parsern:

**TypeScript-Original:**

```
geostyler-style (Kern-Typen, ~2.200 Zeilen, 0 Dependencies)
    ↑
    ├── geostyler-sld-parser      (~3.700 Zeilen)
    ├── geostyler-mapbox-parser   (~2.400 Zeilen)
    ├── geostyler-qgis-parser     (~1.450 Zeilen + ~177 CQL)
    └── geostyler-lyrx-parser     (~4.470 Zeilen, read-only)
```

**Geplante Dart-Portierung:**

```
mapstyler_style (Kern-Typen, basierend auf GeoStyler + eigene Erweiterungen)
    ↑
    ├── mapstyler_mapbox_adapter   (basierend auf GeoStyler TS)
    ├── mapstyler_sld_adapter     (Mapping-Layer auf flutter_map_sld)
    ├── mapstyler_qml_adapter     (Adapter von qml4dart nach mapstyler_style, optional)
    └── mapstyler_lyrx_parser     (basierend auf GeoStyler TS, optional)

flutter_map_sld (bestehend, pure Dart) ──→ mapstyler_sld_adapter
qml4dart (eigenständiges QGIS-QML-Package) ──→ mapstyler_qml_adapter
```

Alle Parser und Adapter sind unabhängig voneinander. Nur die mapstyler-Parser selbst implementieren das gemeinsame `StyleParser<T>`-Interface; `qml4dart` bleibt bewusst ein eigenständiges QML-Package.

## Lizenz

GeoStyler steht unter der **BSD-2-Clause**-Lizenz. Eine Portierung ist erlaubt, erfordert aber:
- Beibehaltung des Copyright-Hinweises in jeder Datei
- Nennung der Originalautoren in der Lizenz-Datei
- Kennzeichnung als abgeleitetes Werk (kein Originalprojekt vortäuschen)

Bei Veröffentlichung auf pub.dev muss die BSD-2-Clause-Lizenz im Dart-Package beibehalten werden.

## Quell-Versionen

Die Portierung basiert auf folgenden Versionen (Stand März 2026):

| Package | Version | Commit/Tag |
|---|---|---|
| `geostyler-style` | _vor Beginn festlegen_ | _pinnen_ |
| `geostyler-mapbox-parser` | _vor Beginn festlegen_ | _pinnen_ |
| `geostyler-lyrx-parser` | _vor Beginn festlegen_ | _pinnen_ |

`geostyler-sld-parser` wird nicht direkt portiert (siehe Phase 3 – Adapter-Ansatz mit `flutter_map_sld`). Die 121 SLD-Test-Fixtures daraus dienen aber als Referenz für Round-Trip-Tests. `geostyler-qgis-parser` wird ebenfalls nicht direkt portiert; für QML ist stattdessen ein eigenständiges Package `qml4dart` plus separater `mapstyler_qml_adapter` vorgesehen.

### Upstream-Sync

| Frage | Antwort |
|---|---|
| Wann prüfen? | Nach Abschluss jeder Phase und bei neuen GeoStyler-Releases |
| Wer prüft? | Maintainer des Dart-Ports vergleicht Changelogs und Diffs |
| Wie? | `git diff` zwischen gepinntem Tag und aktuellem `main` im TS-Repo |
| Breaking Changes? | Werden als eigene Issues im Dart-Repo erfasst und priorisiert |
| Patch-Updates? | Bugfixes im TS-Original werden zeitnah übernommen |

## Warum mapstyler?

- Kein nativer Dart-Konverter zwischen Standard-Style-Formaten vorhanden
- GeoStyler CLI/REST erfordert Node.js oder Docker – unhandlich für mobile Apps
- Dart `sealed class` und Pattern Matching eignen sich hervorragend für das Typ-System
- Direkte Integration in Flutter-Map-Anwendungen ohne Umwege
- Eigenständiges Projekt ermöglicht Erweiterungen (Spatial Filters, OGC-Geometrien) ohne Upstream-Abhängigkeit

## Plattform-Strategie

Alle Packages werden als **pure Dart** implementiert (keine Flutter-Abhängigkeit). Damit sind sie nutzbar in:
- Flutter-Apps (Android, iOS, Web, Desktop)
- Dart CLI-Tools
- Dart-Server-Anwendungen

Flutter-spezifische Adapter werden als separate Packages bereitgestellt:
- `flutter_mapstyler` — rendert `mapstyler_style`-Typen auf `flutter_map` (siehe [flutter_mapstyler.md](flutter_mapstyler.md))

## Architektur-Mapping: TypeScript → Dart

| TypeScript-Konzept | Dart-Äquivalent |
|---|---|
| `interface` / `type` | `class` / `sealed class` |
| Union Types (`A \| B \| C`) | `sealed class` mit Subklassen |
| `Expression<T> = T \| GeoStylerFunction` | `sealed class Expression<T>` mit `LiteralExpression<T>` und `FunctionExpression<T>` |
| Typeguards (`isMarkSymbolizer()`) | Native `is`-Checks / Pattern Matching (`switch`-Expressions) |
| `StyleParser<T>` Interface | `abstract class StyleParser<T>` |
| `Promise<ReadStyleResult>` | `Future<ReadStyleResult>` |
| Error-Handling (nie throw, Result-Objekte) | `sealed class Result` mit `Success`/`Failure`-Subklassen |
| Optionale Properties (`color?: string`) | Nullable Types (`String? color`) — Dart Sound Null Safety |

## Serialisierung

Alle Typen benötigen JSON-Serialisierung (`fromJson`/`toJson`) für die Parser.

### Entscheidung: Manuell ✅

Evaluiert per Prototyp (`prototypes/mapstyler_style_manual/` vs. `prototypes/mapstyler_style_mappable/`). Beide bestehen identische Tests (23/23).

| Ansatz | Ergebnis |
|---|---|
| ~~**`freezed` + `json_serializable`**~~ | **Ausgeschlossen.** freezed erzwingt eigene Union-Klassen, keine handgeschriebenen sealed-Hierarchien möglich. |
| ~~**`dart_mappable`**~~ | **Ausgeschlossen.** Serialisierung musste trotzdem manuell bleiben (Array-Filter, Dual-Format-Expressions, args-Array-Funktionen — alles Nicht-Standard-JSON). Nur Equality/hashCode wurde generiert (16% Zeilenersparnis). Dafür: Runtime-Dependency, 67 Extra-Packages, Build-Step, Namenskonflikt (`toJson()` → `toGeoJson()`). |
| **Manuell** ✅ | **Gewählt.** Volle Kontrolle über GeoStyler-JSON-Formate. Keine Dependencies. 427 Zeilen für 12 Prototyp-Typen (Expression, Filter, Symbolizer, Rule). |

**Begründung:** GeoStyler-JSON verwendet drei verschiedene Serialisierungsformate (Array-Filter, Rohwert-Expressions, Map-Symbolizer). Code-Generierung kann keines der beiden nicht-Standard-Formate abdecken und erzeugt Namenskonflikte. Der Mehraufwand für manuelle Equality (~4 Zeilen pro Klasse) ist bei ~140 Typen vertretbar.

**Prototyp-Referenz:** `prototypes/mapstyler_style_manual/lib/src/` enthält die Muster für alle Typ-Kategorien.

## Das GeoStyler-JSON-Format

GeoStyler definiert ein eigenes JSON-basiertes Zwischenformat – das zentrale Austauschformat des mapstyler-Kerns. Die mapstyler-Parser und -Adapter konvertieren **von** ihrem Format **in** dieses Format und umgekehrt:

```
SLD XML ──────┐                                    ┌──→ SLD XML
Mapbox GL JSON┤                                    ├──→ Mapbox GL JSON
QGIS QML ──→ qml4dart ──→ mapstyler_qml_adapter ───┤
LYRX JSON ────┘                                    └──→ ...
                         GeoStyler JSON (Zwischenformat)
```

### Beispiel: GeoStyler-JSON

```json
{
  "name": "Flächennutzungsplan",
  "rules": [
    {
      "name": "Wohngebiet",
      "filter": ["==", "landuse", "residential"],
      "scaleDenominator": {
        "min": 0,
        "max": 50000
      },
      "symbolizers": [
        {
          "kind": "Fill",
          "color": "#ffcc00",
          "opacity": 0.5,
          "outlineColor": "#aa8800",
          "outlineWidth": 1.5
        }
      ]
    },
    {
      "name": "Wald",
      "filter": ["==", "landuse", "forest"],
      "symbolizers": [
        {
          "kind": "Fill",
          "color": "#228B22",
          "opacity": 0.6
        }
      ]
    },
    {
      "name": "Straßen",
      "filter": ["==", "type", "road"],
      "symbolizers": [
        {
          "kind": "Line",
          "color": "#333333",
          "width": 2,
          "dasharray": [10, 5],
          "cap": "round",
          "join": "round"
        }
      ]
    },
    {
      "name": "Krankenhäuser",
      "filter": ["==", "amenity", "hospital"],
      "symbolizers": [
        {
          "kind": "Mark",
          "wellKnownName": "cross",
          "color": "#ff0000",
          "radius": 8,
          "strokeColor": "#990000",
          "strokeWidth": 1
        },
        {
          "kind": "Text",
          "label": {
            "name": "property",
            "args": ["name"]
          },
          "size": 12,
          "color": "#333333",
          "haloColor": "#ffffff",
          "haloWidth": 2
        }
      ]
    }
  ]
}
```

### Bedeutung für die Dart-Portierung

Das `mapstyler_style`-Package in Phase 1 ist **gleichzeitig** das Typsystem und der GeoStyler-JSON-Serializer:

| Funktion | Methode |
|---|---|
| GeoStyler-JSON lesen | `Style.fromJson(Map<String, dynamic> json)` |
| GeoStyler-JSON schreiben | `style.toJson()` → `Map<String, dynamic>` |
| Als String laden | `Style.fromJson(jsonDecode(jsonString))` |
| Als String exportieren | `jsonEncode(style.toJson())` |

Damit kann man GeoStyler-JSON direkt lesen und schreiben – ohne einen formatspezifischen Parser. Die Parser (Mapbox, SLD, etc.) konvertieren lediglich zwischen ihrem Format und diesen Dart-Typen.

```dart
// GeoStyler-JSON direkt laden
final json = jsonDecode(File('style.geostyler').readAsStringSync());
final style = Style.fromJson(json);

// Durch Regeln und Symbolizer iterieren
for (final rule in style.rules) {
  print('Regel: ${rule.name}');
  for (final symbolizer in rule.symbolizers) {
    switch (symbolizer) {
      case FillSymbolizer(:final color) => print('  Fläche: $color'),
      case LineSymbolizer(:final width) => print('  Linie: Breite $width'),
      case MarkSymbolizer(:final wellKnownName) => print('  Punkt: $wellKnownName'),
      case TextSymbolizer(:final label) => print('  Label: $label'),
      case _ => print('  Sonstiges'),
    }
  }
}

// Wieder als GeoStyler-JSON exportieren
File('output.geostyler').writeAsStringSync(jsonEncode(style.toJson()));
```

## Quellcode-Struktur von geostyler-style

Das Kern-Package definiert ~140 Typen in 3 Dateien:

| Datei | Zeilen | Inhalt |
|---|---|---|
| `style.ts` | 1.088 | Style, Rule, Symbolizer-Hierarchie, Filter, Expression, StyleParser-Interface |
| `functions.ts` | 811 | ~60 GeoStyler-Funktionen (Math, String, Boolean, Case/Step/Interpolate) |
| `typeguards.ts` | 293 | Runtime-Typprüfungen |

### Typ-Hierarchie

```
Style
 └── Rule[]
      ├── Symbolizer[]
      │    ├── MarkSymbolizer
      │    ├── IconSymbolizer
      │    ├── TextSymbolizer
      │    ├── LineSymbolizer
      │    ├── FillSymbolizer
      │    └── RasterSymbolizer
      ├── Filter?
      │    ├── ComparisonFilter (==, !=, <, >, <=, >=, Between, Like, IsNull)
      │    ├── CombinationFilter (And, Or)
      │    ├── NegationFilter (Not)
      │    └── SpatialFilter (Dart-Erweiterung, OGC Filter Encoding 2.0)
      │         ├── BBox, Intersects, Within, Contains
      │         ├── Touches, Crosses, Overlaps, Disjoint
      │         └── DistanceFilter (DWithin, Beyond)
      └── ScaleDenominator?
           ├── min
           └── max
```

### Expression-System

```
Expression<T>
 ├── LiteralExpression<T> (konkreter Wert)
 └── FunctionExpression<T>
      ├── Numerisch (~30): add, subtract, multiply, divide, abs, ceil, floor, ...
      ├── String (~13): strConcat, strToLower, strToUpper, strTrim, ...
      ├── Boolean (~17): all, any, between, equalTo, greaterThan, ...
      └── Kontrollfluss: case, step, interpolate, property
```

In TypeScript ist `Expression<T> = T | GeoStylerFunction` ein einfacher Union Type. In Dart erfordert das eine explizite sealed-class-Hierarchie, was verbloser ist aber dafür typsicheres Pattern Matching ermöglicht:

```dart
// TypeScript (kompakt):
radius: 12                          // Literal
radius: { name: 'property', args: { name: 'size' } }  // Funktion

// Dart (expliziter, aber typsicher):
radius: LiteralExpression(12.0),                        // Literal
radius: FunctionExpression(PropertyGet('size')),         // Funktion

// Pattern Matching auf Expressions:
switch (symbolizer.radius) {
  LiteralExpression(:final value) => 'Fester Wert: $value',
  FunctionExpression(:final function) => 'Dynamisch: $function',
  null => 'Nicht gesetzt',
}
```

## Implementierungs-Plan

### Phase 1 – `mapstyler_style` (Kern-Typen)

**Ziel:** Dart-Package mit allen Datenstrukturen und dem Parser-Interface.

**Aufwand:** Mittel (~2.200 Zeilen TS → geschätzt ~2.500–3.500 Zeilen Dart, wegen Konstruktoren, Serialisierung, Equality)

**Dependencies:** Keine (ggf. `json_annotation` bei Code-Generierung)

**Umfang:**
- Alle Symbolizer als `sealed class Symbolizer` mit Subklassen
- Filter als `sealed class Filter` mit Comparison/Combination/Negation
- Expression als `sealed class Expression<T>` mit `LiteralExpression`/`FunctionExpression`
- ~60 GeoStyler-Funktionen als Klassen
- **Spatial Filters: Option (a) gewählt — in `mapstyler_style` aufnehmen.** Das TS-Original kennt keine Spatial Filters, aber `flutter_map_sld` ≥0.5.0 und der OGC-Standard (Filter Encoding 2.0) schon. Die Entscheidung:
  - ~~(b) Nur im Adapter~~ — verwirft Spatial Filter-Information beim Konvertieren, unakzeptabel für SLD-Workflows
  - ~~(c) Extension-Package~~ — **technisch unmöglich**, da Dart's `sealed class` keine Erweiterung außerhalb der Library erlaubt
  - **(a) Erweitern** ✅ — `SpatialFilter` als Subklasse von `Filter` in `mapstyler_style`. Gekennzeichnet als Dart-Erweiterung über das TS-Original hinaus. Muss in Phase 1 implementiert werden (sealed class nachträglich erweitern = Breaking Change). Spatial Filters werden als OGC-konforme Ergänzung positioniert, nicht als Abweichung.
- `StyleParser<T>` als abstract class
- `ReadStyleResult` / `WriteStyleResult` mit Error-Handling
- `UnsupportedProperties` für Parser-Feedback
- `fromJson`/`toJson` für alle Typen

**Beispiel-Skizze:**

```dart
// --- Expression ---

sealed class Expression<T> {
  const Expression();
}

class LiteralExpression<T> extends Expression<T> {
  final T value;
  const LiteralExpression(this.value);
}

class FunctionExpression<T> extends Expression<T> {
  final GeoStylerFunction function;
  const FunctionExpression(this.function);
}

// --- Symbolizer ---

sealed class Symbolizer {
  final double? opacity;
  const Symbolizer({this.opacity});
}

class MarkSymbolizer extends Symbolizer {
  final WellKnownName wellKnownName;
  final Expression<double>? radius;
  final Expression<String>? color;
  final Stroke? stroke;

  const MarkSymbolizer({
    required this.wellKnownName,
    this.radius,
    this.color,
    this.stroke,
    super.opacity,
  });
}

class LineSymbolizer extends Symbolizer {
  final Expression<String>? color;
  final Expression<double>? width;
  final List<double>? dasharray;
  final LineCap? cap;
  final LineJoin? join;

  const LineSymbolizer({
    this.color,
    this.width,
    this.dasharray,
    this.cap,
    this.join,
    super.opacity,
  });
}

class FillSymbolizer extends Symbolizer {
  final Expression<String>? color;
  final Stroke? outlineStroke;

  const FillSymbolizer({
    this.color,
    this.outlineStroke,
    super.opacity,
  });
}

// --- Filter ---

sealed class Filter {
  const Filter();
}

class ComparisonFilter extends Filter {
  final ComparisonOperator operator;
  final Expression property;
  final Expression value;

  const ComparisonFilter({
    required this.operator,
    required this.property,
    required this.value,
  });
}

class CombinationFilter extends Filter {
  final CombinationOperator operator;
  final List<Filter> filters;

  const CombinationFilter({
    required this.operator,
    required this.filters,
  });
}

class NegationFilter extends Filter {
  final Filter filter;
  const NegationFilter({required this.filter});
}

// --- Parser-Interface ---

abstract class StyleParser<T> {
  String get title;
  UnsupportedProperties? get unsupportedProperties;
  Future<ReadStyleResult> readStyle(T input);
  Future<WriteStyleResult<T>> writeStyle(Style style);
}

sealed class ReadStyleResult {
  const ReadStyleResult();
}

class ReadStyleSuccess extends ReadStyleResult {
  final Style output;
  final List<String> warnings;
  const ReadStyleSuccess({required this.output, this.warnings = const []});
}

class ReadStyleFailure extends ReadStyleResult {
  final List<Exception> errors;
  const ReadStyleFailure({required this.errors});
}
```

### Phase 2 – `mapstyler_mapbox_adapter`

**Ziel:** Konvertierung Mapbox GL Style JSON ↔ GeoStyler.

**Aufwand:** Mittel (~2.400 Zeilen TS → geschätzt ~2.500–3.000 Zeilen Dart)

**Dependencies:** `dart:convert` (JSON), `mapstyler_style`

**Quellstruktur:**

| Datei | Zeilen | Inhalt |
|---|---|---|
| `MapboxStyleParser.ts` | 1.827 | Haupt-Parser (read + write) |
| `Expressions.ts` | 340 | Mapbox-Expressions ↔ GeoStyler-Functions |
| `MapboxStyleUtil.ts` | 235 | Farbkonvertierung, URL-Handling |

**Besonderheiten:**
- Mapbox-Layer sind flach (1 Symbolizer pro Layer), GeoStyler-Rules können mehrere haben → Merge/Split-Logik via `geostyler:ref`-Metadaten
- Mapbox-Expressions sind Array-basiert (`["get", "fieldname"]`) → Mapping auf GeoStyler-Funktionsobjekte
- Kein XML – alles JSON → `dart:convert` reicht vollständig

**Nutzen:** Sehr hoch – Mapbox GL / MapLibre ist das dominante Style-Format für Webkarten und Flutter-Maps.

### Phase 3 – `mapstyler_sld_adapter` (Mapping-Layer)

**Ziel:** Konvertierung flutter_map_sld-Typen ↔ mapstyler_style-Typen.

**Ansatz:** Kein neuer SLD-Parser – stattdessen wird der bestehende SLD-Parser aus `flutter_map_sld` weiterverwendet. Phase 3 ist nur ein **Mapping-Layer** zwischen den beiden Typsystemen:

```
SLD XML ──→ flutter_map_sld (bestehender Parser) ──→ flutter_map_sld Typen
                                                           │
                                                    mapstyler_sld_adapter
                                                      (Mapping-Layer)
                                                           │
                                                           ▼
                                                   mapstyler_style Typen
                                                           │
                                                 ┌─────────┼─────────┐
                                                 ▼         ▼         ▼
                                           Mapbox JSON  QML Adapter  flutter_map
```

**Aufwand:** Niedrig–Mittel (Typ-Mapping, kein XML-Parsing; erweitert durch Spatial Filters und Composite Expressions seit flutter_map_sld 0.5.0)

**Dependencies:** `flutter_map_sld` ≥0.5.0 (pure Dart, keine Flutter-Abhängigkeit; transitiv: `gml4dart` für Geometrie-Modell), `mapstyler_style`

> Hinweis: `flutter_map_sld` ist ein reines Dart-Package. Die Flutter-Abhängigkeit liegt nur in `flutter_map_sld_flutter_map` (dem flutter_map-Adapter). Der `mapstyler_sld_adapter` bleibt damit **pure Dart** – konform mit der Plattform-Strategie.

**Mapping-Umfang:**

| flutter_map_sld Typ | → | mapstyler_style Typ |
|---|---|---|
| PointSymbolizer (Mark/ExternalGraphic) | → | MarkSymbolizer / IconSymbolizer |
| LineSymbolizer (Stroke) | → | LineSymbolizer |
| PolygonSymbolizer (Fill + Stroke) | → | FillSymbolizer |
| TextSymbolizer (Label, Font, Halo) | → | TextSymbolizer |
| RasterSymbolizer (ColorMap) | → | RasterSymbolizer |
| Vergleichs-/Logikfilter | → | ComparisonFilter / CombinationFilter / NegationFilter |
| **Spatial Filters** (BBox, Intersects, Within, Contains, Touches, Crosses, DWithin, Beyond u.a.) | → | **SpatialFilter** (falls Option a) oder UnsupportedProperties (falls Option b) |
| ScaleDenominator | → | ScaleDenominator |
| **Composite Expressions** (Concatenate, FormatNumber) | → | FunctionExpression (strConcat, numberFormat) |
| **Composite Expressions** (Categorize, Interpolate, Recode) | → | FunctionExpression (case/step/interpolate) |

**Vorteile dieses Ansatzes:**
- Kein SLD-Parser wird doppelt geschrieben
- `flutter_map_sld` bleibt der SLD-Spezialist (5 Symbolizer, Vergleichs-/Logik-/Spatial-Filter, Composite Expressions, Scale-Regeln)
- Der Mapping-Layer ist überschaubar und gut testbar
- SLD-Verbesserungen in `flutter_map_sld` fließen automatisch in das GeoStyler-Ökosystem
- Seit 0.5.0: Spatial Filters und Composite Expressions ermöglichen deutlich reichhaltigere SLD→GeoStyler-Konvertierungen

**Bidirektional:**
- **Read:** `flutter_map_sld` parst SLD → Adapter mappt auf `mapstyler_style`-Typen
- **Write:** Adapter mappt `mapstyler_style`-Typen → `flutter_map_sld`-Typen → SLD-Export (sofern von `flutter_map_sld` unterstützt)

**Hinweis zur Geometrie-Unterstützung:** Seit flutter_map_sld 0.5.0 akzeptieren `Filter.evaluate()`, `Rule.appliesTo()` und `SldDocument.selectMatchingRules()` einen optionalen `GmlGeometry? geometry`-Parameter. Der Adapter sollte diesen durchreichen, damit Spatial Filters bei der Regelauswertung funktionieren. Das Geometrie-Modell stammt aus `gml4dart` (transitive Dependency).

**Nutzen:** Hoch – SLD-Unterstützung mit moderatem Aufwand, da der Parser bereits existiert und seit 0.5.0 deutlich umfangreicher ist.

### Phase 4 – `qml4dart` (optional, eigenständiges Package)

**Ziel:** Lesen, Modellieren und Schreiben von QGIS QML als eigenständiges Dart-Package.

**Aufwand:** Mittel (Neuimplementierung auf Basis öffentlicher QML-Struktur und realer Fixtures)

**Dependencies:** `xml`-Package

**Besonderheiten:**
- QGIS-spezifische Konzepte: Symbol-Layer, Einheitenumrechnung (mm/inch/pt → px)
- natives QML-Objektmodell statt direkter Abbildung auf `mapstyler_style`
- Lesen aus String/Datei und Schreiben in String/Datei
- kompatibilitätsgetriebene Implementierung statt direkter GeoStyler-Port

**Nutzen:** Moderat – schafft die Grundlage für QGIS-QML-Support in pure Dart, unabhängig von mapstyler.

### Phase 5 – `mapstyler_qml_adapter` (optional)

**Ziel:** Konvertierung `qml4dart` ↔ `mapstyler_style`.

**Aufwand:** Mittel (abhängig vom finalen `qml4dart`-Objektmodell und gewünschter Abdeckung)

**Dependencies:** `qml4dart`, `mapstyler_style`

**Besonderheiten:**
- saubere Trennung zwischen QML-Domäne und mapstyler-Domäne
- nicht jede QML-Struktur wird verlustfrei in `mapstyler_style` passen
- Adapter kann schrittweise entlang der tatsächlich benötigten Renderer wachsen

### Phase 6 – `mapstyler_lyrx_parser` (optional)

**Ziel:** ArcGIS LYRX → GeoStyler (nur Lesen).

**Aufwand:** Mittel (~4.470 Zeilen TS → geschätzt ~4.000–4.500 Zeilen Dart)

**Dependencies:** `dart:convert`, `image`-Package (Dart), `mapstyler_style`

**Besonderheiten:**
- Read-only (kein Write)
- LYRX ist JSON-basiert (CIM-Format) → `dart:convert` reicht
- `jimp` (JS-Bildverarbeitung) → Darts `image`-Package als Ersatz
- ~1.800 Zeilen ESRI CIM-Typdefinitionen

## Aufwands-Übersicht

| Phase | Package | TS-Zeilen | Geschätzt Dart | Aufwand | Wert |
|---|---|---|---|---|---|
| 1 | `mapstyler_style` | 2.200 | 2.500–3.500 | Mittel | Kritisch |
| 2 | `mapstyler_mapbox_adapter` | 2.400 | 2.500–3.000 | Mittel | Sehr hoch |
| 3 | `mapstyler_sld_adapter` | – | 800–1.200 | Niedrig–Mittel | Hoch |
| 4 | `qml4dart` | – | 1.500–2.500 | Mittel | Moderat |
| 5 | `mapstyler_qml_adapter` | – | 600–1.200 | Niedrig–Mittel | Moderat |
| 6 | `mapstyler_lyrx_parser` | 4.470 | 4.000–4.500 | Mittel | Niedrig |
| | **Gesamt** | **~9.100** | **~11.900–15.900** | | |

Phase 3 wird durch den Mapping-Ansatz drastisch reduziert: statt ~3.500–4.000 Zeilen SLD-Parser nur ~800–1.200 Zeilen Typ-Mapping. Seit flutter_map_sld 0.5.0 ist der Mapping-Umfang gewachsen (Spatial Filters, Composite Expressions), bleibt aber überschaubar. Für QML trennt die neue Struktur bewusst Codec und Adapter: erst `qml4dart`, dann bei Bedarf `mapstyler_qml_adapter`. Phase 1 + 2 allein (~4.600 Zeilen TS → ~5.000–6.500 Zeilen Dart) liefern bereits den größten Nutzen: ein vollständiges Dart-Typsystem für kartographische Stile plus den wichtigsten Parser (Mapbox GL).

## Detailliertes Typ-Mapping: flutter_map_sld ↔ mapstyler_style

Dieses Kapitel definiert das Feld-für-Feld-Mapping zwischen den Typsystemen von `flutter_map_sld` (≥0.5.0) und `mapstyler_style` (portiert aus geostyler-style TS v11). Es dient als Spezifikation für Phase 3 (mapstyler_sld_adapter).

**Legende:** ✅ = 1:1-Mapping, 🔄 = Transformation nötig, ⚠️ = Lücke (nur eine Seite), ❌ = nicht mappbar

### Struktur-Mapping

SLD hat eine tiefere Verschachtelung als GeoStyler. Der Adapter muss diese Ebenen flachklopfen:

```
flutter_map_sld                          mapstyler_style
─────────────                            ───────────────
SldDocument                              Style
 └─ SldLayer[]                            ├─ name (← Layer/Style-Name)
     └─ UserStyle[]                       └─ rules: Rule[]
         └─ FeatureTypeStyle[]
             └─ Rule[]
```

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `SldDocument` | → | `Style` | 🔄 | Verschachtelung Layer→UserStyle→FeatureTypeStyle→Rules wird flachgemacht. Bei mehreren Layers/Styles: alle Rules sammeln, Name aus erstem Layer/Style |
| `SldDocument.version` | → | – | ⚠️ | GeoStyler hat kein Versions-Feld; ggf. als Metadaten weitergeben |
| `Rule.name` | → | `Rule.name` | ✅ | |
| `Rule.minScaleDenominator` | → | `ScaleDenominator.min` | ✅ | |
| `Rule.maxScaleDenominator` | → | `ScaleDenominator.max` | ✅ | |
| `Rule.filter` | → | `Rule.filter` | 🔄 | Siehe Filter-Mapping unten |
| `Rule` mit mehreren Symbolizern | → | `Rule.symbolizers[]` | 🔄 | SLD: max. 1 pro Typ (point/line/polygon/text/raster); GeoStyler: Liste beliebiger Symbolizer. Nicht-null Symbolizer werden gesammelt |
| `SldParseResult.issues` | → | `ReadStyleResult.warnings` | 🔄 | Issues mit severity `warning`/`info` → warnings; `error` → ReadStyleFailure |

### Symbolizer-Mapping

#### PointSymbolizer (Mark) → MarkSymbolizer

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `Graphic.mark.wellKnownName` | → | `wellKnownName` | ✅ | Werte identisch: `square`, `circle`, `triangle`, `star`, `cross`, `x` |
| `Graphic.size` | → | `radius` | 🔄 | SLD `size` = Durchmesser, GeoStyler `radius` = Halbmesser → `size / 2` |
| `Graphic.rotation` | → | `rotate` | ✅ | Beide in Grad, im Uhrzeigersinn |
| `Graphic.opacity` | → | `opacity` | ✅ | Beide 0.0–1.0 |
| `Mark.fill.colorArgb` | → | `color` | 🔄 | ARGB int → Hex-String (`#rrggbb`) |
| `Mark.fill.opacity` | → | `fillOpacity` | ✅ | |
| `Mark.stroke.colorArgb` | → | `strokeColor` | 🔄 | ARGB int → Hex-String |
| `Mark.stroke.width` | → | `strokeWidth` | ✅ | |
| `Mark.stroke.opacity` | → | `strokeOpacity` | ✅ | |

#### PointSymbolizer (ExternalGraphic) → IconSymbolizer

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `ExternalGraphic.onlineResource` | → | `image` | ✅ | URL oder Pfad |
| `ExternalGraphic.format` | → | `format` | ✅ | MIME-Type (z.B. `image/png`) |
| `Graphic.size` | → | `size` | ✅ | Hier kein Durchmesser/Radius-Problem |
| `Graphic.rotation` | → | `rotate` | ✅ | |
| `Graphic.opacity` | → | `opacity` | ✅ | |

#### LineSymbolizer → LineSymbolizer

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `Stroke.colorArgb` | → | `color` | 🔄 | ARGB int → Hex-String |
| `Stroke.width` | → | `width` | ✅ | |
| `Stroke.opacity` | → | `opacity` | ✅ | |
| `Stroke.dashArray` | → | `dasharray` | ✅ | `List<double>` → `List<double>` |
| `Stroke.lineCap` | → | `cap` | 🔄 | SLD-Strings (`butt`/`round`/`square`) → GeoStyler-Enum |
| `Stroke.lineJoin` | → | `join` | 🔄 | SLD-Strings (`mitre`/`round`/`bevel`) → GeoStyler-Enum; `mitre` → `miter` |
| – | → | `perpendicularOffset` | ⚠️ | GeoStyler unterstützt es, flutter_map_sld nicht |
| – | → | `gap` / `dashOffset` | ⚠️ | Nur in GeoStyler |

#### PolygonSymbolizer → FillSymbolizer

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `Fill.colorArgb` | → | `color` | 🔄 | ARGB int → Hex-String |
| `Fill.opacity` | → | `fillOpacity` | ✅ | |
| `Stroke.colorArgb` | → | `outlineColor` | 🔄 | ARGB int → Hex-String |
| `Stroke.width` | → | `outlineWidth` | ✅ | |
| `Stroke.dashArray` | → | `outlineDasharray` | ✅ | |
| `Stroke.opacity` | → | `outlineOpacity` | ✅ | |
| `Stroke.lineCap` | → | `outlineCap` | 🔄 | Wie bei Line |
| `Stroke.lineJoin` | → | `outlineJoin` | 🔄 | Wie bei Line |
| – | → | `graphicFill` | ⚠️ | GeoStyler kann Muster-Fills; flutter_map_sld nicht |

#### TextSymbolizer → TextSymbolizer

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `label` (Expression) | → | `label` | 🔄 | `PropertyName("name")` → `FunctionExpression(property, ["name"])`; `Concatenate` → Template oder strConcat |
| `Font.family` | → | `font` | ✅ | |
| `Font.size` | → | `size` | ✅ | |
| `Font.style` | → | `fontStyle` | ✅ | `normal`/`italic`/`oblique` |
| `Font.weight` | → | `fontWeight` | ✅ | `normal`/`bold` |
| `Fill.colorArgb` | → | `color` | 🔄 | ARGB int → Hex-String |
| `Halo.fill.colorArgb` | → | `haloColor` | 🔄 | ARGB int → Hex-String |
| `Halo.radius` | → | `haloWidth` | ✅ | |
| `PointPlacement.anchorPointX/Y` | → | `anchor` | 🔄 | Zwei Doubles → GeoStyler-Anchor-String (`center`, `top`, etc.) oder Tuple |
| `PointPlacement.displacementX/Y` | → | `offset` | 🔄 | Zwei Doubles → `[x, y]` |
| `PointPlacement.rotation` | → | `rotate` | ✅ | |
| `LinePlacement.perpendicularOffset` | → | `perpendicularOffset` | ✅ | |
| `LabelPlacement` (point vs. line) | → | `placement` | 🔄 | PointPlacement → `'point'`, LinePlacement → `'line'` |

#### RasterSymbolizer → RasterSymbolizer

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `opacity` | → | `opacity` | ✅ | |
| `ColorMap` | → | `colorMap` | 🔄 | `ColorMapType` + `ColorMapEntry[]` → GeoStyler ColorMap. `ramp`→`ramp`, `intervals`→`intervals`, `exactValues`→`values` |
| `ChannelSelection` | → | `channelSelection` | 🔄 | Strukturell ähnlich, GeoStyler hat `redChannel`/`greenChannel`/`blueChannel`/`grayChannel` |
| `ContrastEnhancement` | → | `contrastEnhancement` | ✅ | `normalize`/`histogram`/`none` + gammaValue |
| `ShadedRelief` | → | – | ⚠️ | Nicht in GeoStyler |
| `VendorOption[]` | → | – | ⚠️ | GeoServer-spezifisch, kein GeoStyler-Äquivalent |
| – | → | `hueRotate`, `brightnessMin/Max`, `saturation`, `contrast` | ⚠️ | Nur in GeoStyler (CSS-Filter-inspiriert) |

### Filter-Mapping

#### Vergleichs-Filter ✅

| flutter_map_sld | → | mapstyler_style | Status |
|---|---|---|---|
| `PropertyIsEqualTo(e1, e2)` | → | `ComparisonFilter('==', e1, e2)` | ✅ |
| `PropertyIsNotEqualTo(e1, e2)` | → | `ComparisonFilter('!=', e1, e2)` | ✅ |
| `PropertyIsLessThan(e1, e2)` | → | `ComparisonFilter('<', e1, e2)` | ✅ |
| `PropertyIsGreaterThan(e1, e2)` | → | `ComparisonFilter('>', e1, e2)` | ✅ |
| `PropertyIsLessThanOrEqualTo(e1, e2)` | → | `ComparisonFilter('<=', e1, e2)` | ✅ |
| `PropertyIsGreaterThanOrEqualTo(e1, e2)` | → | `ComparisonFilter('>=', e1, e2)` | ✅ |
| `PropertyIsBetween(e, lower, upper)` | → | `ComparisonFilter('<=x<=', e, lower, upper)` | ✅ |
| `PropertyIsLike(e, pattern, wildCard, singleChar, escapeChar)` | → | `ComparisonFilter('*=', e, pattern)` | 🔄 | GeoStyler `*=` hat keine wildCard/singleChar/escapeChar-Konfiguration; Wildcard-Zeichen müssen in den Pattern konvertiert werden |
| `PropertyIsNull(e)` | → | – | ⚠️ | GeoStyler hat keinen expliziten IsNull-Operator. Workaround: `ComparisonFilter('==', e, null)` |

#### Logik-Filter ✅

| flutter_map_sld | → | mapstyler_style | Status |
|---|---|---|---|
| `And(filters)` | → | `CombinationFilter('&&', filters)` | ✅ |
| `Or(filters)` | → | `CombinationFilter('\|\|', filters)` | ✅ |
| `Not(filter)` | → | `NegationFilter('!', filter)` | ✅ |

#### Spatial Filter ✅ (Dart-Erweiterung)

GeoStyler-style (TS v11) hat keine Spatial-Filter-Typen. Im Dart-Port werden sie als OGC-konforme Erweiterung hinzugefügt (Option a). Alle flutter_map_sld Spatial Filter haben damit ein direktes Äquivalent:

| flutter_map_sld | → | mapstyler_style (Dart) | Status |
|---|---|---|---|
| `BBox(envelope)` | → | `SpatialFilter.bbox(envelope)` | ✅ |
| `Intersects(geom)` | → | `SpatialFilter.intersects(geom)` | ✅ |
| `Within(geom)` | → | `SpatialFilter.within(geom)` | ✅ |
| `Contains(geom)` | → | `SpatialFilter.contains(geom)` | ✅ |
| `Touches(geom)` | → | `SpatialFilter.touches(geom)` | ✅ |
| `Crosses(geom)` | → | `SpatialFilter.crosses(geom)` | ✅ |
| `SpatialOverlaps(geom)` | → | `SpatialFilter.overlaps(geom)` | ✅ |
| `Disjoint(geom)` | → | `SpatialFilter.disjoint(geom)` | ✅ |
| `DWithin(geom, distance, units)` | → | `DistanceFilter.dWithin(geom, distance, units)` | ✅ |
| `Beyond(geom, distance, units)` | → | `DistanceFilter.beyond(geom, distance, units)` | ✅ |

**Geometrie-Modell:** Die Dart-Erweiterung benötigt ein Geometrie-Modell für Spatial Filters. Optionen:
- `gml4dart`-Typen (`GmlGeometry`) direkt verwenden — einfach, aber koppelt `mapstyler_style` an GML
- Eigenes minimales Geometrie-Interface — entkoppelt, aber Mapping-Overhead im Adapter
- GeoJSON-basiert (`Map<String, dynamic>`) — universell, aber untypisiert

Empfehlung: Eigenes minimales `sealed class Geometry` in `mapstyler_style` (Point, LineString, Polygon, Envelope), das im Adapter auf `GmlGeometry` gemappt wird. Das hält die Kern-Library unabhängig.

**Hinweis:** Spatial Filters sind eine Dart-Erweiterung, die über das TypeScript-Original hinausgeht. Dies wird in der Dokumentation und den API-Docs explizit gekennzeichnet. Parser, die keine Spatial Filters unterstützen (Mapbox, QGIS, LYRX), melden sie als `UnsupportedProperties`.

### Expression-Mapping

#### Basis-Expressions

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `Literal(value)` | → | `LiteralExpression(value)` | ✅ | `dynamic` → typisiert (`T`) |
| `PropertyName(name)` | → | `FunctionExpression(property, [name])` | 🔄 | SLD PropertyName ist ein eigener Typ; in GeoStyler ist `property` eine Funktion |

#### Composite Expressions

| flutter_map_sld | → | mapstyler_style | Status | Anmerkung |
|---|---|---|---|---|
| `Concatenate(exprs)` | → | `FunctionExpression(strConcat, exprs)` | 🔄 | SLD-Concatenate ist n-ary, GeoStyler strConcat ebenfalls |
| `FormatNumber(numExpr, pattern)` | → | `FunctionExpression(numberFormat, [numExpr, pattern])` | 🔄 | GeoStyler hat `numberFormat` mit `pattern`/`negativePattern`/`decimalSeparator`/`groupingSeparator`; SLD nur `pattern` |
| `Categorize(lookup, thresholds, values, fallback)` | → | `FunctionExpression(step, [lookup, defaultValue, ...boundaries])` | 🔄 | **Komplexestes Mapping.** OGC Categorize: N Thresholds, N+1 Values. GeoStyler `step`: äquivalente Semantik — `step(input, defaultValue, boundary₁, value₁, boundary₂, value₂, ...)`. `values[0]` = defaultValue, dann Paare (threshold[i], values[i+1]) |
| `Interpolate(lookup, dataPoints, mode, fallback)` | → | `FunctionExpression(interpolate, [mode, lookup, ...stops])` | 🔄 | `InterpolationPoint(data, value)` → `FInterpolateParameter(stop, value)`. `InterpolateMode.linear` → `['linear']`, `.cubic` → `['cubic']` |
| `Recode(lookup, mappings, fallback)` | → | `FunctionExpression(case, [fallback, ...cases])` | 🔄 | Jedes `RecodeMapping(input, output)` → `FCaseParameter(case: equalTo(lookup, input), value: output)`. Recode ist ein Exact-Match-Lookup → in GeoStyler als `case` mit Gleichheits-Bedingungen |

#### Farbwert-Konvertierung

Alle Farbwerte in flutter_map_sld sind ARGB-Integers (`int`). GeoStyler verwendet Hex-Strings (`#rrggbb`). Die Konvertierung ist eine zentrale Utility-Funktion des Adapters:

```dart
/// ARGB int → '#rrggbb' (Alpha wird nur bei != 0xFF berücksichtigt)
String argbToHex(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  if (a == 0xFF) return '#${r.hex}${g.hex}${b.hex}';
  return '#${r.hex}${g.hex}${b.hex}'; // opacity separat
}
```

Alpha-Kanal wird als separater `opacity`-Wert gemappt, da GeoStyler Farbe und Transparenz trennt.

### Zusammenfassung: Lücken und offene Punkte

#### flutter_map_sld → mapstyler_style (Read-Richtung)

| Lücke | Schwere | Workaround |
|---|---|---|
| ~~Spatial Filters (10 Typen)~~ | ~~Hoch~~ | ✅ Gelöst durch Dart-Erweiterung (Option a) |
| PropertyIsNull | Niedrig | `== null`-Vergleich |
| PropertyIsLike-Konfiguration (wildCard, singleChar, escapeChar) | Niedrig | Pattern vor dem Mapping in Standard-Wildcards (`*`/`?`) konvertieren |
| ShadedRelief | Niedrig | UnsupportedProperties |
| VendorOptions | Niedrig | Ignorieren oder als Metadaten durchreichen |
| SLD-Version | Info | Ggf. als Custom-Property |

#### mapstyler_style → flutter_map_sld (Write-Richtung)

| Lücke | Schwere | Workaround |
|---|---|---|
| `perpendicularOffset` (Line) | Niedrig | Nicht in flutter_map_sld verfügbar |
| `gap` / `dashOffset` (Line) | Niedrig | Nicht in flutter_map_sld verfügbar |
| `graphicFill` (Fill) | Mittel | Nicht in flutter_map_sld verfügbar |
| `hueRotate`, `brightnessMin/Max`, `saturation`, `contrast` (Raster) | Mittel | CSS-Filter-Properties, nicht in SLD definiert |
| `blur` (Mark) | Niedrig | Nicht in SLD |
| Expression<boolean> als Filter | Niedrig | GeoStyler erlaubt boolesche Expressions als Filter; flutter_map_sld erwartet explizite Filter-Klassen |

## Test-Strategie

### Fixtures übernehmen

Die TS-Projekte enthalten umfangreiche Test-Fixtures:
- `geostyler-mapbox-parser`: 87 Mapbox-Style-Fixtures → 1:1 übernehmen (`test/fixtures/`)
- `flutter_map_sld`: bestehende Tests als Basis für den Mapping-Layer
- `geostyler-sld-parser`: 121 SLD-Testdateien → als Referenz für Round-Trip-Tests (SLD → flutter_map_sld → mapstyler_style → Mapbox JSON)

### Test-Kategorien

| Kategorie | Beschreibung |
|---|---|
| **Unit-Tests** | Einzelne Typen: Konstruktion, Equality, Serialisierung (`fromJson`/`toJson`) |
| **Parser-Tests** | Jede Fixture einlesen und gegen erwartetes GeoStyler-Objekt prüfen |
| **Round-Trip-Tests** | Read → Write → Read und prüfen, ob das Ergebnis identisch ist |
| **Kompatibilitäts-Tests** | Dart-Output gegen TS-Output vergleichen (einmalig generierte Referenz-JSONs) |

### Vorgehen

1. Vor Beginn jeder Phase: TS-Tests ausführen und erwartete Ergebnisse als JSON-Referenzdateien exportieren
2. Dart-Tests prüfen gegen diese Referenzdateien
3. Round-Trip-Tests sichern bidirektionale Korrektheit

## Dart-Package-Struktur

Monorepo mit `dart pub workspace` (nativ seit Dart 3.5, keine zusätzliche Abhängigkeit):

```
mapstyler/
├── pubspec.yaml                    # Workspace-Root
├── LICENSE                         # BSD-2-Clause (GeoStyler Attribution)
├── mapstyler_style/                # Phase 1 – Kern-Typen
│   ├── lib/
│   │   ├── mapstyler_style.dart
│   │   └── src/
│   │       ├── style.dart              # Style, Rule, ScaleDenominator
│   │       ├── symbolizer.dart         # sealed class Symbolizer + Subklassen
│   │       ├── filter.dart             # sealed class Filter + Subklassen
│   │       ├── expression.dart         # sealed class Expression<T>
│   │       ├── functions/              # GeoStyler-Funktionen nach Kategorie
│   │       │   ├── numeric.dart
│   │       │   ├── string.dart
│   │       │   ├── boolean.dart
│   │       │   └── control_flow.dart
│   │       └── parser.dart             # StyleParser<T>, ReadStyleResult, WriteStyleResult
│   ├── test/
│   └── pubspec.yaml
├── mapstyler_mapbox_adapter/        # Phase 2
│   ├── lib/
│   │   └── src/
│   │       ├── mapbox_style_parser.dart
│   │       ├── expressions.dart
│   │       └── util.dart
│   ├── test/
│   │   └── fixtures/                   # 87 Mapbox-Style-Fixtures aus TS
│   └── pubspec.yaml                    # depends on mapstyler_style
├── mapstyler_sld_adapter/          # Phase 3 – Mapping-Layer
│   ├── lib/
│   │   └── src/
│   │       ├── sld_to_geostyler.dart   # flutter_map_sld → mapstyler_style
│   │       └── mapstyler_to_sld.dart    # mapstyler_style → flutter_map_sld
│   ├── test/
│   └── pubspec.yaml                    # depends on mapstyler_style, flutter_map_sld
├── qml4dart/                       # Phase 4 – eigenständiges QML-Package
│   └── ...                             # depends on xml
├── mapstyler_qml_adapter/         # Phase 5 – Mapping-Layer
│   └── ...                             # depends on qml4dart, mapstyler_style
├── mapstyler_lyrx_parser/         # Phase 6
│   └── ...                             # depends on mapstyler_style, image
└── flutter_mapstyler/              # Flutter-Rendering
    ├── lib/
    │   └── src/
    │       ├── style_renderer.dart
    │       ├── expression_evaluator.dart
    │       ├── filter_evaluator.dart
    │       └── painters/               # CustomPaint für WellKnownNames
    ├── test/
    └── pubspec.yaml                    # depends on mapstyler_style, flutter_map, flutter
```

## Nächste Schritte

1. **GeoStyler-Community informieren** – mapstyler als eigenständiges Dart-Projekt vorstellen (z.B. als GitHub Discussion im geostyler/geostyler Repo). Kompatibilität mit GeoStyler-JSON kommunizieren, Abgrenzung als eigenständiges Ökosystem mit Erweiterungen klären.
2. ~~**Spatial-Filter-Entscheidung treffen**~~ ✅ – **Option (a) gewählt:** Spatial Filters in `mapstyler_style` aufnehmen. Option (c) technisch unmöglich (sealed class). Option (b) verwirft Information. Eigenes minimales Geometrie-Modell in mapstyler_style, Mapping auf GmlGeometry im Adapter
3. **Quell-Versionen pinnen** – Für jedes TS-Package den Commit/Tag festlegen; für flutter_map_sld ≥0.5.0 als Mindestversion
4. ~~**Serialisierungs-Ansatz wählen**~~ ✅ – **Manuell** gewählt. Prototyp-Vergleich in `prototypes/` bestätigt: dart_mappable kann GeoStyler-JSON-Formate nicht abdecken (siehe [Serialisierung](#serialisierung))
5. ~~**Typ-Mapping flutter_map_sld ↔ mapstyler_style definieren**~~ ✅ – Siehe [Detailliertes Typ-Mapping](#detailliertes-typ-mapping-flutter_map_sld--mapstyler_style). Offene Punkte: Spatial-Filter-Entscheidung (Schritt 2), Farbkonvertierungs-Utility implementieren
6. **Repository anlegen** – Workspace-Struktur mit `dart pub workspace`
7. **Phase 1 starten** – `mapstyler_style`: Kern-Typen, Expressions, Parser-Interface
8. **Referenz-JSONs generieren** – TS-Tests ausführen, erwartete Outputs exportieren
9. **Phase 2 starten** – Mapbox-Parser portieren und gegen Fixtures testen
10. **QML separat aufsetzen** – `qml4dart` als eigenständiges Package mit QML-Objektmodell und XML-Codec
11. **Adapter nur bei Bedarf bauen** – `mapstyler_qml_adapter` erst nach stabilem `qml4dart`
