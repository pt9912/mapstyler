# flutter_mapstyler — mapstyler-Stile auf flutter_map rendern

Flutter-Package, das `mapstyler_style`-Typen in `flutter_map`-Layer und -Styles übersetzt. Bindeglied zwischen dem plattformunabhängigen mapstyler-Ökosystem und der Flutter-Kartenvisualisierung.

## Einordnung im Ökosystem

```
SLD XML ─→ flutter_map_sld ─→ mapstyler_sld_adapter ─┐
Mapbox JSON ─→ mapstyler_mapbox_adapter ───────────────┤
                                                      ▼
                                               mapstyler_style
                                              (pure Dart Typen)
                                                      │
                                              flutter_mapstyler    ◄── dieses Package
                                              (Flutter-Rendering)
                                                      │
                                                      ▼
                                                 flutter_map
                                              (Karten-Widget)
```

Das Package liegt bewusst **nach** dem Konvertierungsschritt: Es arbeitet ausschließlich mit `mapstyler_style`-Typen. Damit ist es unabhängig vom Quellformat (SLD, Mapbox, QML, LYRX).

## Aufgabe

Konvertierung von `mapstyler_style`-Symbolizern in flutter_map-kompatible Darstellungen:

| mapstyler_style Typ | → | flutter_map Darstellung |
|---|---|---|
| `FillSymbolizer` | → | `PolygonLayer` mit `Color`, `borderColor`, `borderStrokeWidth` |
| `LineSymbolizer` | → | `PolylineLayer` mit `color`, `strokeWidth`, `isDotted`/`dashPattern` |
| `MarkSymbolizer` | → | `MarkerLayer` mit `Marker` (Widget-basiert: `Container`, `Icon`, Canvas) |
| `IconSymbolizer` | → | `MarkerLayer` mit `Marker` (Image-Widget) |
| `TextSymbolizer` | → | `MarkerLayer` mit `Marker` (Text-Widget) oder eigener Label-Layer |
| `RasterSymbolizer` | → | `TileLayer`-Konfiguration (Opacity, ColorFilter) |

## API-Entwurf

### Kern: `StyleRenderer`

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

typedef FeatureTapCallback = void Function(StyledFeature feature);
typedef FeatureLongPressCallback = void Function(StyledFeature feature);

/// Konvertiert mapstyler-Regeln in flutter_map-Layer.
class StyleRenderer {
  const StyleRenderer();

  /// Wendet einen kompletten Style auf Features an.
  /// Gibt eine geordnete Liste von flutter_map-Layern zurück.
  List<Widget> renderStyle({
    required Style style,
    required StyledFeatureCollection features,
    double? scaleDenominator,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  });

  /// Wendet eine einzelne Regel auf passende Features an.
  List<Widget> renderRule({
    required Rule rule,
    required List<StyledFeature> features,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  });

  /// Konvertiert einen einzelnen Symbolizer in einen flutter_map-Layer.
  /// Nützlich für eigene Rendering-Pipelines.
  Widget? symbolizerToLayer({
    required Symbolizer symbolizer,
    required List<StyledFeature> features,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  });
}
```

### Expression-Auswertung

`mapstyler_style` Expressions (`LiteralExpression`, `FunctionExpression`) müssen zur Render-Zeit gegen Feature-Properties evaluiert werden:

```dart
/// Wertet eine Expression gegen Feature-Properties aus.
T? evaluateExpression<T>(
  Expression<T>? expression,
  Map<String, Object?> properties,
);

// Beispiel:
final color = evaluateExpression(
  symbolizer.color, // könnte LiteralExpression('#ff0000') oder FunctionExpression(property('color')) sein
  feature.properties,
);
```

### Filter-Auswertung

Regeln mit Filtern werden nur auf passende Features angewandt:

```dart
/// Prüft ob ein Feature den Filter erfüllt.
bool evaluateFilter(
  Filter? filter,
  Map<String, Object?> properties, {
  Geometry? geometry, // für Spatial Filters
});
```

### Scale-basierte Regelauswahl

```dart
/// Wählt Regeln aus, die bei gegebenem Maßstab aktiv sind.
List<Rule> selectRulesAtScale(
  Style style,
  double scaleDenominator,
);
```

## Symbolizer-Mapping im Detail

### FillSymbolizer → PolygonLayer

```dart
PolygonLayer(
  polygons: matchingPolygons.map((feature) => Polygon(
    points: feature.coordinates,
    color: evaluateExpression(symbolizer.color, feature.properties)
        .toFlutterColor()
        .withOpacity(evaluateExpression(symbolizer.fillOpacity, feature.properties) ?? 1.0),
    borderColor: evaluateExpression(symbolizer.outlineColor, feature.properties)
        ?.toFlutterColor() ?? Colors.transparent,
    borderStrokeWidth: evaluateExpression(symbolizer.outlineWidth, feature.properties) ?? 0,
  )).toList(),
)
```

### LineSymbolizer → PolylineLayer

```dart
PolylineLayer(
  polylines: matchingLines.map((feature) => Polyline(
    points: feature.coordinates,
    color: evaluateExpression(symbolizer.color, feature.properties).toFlutterColor(),
    strokeWidth: evaluateExpression(symbolizer.width, feature.properties) ?? 1.0,
    isDotted: symbolizer.dasharray != null,
  )).toList(),
)
```

### MarkSymbolizer → MarkerLayer

```dart
MarkerLayer(
  markers: matchingPoints.map((feature) => Marker(
    point: feature.coordinate,
    width: radius * 2,
    height: radius * 2,
    child: CustomPaint(
      painter: MarkPainter(
        wellKnownName: symbolizer.wellKnownName, // circle, square, triangle, star, cross, x
        color: evaluateExpression(symbolizer.color, feature.properties).toFlutterColor(),
        strokeColor: evaluateExpression(symbolizer.strokeColor, feature.properties)?.toFlutterColor(),
        strokeWidth: evaluateExpression(symbolizer.strokeWidth, feature.properties) ?? 1.0,
      ),
    ),
  )).toList(),
)
```

## Dependencies

```yaml
dependencies:
  flutter_map: ^7.0.0       # oder aktuelle Version
  mapstyler_style: ^x.x.x   # Kern-Typen
  flutter:
    sdk: flutter
