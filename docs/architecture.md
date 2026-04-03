# mapstyler Architektur

Diese Datei beschreibt die Architektur des `mapstyler`-Workspaces auf
Repository-Ebene: welche Schichten es gibt, welche Verantwortung jedes
Package trägt und wie Styles zwischen Formaten, Kernmodell und Rendering
fließen.

## Zielbild

`mapstyler` ist als modulares Dart-Ökosystem aufgebaut. Das Repository
trennt bewusst zwischen:

- formatnahen Codecs und Objektmodellen
- Adaptern zum gemeinsamen Kernmodell
- dem zentralen, formatunabhängigen Style-Typsystem
- dem Rendering in Flutter

Dadurch bleiben Parser, Konverter und Renderer unabhängig voneinander.
Ein neues Format kann ergänzt werden, ohne den Kern oder bestehende
Adapter grundlegend umzubauen.

## Schichtenmodell

Die folgende Darstellung zeigt die **interne Verarbeitungsschichtung** im
Workspace. Die formatnahen Codecs und Objektmodelle sind dabei nicht
automatisch Teil der Public API der Adapter; sie können intern genutzt
werden, während die öffentlichen Adapter-Schnittstellen weiterhin
einfachere Verträge wie `String -> Style` oder `Style -> String`
anbieten.

```text
Externe Formate
  SLD XML
  Mapbox GL Style JSON
  QGIS QML
        │
        ▼
Format-Codecs / Objektmodelle
  flutter_map_sld
  mapbox4dart
  qml4dart
        │
        ▼
Adapter auf das gemeinsame Kernmodell
  mapstyler_sld_adapter
  mapstyler_mapbox_adapter
  mapstyler_qml_adapter
        │
        ▼
Kernmodell
  mapstyler_style
        │
        ├── GeoStyler-JSON lesen/schreiben
        └── Regeln, Filter, Symbolizer, Expressions, Geometrien
        │
        ▼
Rendering
  flutter_mapstyler
        │
        ▼
  flutter_map
```

## Architekturprinzipien

### 1. Ein gemeinsames Kernmodell

`mapstyler_style` ist das Zentrum des Systems. Alle formatabhängigen
Bausteine konvertieren in dieses Modell oder aus diesem Modell heraus.
Der Kern ist absichtlich unabhängig von Flutter und von konkreten
Style-Formaten.

### 2. Formatlogik bleibt an den Rändern

Mapbox-, QML- oder SLD-spezifische Besonderheiten sollen nicht in den
Kern diffundieren. Sie gehören in:

- ein formatnahes Objektmodell wie `mapbox4dart` oder `qml4dart`
- oder in einen dedizierten Adapter wie `mapstyler_mapbox_adapter`

So bleibt `mapstyler_style` stabil und wiederverwendbar.

### 3. Pure Dart als Standard

Alle Pakete außer `flutter_mapstyler` sind als pure Dart ausgelegt. Das
ermöglicht Nutzung in:

- Flutter-Apps
- CLI-Tools
- Server-Anwendungen
- Konvertierungs-Pipelines ohne UI

### 4. Rendering ist eine eigene Schicht

`flutter_mapstyler` arbeitet nur mit `mapstyler_style`-Typen. Es kennt
keine Quellformate direkt. Das Rendering hängt damit nicht daran, ob ein
Style ursprünglich aus SLD, Mapbox oder QML stammt.

## Packages und Zuständigkeiten

| Package | Rolle | Verantwortung |
|---|---|---|
| `mapstyler_style` | Kern | Formatunabhängige Typen für `Style`, `Rule`, `Symbolizer`, `Filter`, `Expression`, `Geometry`, `StyledFeature`/`StyledFeatureCollection` sowie GeoStyler-JSON-Serialisierung |
| `mapbox4dart` | Formatmodell | Pure-Dart-Codec und Objektmodell für Mapbox-GL-Style-JSON; wird typischerweise intern von Mapbox-Adaptern genutzt |
| `qml4dart` | Formatmodell | Pure-Dart-Codec und Objektmodell für QGIS-QML; wird typischerweise intern von QML-Adaptern genutzt |
| `mapstyler_mapbox_adapter` | Adapter | Öffentliche Konvertierungs-API zwischen Mapbox-JSON und `mapstyler_style`; kann intern `mapbox4dart` verwenden |
| `mapstyler_qml_adapter` | Adapter | Öffentliche Konvertierungs-API zwischen QML/XML und `mapstyler_style`; kann intern `qml4dart` verwenden |
| `mapstyler_sld_adapter` | Adapter | Öffentliche Konvertierungs-API zwischen SLD/XML und `mapstyler_style`; kann intern `flutter_map_sld` nutzen |
| `flutter_mapstyler` | Rendering | Auswertung von Regeln, Filtern und Expressions für `flutter_map` |

