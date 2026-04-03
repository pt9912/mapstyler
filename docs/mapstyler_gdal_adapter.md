# mapstyler_gdal_adapter

Package-Entwurf fuer einen GDAL-basierten Geodaten-Adapter auf Basis
von `gdal_dart` (pub.dev).

## Abgrenzung zu den Style-Adaptern

Die bestehenden Adapter (`mapstyler_sld_adapter`,
`mapstyler_mapbox_adapter`, `mapstyler_qml_adapter`) konvertieren
**Style-Formate** in das gemeinsame Kernmodell.

`mapstyler_gdal_adapter` konvertiert **Geodaten** (Features und
Geometrien) aus beliebigen OGR-unterstuetzten Vektorformaten in
`StyledFeatureCollection`-Instanzen, die direkt an
`StyleRenderer.renderStyle()` uebergeben werden koennen.

### Feature-Typen im Kernmodell

`StyledFeature` und `StyledFeatureCollection` leben in
`mapstyler_style` (pure Dart, kein Flutter). Der Adapter haengt
nur von `mapstyler_style` ab und kann Features ohne
Flutter-Abhaengigkeit erzeugen.

`flutter_mapstyler` erweitert die Collection per Extension um
einen R-Tree-Index fuer Viewport-Abfragen.

```text
Style-Adapter                     Daten-Adapter
  SLD / Mapbox / QML                Shapefile / GeoJSON / GeoPackage / ...
        |                                  |
        v                                  v
  mapstyler_style (Style,           mapstyler_gdal_adapter
    StyledFeature,                         |
    StyledFeatureCollection)               v
                                    StyledFeatureCollection
                                           |
        +----------------------------------+
        |
        v
  flutter_mapstyler (Rendering, R-Tree)
        |
        v
  flutter_map
```

## Rolle im Workspace

```text
gdal_dart (pub.dev, FFI)
       |
       v
mapstyler_gdal_adapter
  -> iteriert OGR-Features (lazy, ein Feature nach dem anderen)
  -> vereinfacht Geometrien waehrend der Iteration (Douglas-Peucker)
  -> mappt gdal_dart-Geometrien auf mapstyler_style-Geometrien
  -> leitet Spatial- und Attribut-Filter an OGR durch
       |
       v
StyledFeatureCollection (nur vereinfachte Geometrien im Speicher)
       |
       v
flutter_mapstyler (Rendering)
```

Der Adapter kennt weder Style-Formate noch Rendering. Er nimmt
Vektordaten entgegen und liefert typisierte Features zurueck.

Die Geometrie-Vereinfachung geschieht **waehrend der Iteration**
ueber die GDAL-Features. Die vollen Koordinaten ueberqueren die
FFI-Grenze als `gdal_dart`-Objekte, werden aber sofort
vereinfacht und nur in reduzierter Form als
`mapstyler_style`-Geometrien materialisiert. Die
Original-Aufloesung wird nie als vollstaendige
`StyledFeatureCollection` im Speicher gehalten.

## Geometrie-Mapping

| gdal_dart                 | mapstyler_style          | Anmerkung                       |
|---------------------------|--------------------------|----------------------------------|
| `Point(x, y)`            | `PointGeometry(x, y)`    | Z-Koordinate wird verworfen      |
| `LineString(points)`      | `LineStringGeometry(coords)` | `Point.x/y` → `(double, double)` |
| `Polygon(rings)`          | `PolygonGeometry(rings)`  | Rings analog zu LineString       |
| `MultiPoint`              | mehrere `PointGeometry`  | Aufspaltung in Einzel-Features   |
| `MultiLineString`         | mehrere `LineStringGeometry` | Aufspaltung in Einzel-Features |
| `MultiPolygon`            | mehrere `PolygonGeometry` | Aufspaltung in Einzel-Features  |
| `GeometryCollection`      | --                        | Warnung, kein Mapping            |

Multi-Geometrien werden in einzelne Features aufgespalten (analog zum
bestehenden `geojson_loader.dart` in der Demo-App). Die Properties
werden dabei kopiert, die Feature-ID um einen Suffix erweitert
(`'$fid-$i'`).

## Geometrie-Vereinfachung (Douglas-Peucker)

