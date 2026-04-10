# mapstyler Roadmap

Diese Datei beschreibt die geplante Weiterentwicklung des
`mapstyler`-Workspaces auf hoher Ebene. Sie ist bewusst als
Zielrichtung formuliert, nicht als verbindlicher Release-Plan mit
festen Terminen.

## Zielbild

`mapstyler` soll ein zusammenhaengendes Dart-Oekosystem fuer
formatunabhaengige Kartenstile werden:

- `mapstyler_style` als stabiles Kernmodell
- `mapbox4dart` als Pure-Dart-Codec und Objektmodell fuer Mapbox GL
  Style JSON
- `qml4dart` als Pure-Dart-Codec und Objektmodell fuer QGIS-QML-
  Layer-Style-Dateien
- Adapter fuer SLD, QML und Mapbox
- `flutter_mapstyler` fuer das Rendering in Flutter
- datenorientierte Adapter wie `mapstyler_gdal_adapter` fuer
  Flutter-freie Feature-Loads aus Vektorformaten
- spaeter optional Editor- und Tooling-Packages auf Basis desselben
  Kernmodells

## Prioritaeten

Die naechsten Entwicklungsschritte konzentrieren sich auf:

1. Stabilisierung und Ergonomie des Kernmodells
2. Ausbau und Absicherung der Format-Adapter
3. Aufbau eines Daten-Adapters fuer externe Vektorformate
4. Performance und Reife des Flutter-Renderings
5. Vorbereitung eines eigenstaendigen Editor-Packages

## Package-Roadmap

### `mapstyler_style`

Ziel: Das Kernmodell soll klein, stabil und angenehm transformierbar
bleiben.

Umgesetzt:

- `copyWith()` fuer `Style`, `Rule`, `ScaleDenominator` und alle
  konkreten `Symbolizer`-Klassen (`FillSymbolizer`, `LineSymbolizer`,
  `MarkSymbolizer`, `IconSymbolizer`, `TextSymbolizer`,
  `RasterSymbolizer`).  Nullable Felder lassen sich per explizitem
  `null` loeschen; nicht uebergebene Felder behalten ihren Wert.
  Intern wird ein Sentinel-Pattern (`Absent`) verwendet, das in
  `lib/src/sentinel.dart` definiert und nicht exportiert wird.
- `Style.rules`, `Rule.symbolizers` und `ColorMap.colorMapEntries`
  werden per `List.unmodifiable` defensiv kopiert.  Damit sind die
  Listenfelder praktisch immutable.  `Style`, `Rule` und `ColorMap`
  verlieren dadurch ihren `const`-Konstruktor.
  `LineSymbolizer.dasharray` wird bewusst nicht defensiv kopiert, um
  den `const`-Konstruktor zu erhalten — dokumentiert im DartDoc.
- `copyWith` nutzt interne Konstruktoren (`Style._internal`,
  `Rule._internal`), wenn die Liste unveraendert bleibt, und
  vermeidet so doppeltes `List.unmodifiable`-Wrapping.
- Tests fuer feldweises Kopieren, Gleichheit und JSON-Roundtrips
  erweitert (39 neue Tests, 201 gesamt, 99,28 % Coverage).
- Bugfix: `LineSymbolizer.==` und `hashCode` beruecksichtigen jetzt
  `dasharray` (fehlte vorher).

Geplante Punkte:

- Factory-Methoden auf `Filter` fuer die haeufigsten Konstruktions-
  muster: `Filter.eq(prop, value)`, `Filter.neq(…)`, `Filter.lt(…)`
  usw. sowie `Filter.and(filters)`, `Filter.or(filters)` und
  `Filter.not(filter)`.  Reduziert ~50 verbose Konstruktionsstellen
  in den Adaptern auf je eine Zeile.
- `Expression.property<T>(name)` als Factory fuer das haeufige
  Pattern `FunctionExpression<T>(PropertyGet(name))`, das in Adaptern
  und Tests ~15-mal vorkommt.
