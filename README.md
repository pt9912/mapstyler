# mapstyler

Dart-Ökosystem für kartographische Style-Formate. Konvertiert zwischen SLD, Mapbox GL, QML und einem gemeinsamen Typsystem — und rendert das Ergebnis auf `flutter_map`.

Inspiriert von [GeoStyler](https://geostyler.org/) (TypeScript), kompatibel mit dem GeoStyler-JSON-Zwischenformat, aber eigenständig weiterentwickelt mit OGC Spatial Filters und typisiertem Geometrie-Modell.

## Packages

| Package | Beschreibung | Status |
|---|---|---|
| [`mapstyler_style`](mapstyler_style/) | Kern-Typen: Style, Rule, Symbolizer, Filter, Expression, Geometry | 🚧 In Arbeit |
| [`mapstyler_mapbox_parser`](mapstyler_mapbox_parser/) | Mapbox GL Style JSON ↔ mapstyler | geplant |
| [`mapstyler_sld_adapter`](mapstyler_sld_adapter/) | SLD via `flutter_map_sld` ↔ mapstyler | geplant |
| [`flutter_mapstyler`](flutter_mapstyler/) | Rendering auf `flutter_map` | geplant |

## Architektur

```
SLD XML ──→ flutter_map_sld ──→ mapstyler_sld_adapter ──┐
Mapbox JSON ──→ mapstyler_mapbox_parser ─────────────────┤
                                                         ▼
                                                  mapstyler_style
                                                 (pure Dart Typen)
                                                         │
                                                 flutter_mapstyler
                                                         │
                                                         ▼
                                                    flutter_map
```

## Beispiel

```dart
import 'package:mapstyler_style/mapstyler_style.dart';

// GeoStyler-JSON laden
final style = Style.fromJson({
  'name': 'Flächennutzung',
  'rules': [
    {
      'name': 'Wohngebiet',
      'filter': ['==', 'landuse', 'residential'],
      'symbolizers': [
        {'kind': 'Fill', 'color': '#ffcc00', 'opacity': 0.5},
      ],
    },
  ],
});

// Regeln und Symbolizer durchlaufen
for (final rule in style.rules) {
  print('${rule.name}: ${rule.symbolizers.length} Symbolizer');
}

// Wieder als JSON exportieren
final json = style.toJson();
```

## Plattformen

Alle Packages außer `flutter_mapstyler` sind **pure Dart** — nutzbar in Flutter-Apps, CLI-Tools und Server-Anwendungen. `flutter_mapstyler` benötigt das Flutter SDK.

## Lizenz

MIT — siehe [LICENSE](LICENSE).