Die Vereinfachungs-Algorithmen (radiale Vorfilterung +
Douglas-Peucker fuer Linien, ringspezifische Variante fuer
Polygone) leben in `mapstyler_style`, nicht im Adapter. Sie
arbeiten auf `List<(double, double)>` — dem Koordinatenformat
von `LineStringGeometry` und `PolygonGeometry`. So koennen auch
andere Consumer (Renderer, Demo-Loader) sie direkt nutzen.

Der Adapter wendet die Vereinfachung **waehrend der Iteration**
ueber die GDAL-Features an. Da `gdal_dart` einen lazy
Feature-Iterator bietet, ist die Iteration der fruehestmoegliche
Punkt: jede Geometrie wird waehrend der Konvertierung
vereinfacht, bevor sie als `StyledFeature` materialisiert wird.

```text
OgrLayer.features (lazy Iterator, volle Aufloesung)
       |
       v  pro Feature, waehrend der Iteration:
  gdal_dart Geometry (volle Koordinaten in Dart, kurzlebig)
       |
       v
  Koordinaten extrahieren (gd.Point → (double, double))
       |
       v
  radiale Vorfilterung (schnell, entfernt redundante Punkte)
       |
       v
  Douglas-Peucker (formerhaltendes Auslichten)
       |
       v  nur die reduzierten Koordinaten werden materialisiert:
  mapstyler_style Geometry (reduziert)
       |
       v
StyledFeature (nur reduzierte Koordinaten im Speicher)
```

Die vollen Koordinaten existieren kurzzeitig als Dart-Objekte,
werden aber nicht als mapstyler_style-Geometrien aufgebaut.
Nur die vereinfachten Koordinaten fliessen in die Collection.

### Zweistufiger Algorithmus

**Fuer Linien (`LineString`):**

1. **Radiale Vorfilterung** — entfernt Punkte, die naeher als
   `tolerance` am vorherigen behaltenen Punkt liegen. O(n),
   ein Durchgang. Reduziert die Eingabe fuer Douglas-Peucker
   erheblich.

2. **Douglas-Peucker** — rekursive Vereinfachung, die die Form
   der Linie erhaelt. O(n log n) durchschnittlich. Entfernt alle
   Punkte, deren Abstand zur vereinfachten Linie kleiner als
   `tolerance` ist.

**Fuer Polygon-Ringe (`Polygon`):**

Polygon-Ringe benoetigen eine eigene Behandlung gegenueber
offenen Linien:

1. **Ringschluss sicherstellen** — erster und letzter Punkt
   muessen nach der Vereinfachung identisch bleiben. Der
   Algorithmus fixiert beide Endpunkte und vereinfacht nur die
   dazwischenliegenden Koordinaten.

2. **Mindestpunktzahl** — ein gueltiger Ring braucht mindestens
   4 Punkte (3 eindeutige + Schluss). Faellt ein Ring unter
   diese Grenze, wird er unvereinbart uebernommen (Exterior)
   oder verworfen (Interior/Loch).

3. **Topologie** — Selbstschneidungen und Ring-Ueberlappungen
   werden nicht aktiv erkannt oder repariert, sondern durch
   konservative Toleranzwahl vermieden. Degenerierte Innenringe
   (< 4 Punkte) werden verworfen.

Die Vereinfachung wird also nicht blind per `_simplifyCoords`
auf jeden Ring angewandt, sondern ueber eine eigene Funktion
`_simplifyRing` mit Ringschluss- und Mindestpunktzahl-Logik.

### Toleranz und Einheiten

Die Toleranz-Einheit haengt vom Koordinatensystem der Quelldaten ab:

| CRS-Typ                    | Einheit | Beispiel-CRS              |
|----------------------------|---------|----------------------------|
| Geographisch               | Grad    | EPSG:4326 (WGS 84)        |
| Projiziert                 | Meter   | EPSG:3857, UTM-Zonen      |

Da der Adapter via `gdal_dart` das CRS der Daten kennt, bietet
die API zwei Wege:

```dart
/// Toleranz in der nativen Einheit des Quell-CRS
/// (Grad fuer EPSG:4326, Meter fuer projizierte CRS).
double? simplifyTolerance;

/// Toleranz in Metern — der Adapter rechnet intern in die
/// native CRS-Einheit um. Fuer geographische CRS wird eine
/// breitenabhaengige Naeherung verwendet:
///   toleranceDeg ≈ toleranceMeters / (111_320 * cos(lat))
double? simplifyToleranceMeters;
```