- Getter `Expression<T>.literalValue` (liefert `T?`), der den Wert
  einer `LiteralExpression` direkt zurueckgibt und sonst `null`.
  Ersetzt die in jedem Adapter separat definierten Helfer
  `_literalString`, `_literalDouble`, `_literalInt`.
- `copyWith()` auf `Expression` und `Filter` wird bewusst nicht
  eingefuehrt — sealed Types mit wenigen Feldern profitieren davon
  nicht; Rekonstruktion ist der natuerliche Weg.

Umgesetzt (Feature-Typen):

- `StyledFeature` und `StyledFeatureCollection` (ohne R-Tree) aus
  `flutter_mapstyler` nach `mapstyler_style` verschoben.
  Daten-Adapter wie `mapstyler_gdal_adapter` koennen Features ohne
  Flutter-Abhaengigkeit erzeugen. Der R-Tree-Index bleibt als
  Extension in `flutter_mapstyler`; bestehende Imports bleiben
  dank Re-Export kompatibel.

Umgesetzt (Geometrie-Vereinfachung):

- Geometrie-Vereinfachung als Teil des Kernmodells: zweistufiger
  Algorithmus (radiale Vorfilterung + Douglas-Peucker) fuer offene
  Linien sowie ringspezifische Variante fuer Polygone. Arbeitet auf
  `List<(double, double)>` — dem Koordinatenformat von
  `LineStringGeometry` und `PolygonGeometry`. Damit koennen alle
  Consumer (GDAL-Adapter, Renderer, Demo-Loader) die Vereinfachung
  direkt nutzen, ohne ein zusaetzliches Package einzubinden.

### `flutter_mapstyler`

Ziel: Zuverlaessiges und performantes Rendering fuer `mapstyler_style`
auf `flutter_map`.

Geplante Punkte:

- weitere Performance-Arbeit fuer groessere Datenmengen
- Viewport-basierte Optimierungen und Caching weiter absichern
- Ausdrucks- und Symbolizer-Abdeckung schrittweise erweitern
- Tests fuer Rendering-Verhalten und Regressionen ausbauen

### `mapbox4dart`

Ziel: Reines Dart-Package fuer Mapbox GL Style JSON, das ohne
Flutter-Abhaengigkeit als Codec und typisiertes Objektmodell nutzbar
ist.

Umgesetzt:

- `0.1.0` auf pub.dev veroeffentlicht.
- `MapboxStyleCodec` mit `readString`, `readJsonObject`,
  `writeString` und `writeJsonObject`.
- Typisiertes Objektmodell fuer `MapboxStyle`, `MapboxLayer` und
  `MapboxSource`.
- Unknown-Field-Preservation fuer verlustarme Roundtrips.
- Forward-kompatibles Handling unbekannter Layer- und Source-Typen.
- Farbnormalisierung fuer Hex, RGB(A), HSL(A) und CSS-Farbnamen.
- Version-8-Validierung fuer Mapbox-Style-Dokumente.

Geplante Punkte:

- Mapbox-Expression-Abdeckung schrittweise erweitern.
- Validierung fuer haeufige Style-Fehler ausbauen.
- Roundtrip-Tests mit groesseren realen Style-Beispielen ergaenzen.

### `qml4dart`

Ziel: Reines Dart-Package fuer QGIS-QML-Layer-Style-Dateien, das ohne
Flutter- oder QGIS-Laufzeit als Codec und typisiertes Objektmodell
nutzbar ist.

Umgesetzt:

- `0.1.0` auf pub.dev veroeffentlicht.
- Objektmodell fuer `QmlDocument`, `QmlRenderer`, `QmlSymbol`,
  `QmlSymbolLayer`, `QmlRule`, `QmlCategory` und `QmlRange`.
- `Qml4DartCodec` mit `parseString`, `parseFile`, `encodeString` und
  `encodeFile`.
- Reader fuer `singleSymbol`, `categorizedSymbol`,
  `graduatedSymbol` und `RuleRenderer` inklusive verschachtelter
  Regeln.
- Writer fuer alle Renderer-Typen mit QGIS-importierbarem XML im
  neuen `Option`-Format.
