# flutter_mapstyler_editor

Package-Entwurf fuer einen visuellen Style-Editor auf Basis von
`mapstyler_style` und `flutter_mapstyler`.

Aktueller Prototyp:
`demo/mapstyler_demo/lib/style_editor.dart`

Dieses Dokument beschreibt den **Zielzustand** des kuenftigen Packages.
Der Demo-Prototyp zeigt den grundsaetzlichen Datenfluss, kann aber in
Details noch vom hier beschriebenen API- und Implementierungsziel
abweichen.

## Rolle im Workspace

```text
Format-Adapter
  -> mapstyler_style        (Datenmodell, immutable)
  -> flutter_mapstyler       (Rendering)
  -> flutter_mapstyler_editor (Bearbeitung)  <-- neu
  -> flutter_map
```

Der Editor arbeitet auf demselben `Style`-Modell wie der Renderer.
Aenderungen erzeugen neue immutable `Style`-Instanzen, die direkt
an `StyleRenderer.renderStyle()` uebergeben werden koennen.

## Update-Modell

Der Editor behandelt `mapstyler_style` funktional:

- Aenderungen erzeugen neue `Style`-Instanzen statt bestehende Objekte
  in-place zu veraendern
- `Style.rules` und `Rule.symbolizers` sind per `List.unmodifiable`
  immutable abgesichert
- `copyWith()` auf `Style`, `Rule`, `ScaleDenominator` und konkreten
  `Symbolizer`-Klassen reduziert Boilerplate deutlich
- `Expression` und `Filter` werden bei Bedarf weiterhin gezielt neu
  konstruiert

### Update-Muster mit `copyWith()`

```dart
// Farbe eines FillSymbolizers aendern:
void updateFillColor(Style style, int ruleIdx, int symIdx, String hex) {
  final rule = style.rules[ruleIdx];
  final fill = rule.symbolizers[symIdx] as FillSymbolizer;

  final newSymbolizer = fill.copyWith(
    color: LiteralExpression(hex),
  );

  final newSymbolizers = [...rule.symbolizers];
  newSymbolizers[symIdx] = newSymbolizer;

  final newRule = rule.copyWith(
    symbolizers: newSymbolizers,
  );

  final newRules = [...style.rules];
  newRules[ruleIdx] = newRule;

  final newStyle = style.copyWith(rules: newRules);
  // -> onChanged(newStyle)
}
```

Dieses Muster bleibt typsicher, ist aber deutlich kompakter als die
vollstaendige manuelle Rekonstruktion aller betroffenen Felder.

Der aktuelle Demo-Prototyp nutzt dieses `copyWith()`-basierte
Update-Muster bereits durchgaengig. Das eigenstaendige Package sollte
denselben Ansatz beibehalten.

## Prototyp-Architektur (Demo-App)

Der aktuelle Prototyp in der Demo-App besteht aus:

```text
StyleEditor                    (oeffentlich)
  |
  +-- _RuleCard                (pro Regel, aufklappbar)
  |     |
  |     +-- _SymbolizerEditor  (Dispatch nach Typ)
  |           |
  |           +-- _FillEditor  (Farbe + Opazitaet)
  |           +-- _LineEditor  (Farbe + Breite)
  |           +-- _MarkEditor  (Farbe + Radius)
  |
  +-- _ColorRow                (Farbfeld + Hex-Anzeige)
  +-- _SliderRow               (Label + Slider + Wert)
  +-- _ColorPickerDialog       (25-Farben-Palette)
```

### Oeffentliche API (Prototyp)

```dart
class StyleEditor extends StatelessWidget {
  const StyleEditor({
    required this.style,
    required this.onChanged,
  });

  final Style style;
  final ValueChanged<Style> onChanged;
}
```

Einbindung:

```dart
StyleEditor(
  style: currentStyle,
  onChanged: (newStyle) {
    setState(() => _editedStyle = newStyle);
    // StyleRenderer rendert automatisch mit dem neuen Style
  },
)
```

### Ziel-Datenfluss im Package

```text
Nutzer aendert Slider/Farbe
       |
       v
_FillEditor / _LineEditor / _MarkEditor
  -> erzeugt neuen Symbolizer via copyWith()
       |
       v
_RuleCard._updateSymbolizer()
  -> erzeugt neue Rule via copyWith(symbolizers: ...)
       |
       v
StyleEditor._updateRule()
  -> erzeugt neuen Style via copyWith(rules: ...)
       |
       v
onChanged(newStyle)
  -> setState() in der Host-App
       |
       v
StyleRenderer.renderStyle(style: newStyle, ...)
  -> Karte aktualisiert sich sofort
```

