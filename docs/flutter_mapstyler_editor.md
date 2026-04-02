# flutter_mapstyler_editor

Package-Entwurf fuer einen visuellen Style-Editor auf Basis von
`mapstyler_style` und `flutter_mapstyler`.

Aktueller Prototyp:
`demo/mapstyler_demo/lib/style_editor.dart`

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

## Herausforderung: Immutables Style-Modell

Das gesamte `mapstyler_style`-Modell ist immutable:
- `Style`, `Rule`, `Symbolizer`, `Filter`, `Expression` sind `final class`
  mit `const`-Konstruktoren
- Es gibt **keine `copyWith()`-Methoden**
- Jede Aenderung erfordert das Neuerstellen der gesamten Kette:
  `Style` -> `Rules`-Liste -> `Symbolizer`-Liste

### Rekonstruktions-Muster

```dart
// Farbe eines FillSymbolizers aendern:
void updateFillColor(Style style, int ruleIdx, int symIdx, String hex) {
  final rule = style.rules[ruleIdx];
  final fill = rule.symbolizers[symIdx] as FillSymbolizer;

  final newSymbolizer = FillSymbolizer(
    color: LiteralExpression(hex),      // <-- geaendert
    opacity: fill.opacity,               // alle anderen Felder
    fillOpacity: fill.fillOpacity,       // manuell uebertragen
    outlineColor: fill.outlineColor,
    outlineWidth: fill.outlineWidth,
  );

  final newSymbolizers = [...rule.symbolizers];
  newSymbolizers[symIdx] = newSymbolizer;

  final newRule = Rule(
    name: rule.name,
    filter: rule.filter,
    symbolizers: newSymbolizers,
    scaleDenominator: rule.scaleDenominator,
  );

  final newRules = [...style.rules];
  newRules[ruleIdx] = newRule;

  final newStyle = Style(name: style.name, rules: newRules);
  // -> onChanged(newStyle)
}
```

Dieses Muster ist verbose, aber korrekt und vollstaendig typsicher.
Ein spaeters `copyWith()` auf den Modellklassen wuerde den Editor-Code
deutlich vereinfachen.

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

### Datenfluss

```text
Nutzer aendert Slider/Farbe
       |
       v
_FillEditor / _LineEditor / _MarkEditor
  -> erzeugt neuen Symbolizer (immutable)
       |
       v
_RuleCard._updateSymbolizer()
  -> erzeugt neue Rule mit aktualisierter Symbolizer-Liste
       |
       v
StyleEditor._updateRule()
  -> erzeugt neuen Style mit aktualisierter Rule-Liste
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

Helfer-Funktionen:

```dart
String? literalString(Expression<String>? e) =>
    e is LiteralExpression<String> ? e.value : null;

double? literalDouble(Expression<double>? e) =>
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
|E76F5|F4A26|E9C46|F6BD6|F8961|
+-----+-----+-----+-----+-----+
|D6282|9B222|6D597|C77DF|5C7CF|
+-----+-----+-----+-----+-----+
|0B728|0A939|94D2B|6BAA7|2F523|
+-----+-----+-----+-----+-----+
|26465|1D355|35507|005F7|102A4|
+-----+-----+-----+-----+-----+
|8ECAE|FB850|FFFFF|B0B0B|31464|
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
      expression_helpers.dart           <-- literal-Extraktion
  test/
    style_editor_test.dart
    rule_editor_test.dart
    expression_helpers_test.dart
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

- [ ] `copyWith()` auf `Style`, `Rule`, `Symbolizer` in `mapstyler_style`
  wuerde den Editor-Code massiv vereinfachen
- [ ] `TextSymbolizer`-Editor (Label-Expression, Schriftgroesse, Halo)
- [ ] `IconSymbolizer`-Editor (Bild-URL, Groesse, Rotation)
- [ ] Filter-Editor (Regelbedingungen visuell bearbeiten)
- [ ] Regel hinzufuegen / entfernen / umsortieren (Drag & Drop)
- [ ] Symbolizer hinzufuegen / entfernen
- [ ] Hex-Eingabefeld und HSL-Farbregler
- [ ] Undo/Redo (Style-History-Stack)
- [ ] GeoStyler-JSON-Export des editierten Styles
- [ ] Adapter-Roundtrip: editierten Style als Mapbox/QML/SLD exportieren

## Verwandte Dokumente

- [flutter_mapstyler.md](flutter_mapstyler.md) -- Renderer-API
- [architecture.md](architecture.md) -- Workspace-Architektur
- [mapstyler.md](mapstyler.md) -- Core-Style-Modell