## Abhängigkeitsregeln

Die Richtung der Abhängigkeiten ist absichtlich eingeschränkt:

- `mapstyler_style` darf keine Adapter oder Renderer kennen.
- Formatmodelle wie `mapbox4dart` und `qml4dart` bleiben unabhängig vom
  mapstyler-Kern.
- Adapter dürfen vom jeweiligen Formatmodell und von
  `mapstyler_style` abhängen.
- `flutter_mapstyler` hängt von `mapstyler_style` und Flutter ab, aber
  nicht von Formatpaketen.

Vereinfacht:

```text
mapbox4dart ───────────────┐
                           ├──→ mapstyler_mapbox_adapter ──┐
qml4dart ──────────────────┘                              │
                                                          │
flutter_map_sld ─→ mapstyler_sld_adapter ─────────────────┤
                                                          ▼
                                                   mapstyler_style
                                                          │
                                                          ▼
                                                   flutter_mapstyler
```

## Datenfluss

### Format nach Kernmodell

Beispiel Mapbox:

1. Die öffentliche API von `mapstyler_mapbox_adapter` nimmt Mapbox-GL-
   Style-JSON entgegen.
2. Intern kann `mapbox4dart` das JSON in ein formatnahes Modell lesen.
3. `mapstyler_mapbox_adapter` mappt Layer, Sources, Filter und Paint-
   Eigenschaften auf `mapstyler_style`.
4. Das Ergebnis ist ein `Style`, das formatunabhängig weiterverarbeitet
   werden kann.

Beispiel QML:

1. Die öffentliche API von `mapstyler_qml_adapter` nimmt QGIS-QML/XML
   entgegen.
2. Intern kann `qml4dart` die Datei in ein QML-Modell lesen.
3. `mapstyler_qml_adapter` übersetzt Renderer, Regeln und Symbol-Layer
   in `mapstyler_style`.

Beispiel SLD:

1. Die öffentliche API von `mapstyler_sld_adapter` nimmt SLD/XML
   entgegen.
2. Intern kann `flutter_map_sld` SLD samt GML-bezogenen Typen parsen.
3. `mapstyler_sld_adapter` mappt diese Strukturen in das Kernmodell.

### Kernmodell nach Format

Die Gegenrichtung funktioniert analog:

1. Ein `Style` liegt als `mapstyler_style`-Objekt vor.
2. Ein Adapter übersetzt das Kernmodell in das Zielformat.
3. Intern kann dabei ein formatnahes Objektmodell aufgebaut werden.
4. Der zugehörige Codec serialisiert das Ergebnis.

### Kernmodell nach Rendering

1. `flutter_mapstyler` erhält ein `Style` und Features.
2. Regeln werden nach Filter und Maßstab ausgewählt.
3. Expressions werden gegen Feature-Properties ausgewertet.
4. Symbolizer werden in `flutter_map`-Layer bzw. Widgets übersetzt.

## Warum diese Trennung sinnvoll ist

- Neue Formate können als zusätzliche Adapter ergänzt werden.
- Tests bleiben fokussiert: Format-Codec, Mapping und Rendering können
  getrennt geprüft werden.
- Der Kern bleibt klein und stabil.
- Flutter ist nur dort eingebunden, wo tatsächlich gerendert wird.
- GeoStyler-JSON kann als neutrales Austauschformat dienen.

## Workspace-Sicht

Der Repository-Root definiert einen Dart-Workspace mit diesen Modulen:

- `mapstyler_style`
- `mapbox4dart`
- `mapstyler_mapbox_adapter`
- `mapstyler_sld_adapter`
- `qml4dart`
- `mapstyler_qml_adapter`
- `flutter_mapstyler`

Der Workspace bündelt Entwicklung, Tests und Releases, ohne die
fachliche Trennung zwischen Kern, Formaten, Adaptern und Rendering
aufzugeben.

## Nicht-Ziele

Diese Architektur verfolgt bewusst nicht das Ziel,

- formatspezifische Details im Kernmodell 1:1 abzubilden
- Rendering und Parsing im selben Package zu vermischen
- Flutter zur Pflichtabhängigkeit für Konvertierungslogik zu machen

## Verwandte Dokumente

- [mapstyler.md](mapstyler.md)
- [flutter_mapstyler.md](flutter_mapstyler.md)
- [MAPBOX.md](MAPBOX.md)
- [QML.md](QML.md)
