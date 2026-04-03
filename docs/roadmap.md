# mapstyler Roadmap

Diese Datei beschreibt die geplante Weiterentwicklung des
`mapstyler`-Workspaces auf hoher Ebene. Sie ist bewusst als
Zielrichtung formuliert, nicht als verbindlicher Release-Plan mit
festen Terminen.

## Zielbild

`mapstyler` soll ein zusammenhaengendes Dart-Oekosystem fuer
formatunabhaengige Kartenstile werden:

- `mapstyler_style` als stabiles Kernmodell
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

### `flutter_mapstyler`

Ziel: Zuverlaessiges und performantes Rendering fuer `mapstyler_style`
auf `flutter_map`.

Geplante Punkte:

- weitere Performance-Arbeit fuer groessere Datenmengen
- Viewport-basierte Optimierungen und Caching weiter absichern
- Ausdrucks- und Symbolizer-Abdeckung schrittweise erweitern
- Tests fuer Rendering-Verhalten und Regressionen ausbauen

### Adapter-Packages

Betroffene Packages:

- `mapstyler_sld_adapter`
- `mapstyler_qml_adapter`
- `mapstyler_mapbox_adapter`

Ziel: Robuste Roundtrips zwischen externen Formaten und dem gemeinsamen
Kernmodell.

Geplante Punkte:

- Parser- und Writer-Abdeckung erweitern
- verlustarme Roundtrips verbessern
- formattypische Sonderfaelle explizit testen
- Unterschiede zwischen Kernmodell und Zielformat sauber dokumentieren

### `mapstyler_gdal_adapter`

Ziel: Vektordaten aus GDAL-/OGR-unterstuetzten Formaten in
`StyledFeatureCollection` laden, vereinfachen und Flutter-frei
bereitstellen.

Geplante Punkte:

- asynchrone und synchrone Lade-APIs fuer Datei- und Layer-basierte
  Zugriffe bereitstellen
- Geometrie-Mapping fuer Point, LineString, Polygon und Multi-Varianten
  robust abdecken
- zweistufige Linien-Vereinfachung und konservative Ring-
  Vereinfachung fuer Polygone implementieren
- Layer-Metadaten-Inspektion fuer Dateiauswahl und Tooling anbieten
- Lese- und Konvertierungstests fuer Shapefile, GeoJSON und GeoPackage
  aufbauen

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