## Expression-Handling

Symbolizer-Werte sind `Expression<T>`, nicht direkte Werte.
Der Editor muss damit umgehen:

| Expression-Typ | Editor-Verhalten |
|---|---|
| `LiteralExpression<String>` | Hex-Wert lesen/schreiben |
| `LiteralExpression<double>` | Slider-Wert lesen/schreiben |
| `FunctionExpression<T>` | Read-only anzeigen (nicht editierbar) |
| `null` | Default-Wert anzeigen, bei Aenderung Literal erzeugen |

Aktueller Stand:

- der Demo-Prototyp nutzt lokale private Helfer fuer die Extraktion von
  Literal-Werten
- fuer das eigenstaendige Package sollte diese Logik mittelfristig in
  `mapstyler_style` selbst liegen, z.B. ueber einen geplanten Getter wie
  `Expression<T>.literalValue`

Aktuelle Helfer im Prototyp:

```dart
String? _literalString(Expression<String>? e) =>
    e is LiteralExpression<String> ? e.value : null;

double? _literalDouble(Expression<double>? e) =>
    e is LiteralExpression<double> ? e.value : null;
```

## Unterstuetzte Symbolizer

| Symbolizer | Editierbare Felder | Controls |
|---|---|---|
| `FillSymbolizer` | `color`, `fillOpacity` | Farbpalette, Slider 0-1 |
| `LineSymbolizer` | `color`, `width` | Farbpalette, Slider 0.5-20 |
| `MarkSymbolizer` | `color`, `radius` | Farbpalette, Slider 2-30 |
| `TextSymbolizer` | -- | Read-only (Typ-Anzeige) |
| `IconSymbolizer` | -- | Read-only (Typ-Anzeige) |
| `RasterSymbolizer` | -- | Read-only (Typ-Anzeige) |

## Farbauswahl

Der Prototyp verwendet eine eingebettete 25-Farben-Palette (kein
externes Package):

```text
+-----+-----+-----+-----+-----+
|E76F51|F4A261|E9C46A|F6BD60|F8961E|
+-----+-----+-----+-----+-----+
|D62828|9B2226|6D597A|C77DFF|5C7CFA|
+-----+-----+-----+-----+-----+
|0B7285|0A9396|94D2BD|6BAA75|2F5233|
+-----+-----+-----+-----+-----+
|264653|1D3557|355070|005F73|102A43|
+-----+-----+-----+-----+-----+
|8ECAE6|FB8500|FFFFFF|B0B0B0|31464B|
+-----+-----+-----+-----+-----+
```

Fuer ein eigenstaendiges Package koennten ergaenzt werden:
- Hex-Eingabefeld fuer beliebige Farben
- HSL-Regler
- Pipette (Farbe aus der Karte aufnehmen)

## Package-Entwurf

```text
flutter_mapstyler_editor/
  lib/
    flutter_mapstyler_editor.dart       <-- barrel export
    src/
      style_editor.dart                 <-- Hauptwidget
      rule_editor.dart                  <-- Regel-Karte
      symbolizer_editors/
        fill_editor.dart
        line_editor.dart
        mark_editor.dart
        text_editor.dart                <-- erweiterbar
        icon_editor.dart                <-- erweiterbar
      controls/
        color_row.dart                  <-- Farbfeld + Label
        slider_row.dart                 <-- Slider + Label
        color_picker_dialog.dart        <-- Palette oder HSL
        color_utils.dart                <-- Hex/HSL-Konvertierung
  test/
    style_editor_test.dart
    rule_editor_test.dart
    color_utils_test.dart
  pubspec.yaml
```

### Abhaengigkeiten

