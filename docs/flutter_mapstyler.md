# flutter_mapstyler

Diese Datei beschreibt den aktuellen Zuschnitt von `flutter_mapstyler`
innerhalb des Workspaces. Fokus sind:

- das Eingabemodell des Renderers
- die öffentliche Renderer-API
- die wichtigsten Laufzeitentscheidungen

Architektur des gesamten Repositories ist in
[architecture.md](architecture.md) dokumentiert.

## Rolle im Workspace

`flutter_mapstyler` ist die Rendering-Schicht des `mapstyler`-
Ökosystems:

```text
Format-Adapter
  -> mapstyler_style
  -> flutter_mapstyler
  -> flutter_map
```

Das Package rendert nicht direkt aus Mapbox, SLD oder QML. Es arbeitet
mit:

- `Style`, `Rule`, `Symbolizer`, `Filter`, `Expression` aus
  `mapstyler_style`
- `StyledFeature` / `StyledFeatureCollection` aus `mapstyler_style`
- einem in `flutter_mapstyler` ergaenzten R-Tree-Zugriff fuer
  Viewport-Abfragen

## Eingabemodell

Der Renderer erwartet bewusst kein externes GeoJSON-Package. Stattdessen
nutzt er das kleine, stabile Feature-Modell aus `mapstyler_style`,
das `flutter_mapstyler` direkt re-exportiert:

```dart
final class StyledFeature {
  final Object? id;
  final Geometry geometry;
  final Map<String, Object?> properties;
}

final class StyledFeatureCollection {
  final List<StyledFeature> features;
}
```

`flutter_mapstyler` selbst ergaenzt darauf einen lazy aufgebauten
R-Tree-Index per Extension, ohne die Feature-Typen wieder in die
Rendering-Schicht zurueckzuziehen.

Konsequenzen:

- Geometrien kommen aus `mapstyler_style`
- Properties bleiben als freie Map erhalten
- Parsing von GeoJSON oder anderen Quellformaten passiert außerhalb des
  Renderers

## Öffentliche API

Der zentrale Einstiegspunkt ist `StyleRenderer`:

```dart
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

  List<Widget> renderRule({
    required Rule rule,
    required List<StyledFeature> features,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  });

  Widget? symbolizerToLayer({
    required Symbolizer symbolizer,
    required List<StyledFeature> features,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  });
}
```

Zusätzlich gibt es:

- `evaluateExpression<T>()`
- `evaluateFilter()`
- `selectRulesAtScale()`

## Rendering-Modell

Der Renderer arbeitet regelorientiert, nicht global symbolizerorientiert.

Das heißt:

- `renderStyle` bewahrt die Reihenfolge von `style.rules`
- pro passender Regel werden die enthaltenen Symbolizer nacheinander
  gerendert
- das Ergebnis ist eine geordnete Liste von `flutter_map`-Widgets

Diese Entscheidung priorisiert korrekte Z-Order und ein leicht
verständliches Mapping zwischen Style und Render-Ergebnis.

## Unterstützte Symbolizer

Aktuell rendert `flutter_mapstyler`:

- `FillSymbolizer`
- `LineSymbolizer`
- `MarkSymbolizer`
- `IconSymbolizer`
- `TextSymbolizer`
- `RasterSymbolizer`

Grob entspricht das:

| `mapstyler_style` | `flutter_map` |
|---|---|
| `FillSymbolizer` | `PolygonLayer` |
| `LineSymbolizer` | `PolylineLayer` |
| `MarkSymbolizer` | `MarkerLayer` mit `CustomPaint` |
| `IconSymbolizer` | `MarkerLayer` |
| `TextSymbolizer` | `MarkerLayer` |
| `RasterSymbolizer` | Raster-Layer/Overlay-Pfade |

## Filter, Expressions und Maßstab

Der Renderpfad wertet nicht nur statische Symbolizer aus, sondern auch:

- `ScaleDenominator` zur Regelauswahl
- `Filter` zur Feature-Selektion
- `Expression<T>` gegen Feature-Properties

Damit kann derselbe Style sowohl feste als auch datengetriebene
Darstellungen erzeugen.

## Viewport und Interaktion

Der aktuelle Renderpfad unterstützt optional:

- Viewport-basiertes Vorfiltern über `LatLngBounds viewport`
- Tap-Callbacks pro Feature
- Long-Press-Callbacks pro Feature

Interaktion ist optional. Ohne gesetzte Callbacks bleibt der Renderpfad
auf reine Darstellung fokussiert.

## Caching und Laufzeitverhalten

Der Renderer verwendet gezieltes Caching an zwei Stellen:

- ausgewählte Regeln pro `Style` und Maßstab
- vorbereitete Evaluatoren und stabile per-Feature-Ergebnisse pro
  `Style`

Wichtig dabei:

- Caching ist stylegebunden, nicht global
- `renderRule` und `symbolizerToLayer` können auch ohne vollständigen
  styleweiten Kontext genutzt werden
- Features ohne stabile `id` profitieren nur eingeschränkt von
  persistentem per-Feature-Caching

## Raster-Konventionen

Raster-Rendering wird aktuell über Feature-Properties gesteuert. Es gibt
zwei typische Fälle:

- Tile-basierte Raster mit Properties wie `urlTemplate`, `subdomains`,
  `minZoom`, `maxZoom`
- Overlay-Raster mit `EnvelopeGeometry` plus `image`, `url` oder `asset`

Diese Konventionen gehören bewusst zur Renderer-Schicht und nicht in das
allgemeine Kernmodell.

## Abgrenzung

`flutter_mapstyler` ist bewusst nicht zuständig für:

- Parsing von GeoJSON
- Konvertierung aus Mapbox, SLD oder QML
- Clustering oder andere vorgelagerte Datenstrategien
- Bewahrung formatspezifischer Metadaten

Das Package rendert Styles. Es ersetzt nicht die Adapter- oder
Parsing-Schicht.

## Verwandte Dokumente

- [architecture.md](architecture.md)
- [mapstyler.md](mapstyler.md)
- [MAPBOX.md](MAPBOX.md)