Nur einer der beiden Parameter darf gesetzt werden. Bei
`simplifyToleranceMeters` bestimmt der Adapter die Umrechnung
anhand des Layer-CRS und des Layer-Extents (mittlere Breite).

### Toleranz-Berechnung

```
tolerance = 0.5 * resolution
```

`resolution` ist die Aufloesung der Kartenansicht in der
jeweiligen Einheit pro Pixel:

| Kartentyp            | resolution                           | Einheit  |
|----------------------|--------------------------------------|----------|
| OSM / Web-Mercator   | `360 / (256 * 2^zoom)`               | Grad/px  |
| GeoTIFF (Raster)     | Pixelgroesse aus GeoTransform        | CRS-abh. |
| Fester Massstab      | `massstab * 0.00028`                 | m/px     |

Beispiel fuer EPSG:4326 mit Web-Mercator-Kacheln:

| Zoom | resolution (Grad/px) | tolerance (Grad) | Effekt bei 10.000 Punkten |
|------|----------------------|-------------------|---------------------------|
| 5    | 0.0439               | 0.022             | ~20 Punkte                |
| 10   | 0.00137              | 0.00069           | ~200 Punkte               |
| 15   | 0.0000429            | 0.0000215         | ~2.000 Punkte             |
| --   | 0 (Original)         | 0                 | alle Punkte               |

Beispiel fuer EPSG:3857 (projiziert, Meter):

| Massstab  | resolution (m/px) | tolerance (m) | Effekt bei 10.000 Punkten |
|-----------|-------------------|---------------|---------------------------|
| 1:500.000 | 140               | 70            | ~20 Punkte                |
| 1:50.000  | 14                | 7             | ~500 Punkte               |
| 1:5.000   | 1.4               | 0.7           | ~5.000 Punkte             |

### Multi-Scale-Laden

Fuer Anwendungen mit interaktivem Zoom oder wechselndem Massstab
kann der Adapter mehrere LOD-Stufen (Level of Detail) in einem
Durchlauf erzeugen:

Alle Stufen werden in **einem Iterationsdurchlauf** berechnet:
pro Feature werden alle Toleranzen gleichzeitig angewendet.
Die GDAL-Daten werden nur einmal gelesen.

## API-Entwurf

### Oeffentliche API

Die Lade-API ist **asynchron** und fuehrt die GDAL-Iteration
sowie die Vereinfachung in einem eigenen Isolate aus, damit das
UI nicht blockiert wird. Fuer CLI-/Server-Anwendungen wird eine
synchrone Variante bereitgestellt.

Wichtig fuer die Implementierung:

- `dart:ffi`-Handles oder GDAL-Objekte werden **nicht** zwischen
  Isolates uebertragen
- der Worker-Isolate oeffnet Datei und Layer selbst und initialisiert
  dabei die noetigen GDAL-Ressourcen lokal
- an den aufrufenden Isolate werden nur reine Dart-Daten
  (`StyledFeatureCollection`, `VectorLayerInfo`, primitive Werte)
  zurueckgegeben

