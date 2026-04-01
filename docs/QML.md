# QML — Neuimplementierung des QGIS Layer Style Formats

Zielspezifikation für ein neues Dart-Package `qml4dart`, das QGIS-`.qml`-Dateien liest, parst, modelliert und wieder als Datei oder String erzeugt, ohne auf Node.js oder QGIS selbst angewiesen zu sein.

## Ausgangspunkt

QGIS-`QML` ist das native XML-basierte Layer-Style-Format von QGIS. Es ist öffentlich dokumentiert, aber nicht als vollständige normative Spezifikation mit XSD oder RFC-artigem Standard beschrieben. Praktisch ergibt sich das Format aus:

- der offiziellen QGIS-Dokumentation
- echten von QGIS erzeugten `.qml`-Dateien
- dem beobachtbaren Verhalten von QGIS beim Import und Export

Für dieses Vorhaben bedeutet das: Eine Neuimplementierung ist realistisch, sollte aber als kompatibilitätsgetriebene Implementierung verstanden werden, nicht als Umsetzung eines vollständig formalisierten Standards.

## Referenzquellen

Die Implementierung stützt sich auf diese öffentlichen Quellen:

- QGIS-Dokumentation: QML als Layer-Style-Datei
- QGIS-Dokumentation: QGIS File Formats
- Beispieldateien aus QGIS-Projekten und Testdaten
- Optional: Verhalten des GeoStyler-`geostyler-qgis-parser` als zusätzliche Vergleichsquelle

Wichtig für die Lizenzstrategie:

- Die Neuimplementierung soll als Clean-Room-Implementierung erfolgen.
- QGIS-Quellcode dient höchstens zum Verständnis des Verhaltens, nicht als Copy-Paste-Vorlage.
- Wenn stattdessen der TypeScript-Parser portiert wird, gilt die BSD-2-Clause des GeoStyler-Projekts.

## Ziel des Packages

`qml4dart` konvertiert zwischen:

```text
QGIS QML XML  ⇄  QmlDocument
```

Konkret:

- QML aus `String` lesen
- QML-Dateien lesen
- QML als Objektmodell bearbeiten
- QML als `String` erzeugen
- QML-Dateien schreiben
- Der Parser ist pure Dart
- Keine Flutter-Abhängigkeit
- Keine QGIS-Laufzeit

Damit ist das Package bewusst mehr als ein Parser. Es ist ein QML-Codec plus Objektmodell.

## Grundannahmen zum Format

Für eine erste Implementierung sollten diese Annahmen gelten:

- `.qml` ist XML und kann mit dem Dart-Package `xml` verarbeitet werden.
- Das Wurzelelement enthält Renderer-, Symbol- und Metadaten-Strukturen.
- Die eigentliche Styling-Logik sitzt primär in Renderer-Typen wie:
  - `singleSymbol`
  - `categorizedSymbol`
  - `graduatedSymbol`
  - `RuleRenderer`
- Symbole bestehen aus Symbol-Layern wie:
  - Simple Marker
  - Simple Line
  - Simple Fill
  - SVG Marker
  - Raster/Image Fill
- Viele Werte liegen als String-Properties in XML-Attributen oder `prop`-Elementen vor und müssen typisiert werden.

## Package-Ausrichtung

`qml4dart` ist bewusst ein eigenständiges QML-Package mit nativem Objektmodell für QGIS-Styles.

Nicht Ziel dieses Packages:

- Konvertierung nach `mapstyler_style`
- Abbildung auf andere Styling-Modelle
- Formatübergreifende Normalisierung

Falls eine Integration in `mapstyler` benötigt wird, sollte sie in einem separaten Package erfolgen:

```text
qml4dart  →  mapstyler_qml_adapter  →  mapstyler_style
```

Das trennt die Verantwortlichkeiten sauber:

- `qml4dart` kümmert sich um QML lesen, modellieren und schreiben
- `mapstyler_qml_adapter` kümmert sich um die semantische Abbildung nach `mapstyler_style`

## Minimal Viable Package

Phase 1 sollte bewusst klein und robust sein. Unterstützt werden:

1. Renderer:
   - `singleSymbol`
   - `categorizedSymbol`
   - `graduatedSymbol`
   - `RuleRenderer` mit einfachen Regeln
2. Geometrietypen:
   - Punkt
   - Linie
   - Polygon
3. Symbol-Layer:
   - Simple Marker
   - Simple Line
   - Simple Fill
   - SVG Marker
4. Eigenschaften:
   - Farbe
   - Opacity
   - Linienbreite
   - Dash Pattern
   - Join/Cap
   - Marker-Größe
   - Outline/Füllung
   - Rotation, soweit direkt numerisch
5. Regeln:
   - Attributgleichheit
   - Wertebereiche
   - Sichtbarkeit nach Maßstab

Phase 1 sollte noch nicht versuchen, jede exotische QGIS-Stiloption mitzunehmen.

## Bewusste Nicht-Ziele für Phase 1

Diese Bereiche sollten zunächst ausgespart oder nur read-only toleriert werden:

- vollständiges Labeling
- Diagramme
- Geometry Generator
- datengetriebene Expressions in voller QGIS-Syntax
- Blend Modes und komplexe Painter Effects
- 3D-Renderer
- Raster-spezifische Spezialfälle
- alle Vendor-spezifischen oder versionsabhängigen Metadaten
- verlustfreies Round-Trip für unbekannte XML-Teile

Stattdessen gilt:

- Unbekannte Teile werden ignoriert oder als Warning gemeldet.
- Unterstützte Teile werden stabil und testbar abgebildet.

## Package-Architektur

Empfohlene interne Struktur:

