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

## Docker-Builds

Das Projekt enthält ein Multi-Stage-Dockerfile. Jedes Package hat eigene Targets für Analyse, Tests, Coverage und Publish-Check. Die pure-Dart-Packages bauen auf `dart:stable`, das Flutter-Package auf `ghcr.io/cirruslabs/flutter:stable`.

### mapstyler_style

```bash
docker build --target style-analyze .
docker build --target style-test .
docker build --target style-coverage -t style:cov .
docker run --rm style:cov > coverage/lcov.info         # lcov.info extrahieren
docker build --target style-coverage-check .           # Threshold: 95 %
docker build --target style-publish-check .
docker build --target style-doc -t mapstyler_style:doc .
docker run --rm mapstyler_style:doc | tar -xzf -       # API-Docs extrahieren
```

### mapstyler_mapbox_parser

```bash
docker build --target mapbox-analyze .
docker build --target mapbox-test .
docker build --target mapbox-coverage -t mapbox:cov .
docker run --rm mapbox:cov > coverage/lcov.info        # lcov.info extrahieren
docker build --target mapbox-coverage-check .          # Threshold: 95 %
docker build --target mapbox-publish-check .
```

### mapstyler_sld_adapter

```bash
docker build --target sld-analyze .
docker build --target sld-test .
docker build --target sld-coverage -t sld:cov .
docker run --rm sld:cov > coverage/lcov.info           # lcov.info extrahieren
docker build --target sld-coverage-check .             # Threshold: 95 %
docker build --target sld-publish-check .
```

### qml4dart

```bash
docker build --target qml-analyze .
docker build --target qml-test .
docker build --target qml-publish-check .
```

### mapstyler_qml_adapter

```bash
docker build --target qml-adapter-analyze .
docker build --target qml-adapter-test .
docker build --target qml-adapter-publish-check .
```

### flutter_mapstyler

```bash
docker build --target flutter-analyze .
docker build --target flutter-test .
docker build --target flutter-coverage -t flutter:cov .
docker run --rm flutter:cov > coverage/lcov.info       # lcov.info extrahieren
docker build --target flutter-coverage-check .         # Threshold: 95 %
docker build --target flutter-publish-check .
```

Der Coverage-Threshold lässt sich per Build-Arg anpassen, z. B.:

```bash
docker build --target style-coverage-check --build-arg COVERAGE_MIN=90 .
```

## Lizenz

MIT — siehe [LICENSE](LICENSE).