```dart
import 'package:mapstyler_gdal_adapter/mapstyler_gdal_adapter.dart';

/// Laedt Vektordaten asynchron in einem eigenen Isolate.
///
/// [path] kann auf jedes von OGR unterstuetzte Vektorformat zeigen
/// (Shapefile, GeoJSON, GeoPackage, KML, GML, MapInfo, ...).
///
/// [layerName] und [layerIndex] sind exklusiv. Wenn [layerName]
/// gesetzt ist, wird [layerIndex] ignoriert. Ohne Angabe wird
/// Layer 0 verwendet.
///
/// [simplifyTolerance] aktiviert die zweistufige Geometrie-
/// Vereinfachung (radiale Vorfilterung + Douglas-Peucker) waehrend
/// der Iteration. Die Einheit ist die native CRS-Einheit der
/// Quelldaten (Grad bei EPSG:4326, Meter bei projizierten CRS).
///
/// Alternativ kann [simplifyToleranceMeters] in Metern angegeben
/// werden — der Adapter rechnet anhand des Layer-CRS um.
///
/// [spatialFilter] und [attributeFilter] werden serverseitig von
/// OGR angewendet — nur passende Features ueberqueren die
/// FFI-Grenze.
Future<StyledFeatureCollection> loadVectorFile(
  String path, {
  int layerIndex = 0,
  String? layerName,
  double? simplifyTolerance,
  double? simplifyToleranceMeters,
  ({double minX, double minY, double maxX, double maxY})? spatialFilter,
  String? attributeFilter,
});

/// Synchrone Variante fuer CLI-Tools und Server-Anwendungen.
///
/// Identische Parameter wie [loadVectorFile], blockiert aber den
/// aufrufenden Thread.
StyledFeatureCollection loadVectorFileSync(
  String path, {
  int layerIndex = 0,
  String? layerName,
  double? simplifyTolerance,
  double? simplifyToleranceMeters,
  ({double minX, double minY, double maxX, double maxY})? spatialFilter,
  String? attributeFilter,
});

/// Laedt mehrere vorberechnete Vereinfachungsstufen asynchron in einem
/// eigenen Isolate.
///
/// Genau einer der beiden Parameter [tolerances] oder
/// [tolerancesMeters] darf gesetzt sein.
///
/// - [tolerances]: Toleranzen in nativer CRS-Einheit
/// - [tolerancesMeters]: Toleranzen in Metern; der Adapter rechnet
///   intern in die native CRS-Einheit um
///
/// Die Rueckgabe mappt die **effektiv verwendete native Toleranz**
/// auf die jeweilige `StyledFeatureCollection`. Zusaetzlich wird immer
/// eine Stufe `0.0` fuer die Originalgeometrien erzeugt.
Future<Map<double, StyledFeatureCollection>> loadVectorFileMultiScale(
  String path, {
  List<double>? tolerances,
  List<double>? tolerancesMeters,
  int layerIndex = 0,
  String? layerName,
  ({double minX, double minY, double maxX, double maxY})? spatialFilter,
  String? attributeFilter,
});

/// Synchrone Variante fuer CLI-Tools und Server-Anwendungen.
Map<double, StyledFeatureCollection> loadVectorFileMultiScaleSync(
  String path, {
  List<double>? tolerances,
  List<double>? tolerancesMeters,
  int layerIndex = 0,
  String? layerName,
  ({double minX, double minY, double maxX, double maxY})? spatialFilter,
  String? attributeFilter,
});
```

### Layer-Metadaten

```dart
/// Gibt Metadaten ueber die Layer einer Vektordatei asynchron zurueck,
/// ohne Features zu laden.
///
/// Laeuft analog zu [loadVectorFile] in einem eigenen Isolate, damit
/// Datei- und Layerauswahl in Flutter-Apps den UI-Thread nicht blockiert.
Future<List<VectorLayerInfo>> inspectVectorFile(String path);

/// Synchrone Variante fuer CLI-Tools und Server-Anwendungen.
List<VectorLayerInfo> inspectVectorFileSync(String path);

class VectorLayerInfo {
  final String name;
  final int featureCount;
  final List<({String name, String type})> fields;
  final ({double minX, double minY, double maxX, double maxY})? extent;
  final String? geometryType; // z.B. 'Point', 'Polygon', 'MultiLineString'
  final String? crs;          // z.B. 'EPSG:4326'
}
```

## Konvertierungslogik

