# mapstyler Kernmodell

Diese Datei beschreibt das gemeinsame Style-Modell des `mapstyler`-
Ökosystems. Sie ist bewusst auf den Kern fokussiert:

- das `mapstyler_style`-Package
- das GeoStyler-kompatible JSON-Zwischenformat
- die zentralen Typen `Style`, `Rule`, `Symbolizer`, `Filter`,
  `Expression`, `Geometry`, `StyledFeature`,
  `StyledFeatureCollection`
- geplante Geometrie-Operationen (`simplifyLine`, `simplifyRing`)

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
- die Heimat des gemeinsamen Flutter-freien Feature-Modells

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

### Geometrie-Vereinfachung

`mapstyler_style` stellt Funktionen zur Koordinatenreduktion
bereit, die auf dem Tupel-Format `List<(double, double)>`
von `LineStringGeometry` und `PolygonGeometry` arbeiten. Die
Algorithmen sind pure Dart ohne externe Abhaengigkeiten.

**Fuer offene Linien:**

```dart
/// Zweistufige Vereinfachung: radiale Vorfilterung + Douglas-Peucker.
/// Start- und Endpunkt bleiben erhalten.
List<(double, double)> simplifyLine(
  List<(double, double)> coords,
  double tolerance,
);
```

**Fuer geschlossene Polygon-Ringe:**

```dart
/// Ringspezifische Vereinfachung: Ringschluss wird gesichert,
/// Mindestpunktzahl ist 4 (3 eindeutige + Schluss).
List<(double, double)> simplifyRing(
  List<(double, double)> coords,
  double tolerance,
);
```

**Pseudocode der Algorithmen:**

```dart
/// Radiale Vorfilterung — entfernt Punkte, die naeher als
/// [tolerance] am vorherigen behaltenen Punkt liegen.
/// O(n), ein Durchgang.
List<(double, double)> _radialFilter(
  List<(double, double)> coords,
  double tolerance,
) {
  if (coords.length <= 2) return coords;
  final tolSq = tolerance * tolerance;
  final result = [coords.first];

  for (var i = 1; i < coords.length - 1; i++) {
    final (px, py) = result.last;
    final (cx, cy) = coords[i];
    final dx = cx - px;
    final dy = cy - py;
    if (dx * dx + dy * dy >= tolSq) {
      result.add(coords[i]);
    }
  }

  result.add(coords.last); // Endpunkt immer erhalten
  return result;
}

/// Douglas-Peucker — rekursive formerhaltende Vereinfachung.
/// O(n log n) durchschnittlich.
List<(double, double)> _douglasPeucker(
  List<(double, double)> coords,
  double tolerance,
) {
  if (coords.length <= 2) return coords;

  // Punkt mit groesstem Abstand zur Linie start→end finden.
  final (sx, sy) = coords.first;
  final (ex, ey) = coords.last;
  final dx = ex - sx;
  final dy = ey - sy;
  final lenSq = dx * dx + dy * dy;

  var maxDist = 0.0;
  var maxIdx = 0;

  for (var i = 1; i < coords.length - 1; i++) {
    final (px, py) = coords[i];
    double dist;
    if (lenSq == 0) {
      // Start == End → Abstand zum Punkt
      final dpx = px - sx;
      final dpy = py - sy;
      dist = dpx * dpx + dpy * dpy;
    } else {
      // Lotfusspunkt auf die Linie
      final t = ((px - sx) * dx + (py - sy) * dy) / lenSq;
      final tc = t.clamp(0.0, 1.0);
      final projX = sx + tc * dx;
      final projY = sy + tc * dy;
      final dpx = px - projX;
      final dpy = py - projY;
      dist = dpx * dpx + dpy * dpy;
    }
    if (dist > maxDist) {
      maxDist = dist;
      maxIdx = i;
    }
  }

  if (maxDist < tolerance * tolerance) {
    // Alle Zwischenpunkte liegen innerhalb der Toleranz.
    return [coords.first, coords.last];
  }

  // Rekursiv beide Haelften vereinfachen.
  final left = _douglasPeucker(coords.sublist(0, maxIdx + 1), tolerance);
  final right = _douglasPeucker(coords.sublist(maxIdx), tolerance);
  return [...left, ...right.skip(1)];
}

/// Zweistufige Linienvereinfachung.
List<(double, double)> simplifyLine(
  List<(double, double)> coords,
  double tolerance,
) {
  if (tolerance <= 0 || coords.length <= 2) return coords;
  return _douglasPeucker(_radialFilter(coords, tolerance), tolerance);
}

/// Ringspezifische Vereinfachung: loest den Ringschluss temporaer,
/// vereinfacht, stellt ihn wieder her. Mindestpunktzahl: 4.
List<(double, double)> simplifyRing(
  List<(double, double)> coords,
  double tolerance,
) {
  if (tolerance <= 0 || coords.length <= 4) return coords;

  final closed = coords.first == coords.last;
  var open = closed ? coords.sublist(0, coords.length - 1) : coords;

  open = _radialFilter(open, tolerance);
  open = _douglasPeucker(open, tolerance);

  if (open.length < 3) return coords; // zu wenige Punkte → Original
  if (closed) open.add(open.first);
  return open;
}
```

Die Toleranz ist in derselben Einheit wie die Koordinaten (Grad
bei EPSG:4326, Meter bei projizierten CRS). Die Berechnung einer
sinnvollen Toleranz aus Kartenaufloesung oder Zoomstufe ist Sache
des Aufrufers, nicht des Kernmodells.

Consumer:
- `mapstyler_gdal_adapter` — vereinfacht waehrend der
  Feature-Iteration
- `flutter_mapstyler` — kann bei Bedarf zur Renderzeit
  vereinfachen
- Demo-App-Loader — koennen beim Import vereinfachen

### StyledFeature und StyledFeatureCollection

Neben Style-Typen enthält `mapstyler_style` auch das gemeinsame
Feature-Modell für Renderer und Daten-Adapter:

```dart
class StyledFeature {
  final String? id;
  final Map<String, dynamic> properties;
  final Geometry geometry;
}

class StyledFeatureCollection {
  final List<StyledFeature> features;
}
```

Diese Typen liegen bewusst im Kernmodell statt in `flutter_mapstyler`:

- Daten-Adapter wie `mapstyler_gdal_adapter` können Features ohne
  Flutter-Abhängigkeit erzeugen
- `flutter_mapstyler` kann dieselben Typen direkt rendern
- CLI- und Server-Anwendungen können Features ebenfalls ohne Flutter
  verarbeiten

`flutter_mapstyler` ergänzt die Collection nur noch um renderernahe
Hilfen wie den räumlichen Index per Extension.

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