- Unterstuetzung fuer neues `Option type="Map"`-Format und altes
  `<prop k v>`-Format.
- Symbol-Layer fuer SimpleMarker, SvgMarker, SimpleLine, SimpleFill
  und RasterFill.
- Scale Visibility auf Dokument- und Regel-Ebene.
- Tests fuer Modell, Renderer, Symbol-Layer, Fehlerfaelle,
  Roundtrips und File-I/O mit QML-Fixtures.

Geplante Punkte:

- Weitere QGIS-Symbol-Layer und Renderer-Sonderfaelle schrittweise
  abdecken.
- Parser-Warnings fuer nicht unterstuetzte QML-Details weiter
  verfeinern.
- Roundtrip-Tests mit realen QGIS-QML-Dateien ausbauen.

### Adapter-Packages

Betroffene Packages:

- `mapstyler_sld_adapter`
- `mapstyler_qml_adapter` (auf Basis von `qml4dart`)
- `mapstyler_mapbox_adapter` (auf Basis von `mapbox4dart`)

Ziel: Robuste Roundtrips zwischen externen Formaten und dem gemeinsamen
Kernmodell.

Umgesetzt (`mapstyler_sld_adapter`):

- `SldStyleParser` fuer SLD-XML nach `mapstyler_style`.
- SLD-Hierarchie wird in flache mapstyler-Regeln transformiert.
- Read/Write-Abdeckung fuer Point/Mark, Icon, Line, Fill, Text und
  Raster-Symbolizer.
- OGC-Filter fuer Vergleichs-, logische, raeumliche und Distanz-
  Operatoren.
- GML-Geometrie-Mapping fuer Point, LineString, Polygon und Envelope.
- Farbkonvertierung zwischen ARGB und `#rrggbb` inklusive Opacity.
- Breite Roundtrip- und Coverage-Tests fuer Symbolizer, Filter,
  Expressions, Geometrien und Raster-Konfiguration.

Umgesetzt (`mapstyler_qml_adapter`):

- `QmlStyleParser` fuer QGIS-QML-XML nach `mapstyler_style` und zurueck.
- Read-Abdeckung fuer `singleSymbol`, `categorizedSymbol`,
  `graduatedSymbol` und `RuleRenderer` inklusive verschachtelter Regeln.
- Write-Abdeckung mit automatischer Renderer-Auswahl.
- Symbol-Layer fuer SimpleFill, SimpleLine, SimpleMarker, SvgMarker
  und RasterFill.
- Filter- und Scale-Visibility-Konvertierung in beide Richtungen.
- QGIS-Farbformat-Konvertierung inklusive Opacity.
- Roundtrip-Tests fuer Lesen, Schreiben, Filter, Multi-Layer-Symbole
  und Parser-API.

Umgesetzt (`mapstyler_mapbox_adapter`):

- `MapboxStyleAdapter` fuer Mapbox GL Style JSON nach
  `mapstyler_style` und zurueck.
- Nutzung von `mapbox4dart` als JSON-Codec und Objektmodell.
- Read-Abdeckung fuer Fill, Line, Circle, Symbol und Raster-Layer.
- Write-Abdeckung fuer die unterstuetzten mapstyler-Symbolizer.
- Expression-MVP: `get`, `literal`, `interpolate`, `step`, `case`,
  `match`, `concat` und `zoom`.
- Filter-MVP inklusive Vergleichs-, Kombinations-, Negations-,
  `has`/`!has`- und `in`/`!in`-Operatoren.
- Web-Mercator-Konvertierung zwischen Zoom und `ScaleDenominator`.
- Warnings fuer nicht unterstuetzte Mapbox-Layer-Typen.

Geplante Punkte:

- Publish-Freigabe fuer die Adapter vorbereiten (`publish_to: none`
  entfernen), sobald die jeweilige API stabil ist.
- Bei `mapstyler_qml_adapter` Version und Changelog vor Release
  synchronisieren (`pubspec.yaml` steht auf `0.1.0`,
  `CHANGELOG.md` fuehrt bereits `0.2.0`).
