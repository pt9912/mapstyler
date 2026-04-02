# mapstyler Kernmodell

Diese Datei beschreibt das gemeinsame Style-Modell des `mapstyler`-
Ökosystems. Sie ist bewusst auf den Kern fokussiert:

- das `mapstyler_style`-Package
- das GeoStyler-kompatible JSON-Zwischenformat
- die zentralen Typen `Style`, `Rule`, `Symbolizer`, `Filter`,
  `Expression`, `Geometry`

Architektur, format-spezifische Details und Rendering werden in
separaten Dokumenten beschrieben.

## Ziel

`mapstyler` trennt zwischen:

- formatspezifischen Eingabeformaten wie Mapbox, SLD oder QML
- einem gemeinsamen, formatunabhängigen Kernmodell
- optionalem Rendering in Flutter

Das Kernmodell lebt in `mapstyler_style`. Es ist der gemeinsame Nenner,
in den Adapter ihre Eingabeformate übersetzen und aus dem sie wieder in
Zielformate schreiben.

## Rolle von `mapstyler_style`

`mapstyler_style` ist:

- das zentrale Typsystem des Workspaces
- die Implementierung des GeoStyler-kompatiblen JSON-Formats
- die Heimat des gemeinsamen `StyleParser<T>`-Interfaces

Das Package ist pure Dart und hängt nicht von Flutter ab.

## Grundstruktur

Das Modell ist bewusst klein und stabil aufgebaut:

```text
Style
  -> Rule[]
     -> Filter?
     -> ScaleDenominator?
     -> Symbolizer[]
```

Ein `Style` enthält geordnete Regeln. Jede `Rule` kann:

- über einen `Filter` Features auswählen
- über `ScaleDenominator` auf Maßstäbe beschränkt sein
- ein oder mehrere `Symbolizer` tragen

## Die wichtigsten Typen

### Style

`Style` ist der Top-Level-Typ:

```dart
class Style {
  final String? name;
  final List<Rule> rules;
}
```

Ein Style ist nichts anderes als ein optional benanntes Regelset.

### Rule

`Rule` bündelt Auswahl und Darstellung:

```dart
class Rule {
  final String? name;
  final Filter? filter;
  final List<Symbolizer> symbolizers;
  final ScaleDenominator? scaleDenominator;
}
```

Damit ist eine Regel sowohl für Konvertierung als auch Rendering
brauchbar:

- fachliche Auswahl über `filter`
- visuelle Ausgabe über `symbolizers`
- zoom- oder maßstabsabhängige Aktivierung über `scaleDenominator`

### Symbolizer

`Symbolizer` beschreibt die Darstellung eines Features. Aktuell gibt es:

- `FillSymbolizer`
- `LineSymbolizer`
- `MarkSymbolizer`
- `IconSymbolizer`
- `TextSymbolizer`
- `RasterSymbolizer`

JSON-seitig werden Symbolizer über das Feld `kind` unterschieden:

```json
{
  "kind": "Fill",
  "color": "#ffcc00",
  "opacity": 0.5
}
```

### Filter

`Filter` beschreibt, auf welche Features eine Regel angewendet wird.

Aktuell gibt es:

- `ComparisonFilter`
- `CombinationFilter`
- `NegationFilter`
- `SpatialFilter`
- `DistanceFilter`

Die ersten drei sind GeoStyler-kompatibel. `SpatialFilter` und
`DistanceFilter` sind bewusste `mapstyler`-Erweiterungen.

Die JSON-Repräsentation ist array-basiert:

```json
["==", "landuse", "residential"]
["&&", ["==", "type", "road"], [">", "width", 5]]
["intersects", {"type": "Point", "coordinates": [8.5, 47.3]}]
```

### Expression

Viele Symbolizer- und Filterwerte sind nicht nur Literale, sondern
Expressions:

```dart
sealed class Expression<T> {}

final class LiteralExpression<T> extends Expression<T> {}
final class FunctionExpression<T> extends Expression<T> {}
```

Damit lassen sich sowohl feste Werte als auch datengetriebene Werte
ausdrücken:

```dart
const LiteralExpression('#ff0000')
const FunctionExpression(PropertyGet('color'))
```

JSON-seitig nutzt `mapstyler_style` ein Dual-Format:

- Literale bleiben rohe JSON-Werte
- Funktionen werden als Objekte mit `name` und `args` serialisiert

Beispiel:

```json
"#ff0000"
```

```json
{
  "name": "property",
  "args": ["color"]
}
```

### GeoStylerFunction