```

Keine Abhängigkeit auf `flutter_map_sld`, `mapstyler_mapbox_adapter` o.ä. — das Package arbeitet nur mit den abstrakten `mapstyler_style`-Typen.

## Abgrenzung zu flutter_map_sld_flutter_map

`flutter_map_sld` hat bereits ein Flutter-Rendering-Package (`flutter_map_sld_flutter_map`). Die Abgrenzung:

| | flutter_map_sld_flutter_map | flutter_mapstyler |
|---|---|---|
| **Input** | `flutter_map_sld`-Typen (SLD-spezifisch) | `mapstyler_style`-Typen (formatunabhängig) |
| **Quellformate** | Nur SLD | SLD, Mapbox, QML, LYRX, GeoStyler-JSON |
| **Expressions** | flutter_map_sld Expressions | mapstyler Expression<T> mit Pattern Matching |
| **Spatial Filters** | Ja (direkt) | Ja (via mapstyler_style Geometrie-Modell) |
| **Zielgruppe** | Wer nur SLD braucht | Wer mehrere Formate oder das mapstyler-Ökosystem nutzt |

Langfristig könnte `flutter_map_sld_flutter_map` auf `flutter_mapstyler` aufbauen, indem es SLD → mapstyler_style → flutter_map rendert.

## Architekturentscheidungen

### 1. Feature- und Geometriemodell

`flutter_mapstyler` nutzt im Kern **kein externes GeoJSON-Package**. Das
Package rendert gegen ein kleines, stabiles Feature-Modell und verwendet
für Geometrien das bereits vorhandene `mapstyler_style`-Modell.

Damit bleibt die API unabhängig von Parser- und Austauschformaten.
GeoJSON, SLD, Mapbox oder QML werden außerhalb des Renderers in dieses
interne Modell übersetzt.

```dart
import 'package:mapstyler_style/mapstyler_style.dart';

/// Minimales Feature-Modell für flutter_mapstyler.
final class StyledFeature {
  final Object? id;
  final Geometry geometry;
  final Map<String, Object?> properties;

  const StyledFeature({
    this.id,
    required this.geometry,
    this.properties = const {},
  });
}

/// Explizite Feature-Sammlung statt Bindung an ein GeoJSON-Package.
final class StyledFeatureCollection {
  final List<StyledFeature> features;