```dart
// Pseudocode der internen Konvertierung:

StyledFeatureCollection _convert(OgrLayer layer, {double? tolerance}) {
  final features = <StyledFeature>[];

  // Lazy Iteration — GDAL materialisiert ein Feature nach dem anderen.
  for (final f in layer.features) {
    final geometry = f.geometry;
    if (geometry == null) continue;

    // Konvertierung + Vereinfachung in einem Schritt.
    // Die volle Aufloesung existiert nur kurz als gdal_dart-Objekt
    // und wird nie als mapstyler_style-Geometry materialisiert.
    final converted = _convertGeometry(geometry, tolerance);

    for (final (i, geo) in converted.indexed) {
      features.add(StyledFeature(
        id: converted.length == 1 ? '${f.fid}' : '${f.fid}-$i',
        geometry: geo,
        properties: f.attributes,
      ));
    }
  }

  return StyledFeatureCollection(features);
}

/// Konvertiert eine gdal_dart-Geometrie in mapstyler_style-Geometrien.
///
/// Linien werden per _simplifyLine vereinfacht, Polygon-Ringe per
/// _simplifyRing (mit Ringschluss und Mindestpunktzahl).
/// Points bleiben unveraendert, Multi-Geometrien werden aufgespalten.
List<Geometry> _convertGeometry(gd.Geometry geometry, double? tolerance) =>
    switch (geometry) {
      gd.Point(:final x, :final y) => [PointGeometry(x, y)],
      gd.LineString(:final points) => [
        LineStringGeometry(_simplifyLineFromPoints(points, tolerance)),
      ],
      gd.Polygon(:final rings) =>
        _convertPolygon(rings, tolerance),
      gd.MultiPoint(:final points) =>
        points.map((p) => PointGeometry(p.x, p.y)).toList(),
      gd.MultiLineString(:final lineStrings) => lineStrings
          .map((ls) =>
              LineStringGeometry(_simplifyLineFromPoints(ls.points, tolerance)))
          .toList(),
      gd.MultiPolygon(:final polygons) => polygons
          .expand((poly) => _convertPolygon(poly.rings, tolerance))
          .toList(),
      _ => [],
    };

/// Konvertiert Polygon-Ringe mit ringspezifischer Vereinfachung.
///
/// - Exterior-Ring (Index 0): wird immer beibehalten, mindestens
///   4 Punkte, Ringschluss gesichert.
/// - Interior-Ringe (Loecher): werden verworfen wenn sie unter
///   4 Punkte fallen oder nach Vereinfachung degeneriert sind.
List<Geometry> _convertPolygon(
    List<gd.LineString> rings, double? tolerance) {
  if (rings.isEmpty) return [];
  final simplified = <List<(double, double)>>[];

  for (var i = 0; i < rings.length; i++) {
    final ring = _simplifyRingFromPoints(rings[i].points, tolerance);
    if (ring.length >= 4) {
      simplified.add(ring);
    } else if (i == 0) {
      // Exterior-Ring zu klein → Polygon unvereinbart uebernehmen
      return [PolygonGeometry(
        rings.map((r) => r.points.map((p) => (p.x, p.y)).toList()).toList(),
      )];
    }
    // Interior-Ring zu klein → stillschweigend verwerfen
  }
  return [PolygonGeometry(simplified)];
}

// simplifyLine und simplifyRing kommen aus mapstyler_style:
//   import 'package:mapstyler_style/mapstyler_style.dart';
//
// simplifyLine(coords, tolerance) — offene Linie
// simplifyRing(coords, tolerance) — geschlossener Ring

/// Extrahiert Koordinaten und vereinfacht per mapstyler_style.
List<(double, double)> _simplifyLineFromPoints(
  List<gd.Point> points,
  double? tolerance,
) {
  final coords = points.map((p) => (p.x, p.y)).toList();
  return tolerance != null && tolerance > 0
      ? simplifyLine(coords, tolerance)
      : coords;
}

List<(double, double)> _simplifyRingFromPoints(
  List<gd.Point> points,
  double? tolerance,
) {
  final coords = points.map((p) => (p.x, p.y)).toList();
  return tolerance != null && tolerance > 0
      ? simplifyRing(coords, tolerance)
      : coords;
}
```

## Package-Entwurf

```text
mapstyler_gdal_adapter/
  lib/
    mapstyler_gdal_adapter.dart        <-- barrel export
    src/
      load_vector_file.dart            <-- async API (Isolate-Wrapper)
      load_vector_file_sync.dart       <-- synchrone Variante
      isolate_worker.dart              <-- Isolate-Einstiegspunkt
      geometry_converter.dart          <-- gdal_dart → mapstyler_style
      vector_layer_info.dart           <-- Metadaten-Modell
  test/
    geometry_converter_test.dart
    load_vector_file_test.dart
  example/
    mapstyler_gdal_adapter_example.dart
  pubspec.yaml
```

Die oeffentlichen Vereinfachungsfunktionen `simplifyLine` und
`simplifyRing` liegen in `mapstyler_style` und werden hier nur
aufgerufen.

## Abhaengigkeiten

```yaml
dependencies:
  gdal_dart: ^0.2.0
  mapstyler_style: ^0.1.0

dev_dependencies:
  test: ^1.25.0
```