- `mapstyler_mapbox_adapter` von lokalen `path`-Dependencies auf
  veroeffentlichte Versionen von `mapbox4dart` und `mapstyler_style`
  umstellen, bevor das Package selbst publiziert wird.
- Parser- und Writer-Abdeckung fuer formattypische Sonderfaelle weiter
  ausbauen.
- Verlustarme Roundtrips verbessern und bewusst nicht abbildbare
  Formatdetails als Warnings oder Dokumentation erfassen.
- Unterschiede zwischen Kernmodell und Zielformat sauber dokumentieren.

### `mapstyler_gdal_adapter`

Ziel: Vektordaten aus GDAL-/OGR-unterstuetzten Formaten in
`StyledFeatureCollection` laden, vereinfachen und Flutter-frei
bereitstellen.

Umgesetzt:

- Synchrone und isolate-basierte asynchrone Lade-APIs:
  `loadVectorFileSync`, `loadVectorFile`, `loadVectorFileMultiScaleSync`
  und `loadVectorFileMultiScale`.
- Layer-Auswahl per Index oder Name.
- OGR-seitige Spatial- und Attribut-Filter, damit nur passende
  Features die FFI-Grenze ueberqueren.
- Geometrie-Mapping fuer Point, LineString, Polygon sowie
  MultiPoint, MultiLineString und MultiPolygon.
- Nicht konvertierbare oder leere Geometrien werden ueber
  `LoadVectorResult.warnings` gemeldet statt Exceptions zu werfen.
- Geometrie-Vereinfachung aus `mapstyler_style` waehrend der
  Feature-Iteration, inklusive nativer Toleranz und
  meterbasierter Toleranz fuer EPSG:4326.
- Multi-Scale-Laden mit mehreren Vereinfachungsstufen in einem
  Iterationsdurchlauf.
- Layer-Metadaten-Inspektion ueber `inspectVectorFileSync` und
  `inspectVectorFile`.
- Tests fuer GeoJSON-Fixtures, Filter, Vereinfachung, Multi-Scale,
  Layer-Inspektion und Geometrie-Konvertierung.

Geplante Punkte:

- README und CHANGELOG fuer ein spaeteres Package-Release ergaenzen.
- Publish-Freigabe vorbereiten (`publish_to: none` entfernen), sobald
  die API fuer `0.1.0` stabil ist.
- Testabdeckung fuer Shapefile und GeoPackage neben GeoJSON ergaenzen.
- CRS- und Toleranzverhalten fuer weitere geographische und projizierte
  Koordinatensysteme absichern.
- Fehler- und Ressourcenverhalten bei defekten Dateien und sehr grossen
  Layern testen.

### `flutter_mapstyler_editor`

Ziel: Ein eigenstaendiges UI-Package fuer die visuelle Bearbeitung von
`Style`-Objekten.

Geplante Punkte:

- Prototyp aus der Demo-App in ein eigenes Package ueberfuehren
- Editoren fuer zentrale Symbolizer-Typen bereitstellen
- klares Verhalten fuer `LiteralExpression`, `FunctionExpression` und
  `null`-Werte definieren
- spaeter Regel-, Filter- und Symbolizer-Verwaltung erweitern

Abhaengigkeit zum Kernmodell:

- `copyWith()` ist seit der Kernmodell-Erweiterung verfuegbar und
  reduziert den Implementierungs- und Wartungsaufwand erheblich

## Nicht-Ziel der Roadmap

Diese Roadmap bedeutet nicht:

- dass alle Punkte vor dem naechsten Release umgesetzt werden muessen
- dass Editor, Rendering und Adapter gleichzeitig denselben Reifegrad
  erreichen muessen
- dass das Kernmodell kurzfristig formatgetrieben aufgeweicht wird

## Verwandte Dokumente

- [architecture.md](architecture.md)
- [mapstyler.md](mapstyler.md)
- [flutter_mapstyler.md](flutter_mapstyler.md)
- [flutter_mapstyler_editor.md](flutter_mapstyler_editor.md)
- [todos.md](todos.md)