  const StyledFeatureCollection(this.features);
}
```

Konsequenz:

- Keine harte Abhängigkeit auf `geojson_vi`, `dart_geojson` oder ähnliche Packages
- Adapter von Fremdformaten bleiben in separaten Packages oder Hilfsmodulen
- Renderer-API bleibt langfristig stabil, auch wenn sich GeoJSON-Libraries ändern

### 2. Layer-Strategie

Die Style-Reihenfolge aus `Style.rules` und `Rule.symbolizers` ist
verbindlich. Deshalb rendert `flutter_mapstyler` **nicht global einen
Layer pro Symbolizer-Typ**.

Stattdessen:

- Rendern in Regelreihenfolge
- Intern ein Render-Batch pro `Rule + Symbolizer`
- Spätere Optimierung nur durch Zusammenfassen benachbarter, kompatibler Batches

Das ist für das MVP einfacher, korrekt bezüglich Z-Order und gut
erweiterbar.

### 3. Performance-Strategie

Performance wird zuerst über Datenfluss und Vorverarbeitung gelöst, nicht
über allgemeine Lazy-Evaluation im gesamten Renderer.

Prioritäten:

- Expressions und Filter einmal in auswertbare Strukturen überführen
- Features früh nach Geometrietyp vorfiltern
- Viewport-basiert nur sichtbare Features berücksichtigen
- Punktsymbole und Labels nicht unkontrolliert als tausende Widgets erzeugen

Clustering ist **keine Kernaufgabe des Renderers**. Wenn benötigt, sollte
es als optionale, vorgelagerte Datenstrategie oder spätere Erweiterung
kommen.

### 4. Interaktivität

Der Renderer soll optionale Feature-Interaktion unterstützen, aber
Interaktivität darf den statischen Renderpfad nicht belasten.

Vorgesehene API-Richtung:

```dart
typedef FeatureTapCallback = void Function(StyledFeature feature);
typedef FeatureLongPressCallback = void Function(StyledFeature feature);
```

Konsequenz:

- Feature-Interaktion nur aktiv, wenn Callbacks gesetzt sind
- Feature-Ids sind empfohlen, damit Selektion und Wiedererkennung stabil bleiben
- Hit-Testing wird pro Layer-Typ gezielt ergänzt, nicht als globaler Sonderfall

### 5. Caching

Caching ist sinnvoll, aber gezielt. Ein pauschales Memoizing jeder
Expression pro Feature wäre zu grob und schwer korrekt invalidierbar.

Empfohlene Cache-Ebenen:

- Kompilierte Expressions und Filter pro `Style`
- Vorausgewählte Regeln pro Scale-/Zoom-Bereich
- Aufgelöste Symbolizer-Werte pro `featureId + expression + propertySignature + scaleBucket`, wenn eine stabile `id` vorhanden ist

Wenn ein Feature keine stabile `id` hat, sind nur kurzlebige Caches innerhalb
eines einzelnen Render-Durchlaufs sinnvoll. Persistente per-Feature-Caches
sollten dann deaktiviert bleiben.

Voraussetzung für aggressiveres Caching ist ein klar definiertes
Invalidierungsmodell:

- Style geändert
- Feature-Properties geändert
- Zoom-/Scale-Bereich gewechselt
- Viewport geändert, falls viewport-basiertes Culling aktiv ist

### Empfohlene Kern-API

Mit den obigen Entscheidungen ergibt sich statt einer GeoJSON-gebundenen
API eher folgende Richtung:

```dart
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

typedef FeatureTapCallback = void Function(StyledFeature feature);
typedef FeatureLongPressCallback = void Function(StyledFeature feature);

class StyleRenderer {
  const StyleRenderer();

  List<Widget> renderStyle({
    required Style style,
    required StyledFeatureCollection features,
    double? scaleDenominator,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  });
}
```

## Umsetzungsstand

Der aktuelle Implementierungsstand deckt die Kernpunkte der Doku ab:

- `StyledFeature` und `StyledFeatureCollection` bilden das rendererinterne Datenmodell
- `StyleRenderer` rendert in Regelreihenfolge und unterstützt `renderStyle`, `renderRule` und `symbolizerToLayer`
- optionales Viewport-Culling ist über `LatLngBounds viewport` im Renderpfad verfügbar
- Expressions und Filter werden pro `Style` in wiederverwendbare Evaluator-Closures vorbereitet
- per-Feature-Expression-Ergebnisse werden persistent pro `featureId + expression + propertySignature + scaleBucket` gecacht
- Fill, Line, Mark, Icon, Text und Raster sind auf `flutter_map`-Layer abgebildet
- Feature-Tap und Long-Press sind für Marker sowie Geometrie-Layer unterstützt

Der Expression-Evaluator unterstützt aktuell neben `property`, `case`, `step`
und `interpolate` auch einen breiten Satz dokumentierter `ArgsFunction`-Namen
für numerische, String- und Bool-Operationen. Unbekannte Funktionen liefern
weiterhin `null`, damit der Renderer bei neuen oder formatspezifischen
Funktionen defensiv bleibt.

## Implementierungsreihenfolge

1. **Feature-Modell festziehen** — `StyledFeature` und `StyledFeatureCollection`
2. **Expression-Evaluator** — `evaluateExpression<T>()` für Literal + PropertyGet
3. **Filter-Evaluator** — `evaluateFilter()` für Comparison + Combination + Negation
4. **Scale-basierte Regelauswahl** — aktive Regeln für aktuellen Maßstab
5. **FillSymbolizer → PolygonLayer** — einfachster Symbolizer
6. **LineSymbolizer → PolylineLayer**
7. **MarkSymbolizer → MarkerLayer** — CustomPaint für Well-Known-Names
8. **TextSymbolizer → MarkerLayer** — Text-Widget mit Halo
9. **IconSymbolizer → MarkerLayer** — Image-Widget
10. **StyleRenderer** — Orchestrierung, Batch-Reihenfolge und optionale Interaktion
11. **Caching-Schicht** — zuerst Rule-/Expression-Caches, dann Symbolizer-Werte
12. **RasterSymbolizer → TileLayer** (optional, niedrigere Priorität)