```text
qml4dart
├── src/model/
│   ├── qml_renderer.dart
│   ├── qml_symbol.dart
│   ├── qml_symbol_layer.dart
│   └── qml_rule.dart
├── src/xml/
│   ├── xml_reader.dart
│   ├── xml_writer.dart
│   └── xml_helpers.dart
├── src/read/
│   ├── read_renderer.dart
│   ├── read_symbol.dart
│   └── read_rule.dart
├── src/write/
│   ├── write_renderer.dart
│   ├── write_symbol.dart
│   └── write_rule.dart
└── qml4dart.dart
```

Empfehlung:

- Zuerst ein kleines internes QML-Zwischenmodell bauen.
- Danach QML-Reader und QML-Writer auf dieses Modell aufsetzen.
- XML-Lesen/Schreiben strikt vom semantischen Mapping trennen.

Das vermeidet, dass DOM-Zugriffe und Style-Logik untrennbar vermischt werden.

## API-Zielbild

Sinnvolle öffentliche API:

```dart
abstract class QmlCodec {
  QmlDocument parseString(String xml);
  QmlDocument parseFile(String path);

  String encodeString(QmlDocument document);
  void encodeFile(String path, QmlDocument document);
}
```

Die Kernidee:

- `qml4dart` besitzt zuerst eine eigene QML-Domäne
- Serialisierung und Deserialisierung arbeiten auf diesem Modell
- andere Integrationen gehören in separate Adapter-Packages

## Lesestrategie

Beim Lesen:

1. XML parsen
2. Wurzelelement validieren
3. Renderer-Typ bestimmen
4. Symbole und Regeln extrahieren
5. QGIS-Werte typisieren
6. in `QmlDocument` mappen
7. Warnings für nicht unterstützte Konstrukte sammeln

Mit Result-Typen analog zur restlichen Architektur:

- `Success(document, warnings)`
- `Failure(message, cause)`

## Schreibstrategie

Beim Schreiben sollte nicht versucht werden, beliebiges historisches QGIS-QML exakt zu reproduzieren. Ziel ist stattdessen:

- syntaktisch gültiges XML
- von QGIS importierbar
- semantisch äquivalente Darstellung der unterstützten Features

Das Schreibziel ist also:

```text
QmlDocument → kanonisches, einfaches QML
```

Nicht Ziel:

- bytegenauer Round-Trip
- Erhalt unbekannter Originalattribute
- Reproduktion jeder QGIS-Versionseigenheit

## Kompatibilitätsstrategie

Die richtige Qualitätsmetrik ist Verhaltenskompatibilität.

Testarten:

1. Fixture-Tests
   - echte `.qml`-Dateien
   - erwartetes `QmlDocument`
2. Snapshot-Tests
   - `QmlDocument` → QML
   - XML-Struktur auf stabile Kernfelder prüfen
3. Import-Tests gegen QGIS
   - erzeugtes QML in QGIS laden
   - Renderer und Symbolik visuell oder strukturell prüfen
4. Round-Trip-Tests
   - `QML → QmlDocument → QML`
   - `QmlDocument → QML → QmlDocument`
5. Schreibtests auf Datei-Ebene
   - `encodeFile()` erzeugt importierbare `.qml`-Dateien

Wichtig:

- Round-Trip muss semantisch stabil sein, nicht textuell identisch.

## Priorisierte Implementierungsreihenfolge

1. XML-Helfer und Property-Reader
2. `singleSymbol` lesen
3. Simple Marker / Line / Fill lesen
4. `QmlDocument` aufbauen
5. `categorizedSymbol` lesen
6. `graduatedSymbol` lesen
7. `RuleRenderer` lesen
8. QML schreiben für die bereits unterstützten Typen
9. SVG Marker
10. Maßstabsgrenzen
11. robuste Warning- und Error-Ausgabe
12. Kompatibilitätstests mit echten QGIS-Files

## Technische Detailentscheidungen

Für die erste Version sollten diese Entscheidungen fest sein:

- XML-Verarbeitung mit `package:xml`
- kein Streaming-Parser, DOM ist ausreichend
- Farben intern normalisiert, z. B. als Hex plus Opacity
- numerische Werte tolerant parsen, da QGIS oft Strings schreibt
- unbekannte `prop`-Keys nicht als Fehler behandeln
- QGIS-Expressions zunächst nicht voll auswerten, sondern nur einfache Fälle mappen

## Risiken

Die größten Risiken einer Neuimplementierung sind:

- QGIS speichert viele Details in lose strukturierten Property-Sammlungen
- verschiedene QGIS-Versionen schreiben leicht unterschiedliche XML-Strukturen
- manche Renderer- oder Symbol-Layer-Typen sind schlecht dokumentiert
- komplexe Expressions und data-defined properties sind schnell ein eigenes Teilprojekt

Deshalb ist der richtige Schnitt für Version 1:

- solide Unterstützung der häufigsten Vektor-Stile
- klare Warnings statt halbfertiger Magie
- späterer Ausbau anhand echter Testdateien

## Abgrenzung zu Adapter-Packages

Für dieses Repo ist `qml4dart` sinnvoll, wenn das Ziel ist:

- pure Dart
- ein eigenständiges QML-Modell statt nur Formatkonvertierung
- saubere Kontrolle über das Datenmodell
- kleine, verständliche Abhängigkeiten
- schrittweiser Ausbau entlang realer Anwendungsfälle

Wenn später eine `mapstyler`-Anbindung nötig ist, sollte sie separat gebaut werden:

```text
qml4dart
mapstyler_qml_adapter
```

Die pragmatische Reihenfolge wäre daher:

1. `qml4dart` für den kleinen, klaren Kern implementieren
2. QGIS-Kompatibilität über echte Fixtures absichern
3. erst danach bei Bedarf `mapstyler_qml_adapter` als separates Package bauen