Keine Abhaengigkeit auf `flutter_mapstyler` oder Flutter selbst.
Der Adapter ist pure Dart (plus FFI via `gdal_dart`) und damit auch
in CLI-Tools und Server-Anwendungen nutzbar.

## Plattform-Einschraenkungen

| Plattform       | Unterstuetzt | Anmerkung                           |
|-----------------|--------------|--------------------------------------|
| Linux Desktop   | ja           | GDAL ueber Paketmanager installieren |
| macOS Desktop   | ja           | GDAL ueber Homebrew                  |
| Windows Desktop | ja           | GDAL-Binaries / vcpkg                |
| Android         | moeglich     | GDAL cross-kompilieren               |
| iOS             | moeglich     | GDAL cross-kompilieren               |
| Web             | nein         | FFI nicht verfuegbar                  |

Die nativen GDAL-Libraries muessen auf dem Zielsystem vorhanden sein.
`gdal_dart` bindet sie zur Laufzeit ueber `dart:ffi`.

## Verhaeltnis zu den Demo-App-Loadern

Die Demo-App enthaelt zwei leichtgewichtige pure-Dart-Loader:

- `shapefile_loader.dart` (SHP/DBF, ~330 Zeilen)
- `geojson_loader.dart` (GeoJSON, ~70 Zeilen)

Diese bleiben bestehen. Sie haben keine nativen Abhaengigkeiten
und sind fuer die Demo-App ausreichend. `mapstyler_gdal_adapter`
ist eine optionale Erweiterung fuer Anwendungen, die weitere
Formate oder serverseitige Filterung benoetigen.

## Offene Punkte

### MVP

- [ ] `loadVectorFile()` (async, Isolate) mit Layer-Auswahl,
      Filterung und `simplifyTolerance`
- [ ] `loadVectorFileSync()` fuer CLI/Server
- [ ] Geometrie-Mapping fuer Point, LineString, Polygon und
      Multi-Varianten
- [ ] Vereinfachung aus `mapstyler_style` (`simplifyLine`,
      `simplifyRing`) waehrend der Feature-Iteration anwenden
- [ ] `loadVectorFileMultiScale()` / `loadVectorFileMultiScaleSync()`
      fuer vorberechnete LOD-Stufen
- [ ] `inspectVectorFile()` / `inspectVectorFileSync()` fuer
      Layer-Metadaten
- [ ] Tests: Linien-Vereinfachung, Ring-Vereinfachung
      (Schluss, Mindestpunktzahl, Topologie), Geometrie-Mapping,
      Lese-/Konvertierungstests mit Shapefile, GeoJSON und GeoPackage

#### Loesungsansatz fuer den MVP

**`loadVectorFile()` (async, Isolate)**

Loesung:
- oeffentliche Async-API als duenne Huelle ueber `Isolate.run(...)`
  oder einen dedizierten Worker in `src/isolate_worker.dart`
- Isolate-Eingabe als serialisierbare Request-Struktur modellieren:
  `path`, `layerIndex`, `layerName`, `simplifyTolerance`,
  `simplifyToleranceMeters`, `spatialFilter`, `attributeFilter`
- der Worker ruft intern dieselbe synchrone Kernlogik auf wie
  `loadVectorFileSync()`, damit es nur einen Konvertierungspfad gibt
- Fehler aus GDAL/FFI in packageeigene Exceptions oder
  `ArgumentError`/`StateError` mit klarer Datei-/Layer-Info uebersetzen

Ziel fuer die erste Version:
- Flutter-Apps koennen Vektordaten laden, ohne den UI-Thread zu blockieren
- die gesamte Fachlogik bleibt dennoch in einer synchronen Kernfunktion

**`loadVectorFileSync()` fuer CLI/Server**

Loesung:
- synchrone Kernfunktion in `src/load_vector_file_sync.dart`
- dieselben Parameter und dieselbe Validierung wie die Async-Variante
- Async-API delegiert intern nur an diesen Pfad

Ziel fuer die erste Version:
- keine doppelte Fachlogik
- gute Nutzbarkeit fuer Tests, Skripte und Server-Anwendungen

**Geometrie-Mapping fuer Point, LineString, Polygon und Multi-Varianten**

Loesung:
- zentrale Konvertierung in `geometry_converter.dart`
- `Point`, `LineString`, `Polygon` direkt auf die entsprechenden
  `mapstyler_style`-Geometrien abbilden