```yaml
dependencies:
  flutter:
    sdk: flutter
  mapstyler_style: ^0.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

Keine Abhaengigkeit auf `flutter_mapstyler` -- der Editor arbeitet
rein auf dem Style-Modell. Das Rendering und die Vorschau bleiben
Sache der Host-App.

## Abgrenzung

| Zustaendigkeit | Package |
|---|---|
| Style-Datenmodell | `mapstyler_style` |
| Style -> flutter_map-Layer | `flutter_mapstyler` |
| **Style visuell bearbeiten** | **`flutter_mapstyler_editor`** |
| Format-Konvertierung | Adapter-Packages |

Der Editor kennt weder Formate noch Rendering. Er nimmt einen `Style`,
zeigt Controls, und liefert einen neuen `Style` zurueck.

## Offene Punkte / Erweiterungen

### MVP

- [ ] `TextSymbolizer`-Editor (mindestens Label-Expression,
  Schriftgroesse, Halo)
- [ ] `IconSymbolizer`-Editor (mindestens Bild-URL, Groesse, Rotation)
- [ ] Regel hinzufuegen / entfernen / umsortieren (Drag & Drop)
- [ ] Symbolizer hinzufuegen / entfernen
- [ ] Hex-Eingabefeld und HSL-Farbregler

#### Loesungsansatz fuer den MVP

**`TextSymbolizer`-Editor**

Loesung:
- eigener `_TextEditor` analog zu `_FillEditor`, `_LineEditor` und
  `_MarkEditor`
- `label` als Sonderfall behandeln: `LiteralExpression<String>` per
  Textfeld editieren, `FunctionExpression<String>` zunaechst read-only
  anzeigen
- `size`, `haloWidth` ueber Slider oder numerische Eingabe
- `color`, `haloColor` ueber dieselben Farb-Controls wie bei Fill/Line

Ziel fuer die erste Version:
- einfache Literal-Labels direkt editierbar
- datengetriebene Label-Expressions sichtbar, aber noch nicht visuell
  modellierbar

**`IconSymbolizer`-Editor**

Loesung:
- eigener `_IconEditor`
- `image` ueber Textfeld bearbeiten
- `size` und `rotate` ueber Slider oder numerische Eingabe
- `opacity` kann in der ersten Version optional direkt mitgezogen
  werden, auch wenn sie nicht zum Minimalumfang gehoert

Ziel fuer die erste Version:
- Literale Bild-URLs oder Asset-Pfade direkt editierbar
- `FunctionExpression<String>` bei `image` zunaechst read-only

**Regel hinzufuegen / entfernen / umsortieren**

Loesung:
- oberhalb der Regelliste einen "Regel hinzufuegen"-Button anbieten
- jede `_RuleCard` bekommt Aktionen fuer Loeschen und Duplizieren
- Umsortieren ueber `ReorderableListView` oder eine gleichwertige
  reorderbare Listenstruktur
- Aenderungen weiter rein ueber neue `rules`-Listen und
  `style.copyWith(rules: ...)` abbilden

Ziel fuer die erste Version:
- neue leere Regel mit Default-Name und leerer Symbolizer-Liste
- Entfernen und Reordering ohne komplexe Validierungslogik

**Symbolizer hinzufuegen / entfernen**

Loesung:
- innerhalb jeder Regel einen "Symbolizer hinzufuegen"-Button
- Typauswahl ueber kleines Dialog- oder Bottom-Sheet:
  `Fill`, `Line`, `Mark`, `Text`, `Icon`
- pro Typ eine kleine Default-Konfiguration erzeugen, damit der neue
  Symbolizer sofort sichtbar und editierbar ist
- Entfernen direkt an jedem Symbolizer-Block anbieten

Ziel fuer die erste Version:
- Erzeugen von brauchbaren Default-Symbolizern statt komplett leerer
  Objekte
- kein komplexer Multi-Select oder verschachteltes Reordering noetig

**Hex-Eingabefeld und HSL-Farbregler**

Loesung:
- `_ColorRow` um freies Hex-Eingabefeld erweitern
- `_ColorPickerDialog` neben der festen Palette um HSL-Slider
  erweitern
- Farbeingaben zentral normalisieren, z.B. immer als `#RRGGBB`
  zurueckgeben
- ungueltige Eingaben lokal validieren und nicht sofort in den Style
  uebernehmen

Ziel fuer die erste Version:
- Palette bleibt als schneller Einstieg erhalten
- Hex und HSL decken den produktiven Bearbeitungsfall ab, ohne ein
  zusaetzliches Package zu erzwingen

### V2

- [ ] Filter-Editor (Regelbedingungen visuell bearbeiten)
- [ ] Undo/Redo (Style-History-Stack)

### Spaeter / ausserhalb des Kern-Editors

- [ ] GeoStyler-JSON-Export des editierten Styles
- [ ] Adapter-Roundtrip: editierten Style als Mapbox/QML/SLD exportieren

## Verwandte Dokumente

- [flutter_mapstyler.md](flutter_mapstyler.md) -- Renderer-API
- [architecture.md](architecture.md) -- Workspace-Architektur
- [mapstyler.md](mapstyler.md) -- Core-Style-Modell
- [roadmap.md](roadmap.md) -- Geplante Kernmodell-Erweiterungen