`FunctionExpression` kapselt eine `GeoStylerFunction`. Aktuell
unterscheidet das Modell zwischen:

- `PropertyGet`
- `ArgsFunction`
- `CaseFunction`
- `StepFunction`
- `InterpolateFunction`

Damit lassen sich einfache Property-Lookups ebenso abbilden wie
kontrollflussartige Expressions.

### Geometry

Für Spatial- und Distance-Filter besitzt `mapstyler_style` ein eigenes
kleines Geometriemodell:

- `PointGeometry`
- `EnvelopeGeometry`
- `LineStringGeometry`
- `PolygonGeometry`

Das Modell ist absichtlich unabhängig von `gml4dart` oder GeoJSON-
Bibliotheken. Adapter wie `mapstyler_sld_adapter` übernehmen die
Übersetzung an ihren jeweiligen Grenzen.

## GeoStyler-JSON als Zwischenformat

Das Kernmodell ist zugleich das gemeinsame JSON-Zwischenformat des
Workspaces. Formate wie Mapbox, SLD oder QML werden nicht direkt
ineinander umgewandelt, sondern immer über dieses Modell.

```text
Mapbox / SLD / QML
  -> Adapter
  -> mapstyler_style
  -> Adapter
  -> Zielformat
```

Beispiel:

```json
{
  "name": "Flächennutzung",
  "rules": [
    {
      "name": "Wohngebiet",
      "filter": ["==", "landuse", "residential"],
      "symbolizers": [
        {
          "kind": "Fill",
          "color": "#ffcc00",
          "opacity": 0.5
        }
      ]
    }
  ]
}
```

Die wichtigsten Ein- und Ausgänge sind:

```dart
final style = Style.fromJson(jsonMap);
final style2 = Style.fromJsonString(jsonString);

final jsonMap2 = style.toJson();
final jsonString2 = style.toJsonString();
```

## Warum das Modell bewusst abstrakt bleibt

Das Kernmodell versucht nicht, jedes Eingabeformat 1:1 nachzubauen.
Stattdessen abstrahiert es auf die gemeinsamen Konzepte:

- Regeln statt formatspezifischer Layer-/Renderer-Strukturen
- Symbolizer statt formatabhängiger Render-Details
- Expressions statt formatgebundener Ausdruckssprachen
- Filter statt parser-spezifischer Bedingungstypen

Das macht das Modell:

- stabiler über mehrere Formate hinweg
- einfacher zu serialisieren
- besser für Adapter und Renderer nutzbar

Der Preis ist bewusst akzeptierter Informationsverlust an den Rändern.
Formatspezifische Details, die nicht Teil des Kernmodells sind, bleiben
in den jeweiligen Formatpaketen oder gehen beim Mapping verloren.

## Erweiterungen gegenüber GeoStyler

`mapstyler_style` ist am GeoStyler-JSON-Format orientiert, erweitert das
Modell aber an einer zentralen Stelle:

- `SpatialFilter`
- `DistanceFilter`
- ein minimales `Geometry`-Modell für diese Filter

Diese Erweiterungen sind nötig, um räumliche Filter aus SLD-ähnlichen
Quellen nicht beim Mapping zu verlieren.

## `StyleParser<T>`

Formatspezifische Konverter können das gemeinsame Interface
`StyleParser<T>` nutzen:

```dart
abstract class StyleParser<T> {
  String get title;
  Future<ReadStyleResult> readStyle(T input);
  Future<WriteStyleResult<T>> writeStyle(Style style);
}
```

Das Interface gehört absichtlich in den Kern, weil alle Adapter dieselbe
Form von Read-/Write-Verträgen verwenden sollen.

Die Result-Typen trennen harte Fehler von degradierten Erfolgen mit
Warnings:

- `ReadStyleSuccess`
- `ReadStyleFailure`
- `WriteStyleSuccess<T>`
- `WriteStyleFailure<T>`

## Was diese Datei nicht mehr abdeckt

Diese Datei ist bewusst keine:

- Architekturübersicht des gesamten Repositories
- Implementierungs-Roadmap
- formatspezifische Spezifikation für Mapbox, QML oder SLD
- Rendering-Dokumentation für Flutter

Diese Themen sind getrennt dokumentiert, damit `mapstyler.md` klein und
als Kernreferenz lesbar bleibt.

## Verwandte Dokumente

- [architecture.md](architecture.md)
- [MAPBOX.md](MAPBOX.md)
- [QML.md](QML.md)
- [flutter_mapstyler.md](flutter_mapstyler.md)