- `MultiPoint`, `MultiLineString`, `MultiPolygon` in mehrere
  `StyledFeature`-Instanzen aufspalten
- `GeometryCollection` in der ersten Version bewusst nicht unterstuetzen:
  Warnung oder Fehler sammeln, aber nicht raten
- Feature-IDs fuer Multi-Geometrien stabil erweitern, z.B. `fid`,
  `fid-0`, `fid-1`

Ziel fuer die erste Version:
- sauberes und deterministisches Mapping fuer die haeufigen
  OGR-Geometrietypen
- keine implizite Magie fuer exotische Sammelgeometrien

**Geometrie-Vereinfachung (aus `mapstyler_style`)**

Die Vereinfachungs-Algorithmen liegen in `mapstyler_style`, nicht
im Adapter. Der Adapter ruft `simplifyLine` und `simplifyRing`
auf und uebergibt die aus `gdal_dart`-Punkten extrahierten
Koordinaten.

Details zu Algorithmus, Ringschluss, Mindestpunktzahl und
Topologie-Verhalten: siehe `mapstyler_style`-Roadmap und den
Abschnitt [Geometrie-Vereinfachung](#geometrie-vereinfachung-douglas-peucker)
weiter oben.

**`loadVectorFileMultiScale()` fuer vorberechnete LOD-Stufen**

Loesung:
- pro Feature die Rohkoordinaten einmal extrahieren und danach gegen
  mehrere Toleranzen vereinfachen
- Ergebnis als `Map<double, StyledFeatureCollection>` mit zusaetzlicher
  `0.0`-Stufe fuer Originalgeometrien
- Async-API und Sync-API ueber denselben Kernpfad aufbauen, analog zu
  `loadVectorFile()` / `loadVectorFileSync()`
- genau einer der beiden Parameter `tolerances` oder
  `tolerancesMeters` darf gesetzt sein
- Toleranzen vorab normalisieren: sortieren, deduplizieren, nur
  positive Werte zusaetzlich zur Originalstufe zulassen

Ziel fuer die erste Version:
- ein Lese-Durchlauf fuer mehrere Darstellungsstufen
- einfache Auswahl der passenden Stufe in der Host-App

**`inspectVectorFile()` / `inspectVectorFileSync()` fuer Layer-Metadaten**

Loesung:
- Metadaten-API getrennt vom Feature-Laden halten
- `name`, `featureCount`, `fields` und `extent` direkt aus dem OGR-Layer
  lesen, ohne Features komplett zu konvertieren
- Async-Variante analog zu `loadVectorFile()` im Isolate ausfuehren
- Sync-Variante fuer CLI und Tests direkt bereitstellen

Ziel fuer die erste Version:
- Datei- und Layerauswahl ohne Vollimport
- dieselbe Nutzbarkeit in Flutter und in reinen Dart-Umgebungen

**Tests**

Loesung:
- Vereinfachungsalgorithmen isoliert und ohne GDAL-Mock testen, wo
  moeglich
- Ring-Tests explizit auf Ringschluss, Mindestpunktzahl und Verhalten
  degenerierter Loecher ausrichten
- Geometrie-Mapping pro OGR-Typ in kleinen, gerichteten Testfaellen
  pruefen
- dateibasierte Integrationstests mit kleinen Fixtures fuer
  Shapefile, GeoJSON und GeoPackage
- Async- und Sync-API gegen dieselben erwarteten Ergebnisse laufen
  lassen

Ziel fuer die erste Version:
- hohe Sicherheit in der Kernlogik
- echte Formatabdeckung statt nur algorithmischer Unit-Tests

### Spaeter

- [ ] CRS-Transformation via `gdal_dart` `CoordinateTransform`
      (z.B. automatische Reprojektion nach EPSG:4326)
- [ ] Streaming-API fuer grosse Dateien (Feature-Iterator statt
      vollstaendige Materialisierung)
- [ ] Rueckkanal: `StyledFeatureCollection` zurueck in ein
      OGR-Format schreiben

## Verwandte Dokumente

- [architecture.md](architecture.md) -- Workspace-Architektur
- [mapstyler.md](mapstyler.md) -- Core-Style-Modell
- [flutter_mapstyler.md](flutter_mapstyler.md) -- Renderer-API
- [roadmap.md](roadmap.md) -- Geplante Entwicklung
