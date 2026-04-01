# flutter_mapstyler — mapstyler-Stile auf flutter_map rendern

Flutter-Package, das `mapstyler_style`-Typen in `flutter_map`-Layer und -Styles übersetzt. Bindeglied zwischen dem plattformunabhängigen mapstyler-Ökosystem und der Flutter-Kartenvisualisierung.

## Einordnung im Ökosystem

```
SLD XML ─→ flutter_map_sld ─→ mapstyler_sld_adapter ─┐
Mapbox JSON ─→ mapstyler_mapbox_parser ───────────────┤
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

/// Konvertiert mapstyler-Regeln in flutter_map-Layer.
class StyleRenderer {
  const StyleRenderer();

  /// Wendet einen kompletten Style auf GeoJSON-Features an.
  /// Gibt eine geordnete Liste von flutter_map-Layern zurück.
  List<Widget> renderStyle({
    required Style style,
    required FeatureCollection features,
    double? scaleDenominator,
  });

  /// Wendet eine einzelne Regel auf passende Features an.
  List<Widget> renderRule({
    required Rule rule,
    required List<Feature> features,
  });

  /// Konvertiert einen einzelnen Symbolizer in Layer-Optionen.
  /// Nützlich für eigene Rendering-Pipelines.
  LayerOptions? symbolizerToLayer({
    required Symbolizer symbolizer,
    required List<Feature> features,
  });
}
```

### Expression-Auswertung

`mapstyler_style` Expressions (`LiteralExpression`, `FunctionExpression`) müssen zur Render-Zeit gegen Feature-Properties evaluiert werden:

```dart
/// Wertet eine Expression gegen Feature-Properties aus.
T evaluateExpression<T>(
  Expression<T> expression,
  Map<String, dynamic> properties,
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
  Filter filter,
  Map<String, dynamic> properties, {
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

Keine Abhängigkeit auf `flutter_map_sld`, `mapstyler_mapbox_parser` o.ä. — das Package arbeitet nur mit den abstrakten `mapstyler_style`-Typen.

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

## Offene Design-Fragen

1. **GeoJSON-Modell:** Welches GeoJSON-Package nutzen? (`geojson_vi`, `dart_geojson`, eigenes?) Oder Feature-Daten als `Map<String, dynamic>` + Koordinaten-Listen?
2. **Layer-Strategie:** Ein Layer pro Symbolizer-Typ (Fill, Line, Mark) oder ein kombinierter Layer pro Regel?
3. **Performance:** Wie mit großen Feature-Sammlungen umgehen? Lazy Evaluation? Clustering für Marker?
4. **Interaktivität:** Soll der Renderer Tap-Callbacks pro Feature unterstützen?
5. **Caching:** Berechnete Styles cachen? Expression-Ergebnisse pro Feature memorisieren?

## Implementierungsreihenfolge

1. **Expression-Evaluator** — `evaluateExpression<T>()` für Literal + PropertyGet
2. **Filter-Evaluator** — `evaluateFilter()` für Comparison + Combination + Negation
3. **FillSymbolizer → PolygonLayer** — einfachster Symbolizer
4. **LineSymbolizer → PolylineLayer**
5. **MarkSymbolizer → MarkerLayer** — CustomPaint für Well-Known-Names
6. **TextSymbolizer → MarkerLayer** — Text-Widget mit Halo
7. **IconSymbolizer → MarkerLayer** — Image-Widget
8. **Scale-basierte Regelauswahl**
9. **StyleRenderer** — Orchestrierung aller Symbolizer
10. **RasterSymbolizer → TileLayer** (optional, niedrigere Priorität)
