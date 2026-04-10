# Releasing mapstyler

## Tag-Schema

Releases werden ausschließlich über annotierte Git-Tags veröffentlicht.
Jedes Package hat ein eigenes Tag-Präfix:

| Package | Tag-Format | Beispiel |
|---|---|---|
| `mapstyler_style` | `mapstyler_style-vX.Y.Z` | `mapstyler_style-v0.1.0` |
| `mapbox4dart` | `mapbox4dart-vX.Y.Z` | `mapbox4dart-v0.1.0` |
| `mapstyler_mapbox_adapter` | `mapstyler_mapbox_adapter-vX.Y.Z` | `mapstyler_mapbox_adapter-v0.1.0` |
| `mapstyler_sld_adapter` | `mapstyler_sld_adapter-vX.Y.Z` | `mapstyler_sld_adapter-v0.1.0` |
| `qml4dart` | `qml4dart-vX.Y.Z` | `qml4dart-v0.1.0` |
| `mapstyler_qml_adapter` | `mapstyler_qml_adapter-vX.Y.Z` | `mapstyler_qml_adapter-v0.1.0` |
| `mapstyler_gdal_adapter` | `mapstyler_gdal_adapter-vX.Y.Z` | `mapstyler_gdal_adapter-v0.1.0` |
| `flutter_mapstyler` | `flutter_mapstyler-vX.Y.Z` | `flutter_mapstyler-v0.1.0` |

Nicht vorgesehen:

- bare Tags wie `v0.1.0`
- Package-fremde Präfixe
- Pre-Releases wie `qml4dart-v1.2.3-rc.1`

## Release-Quelle

Release-Tags dürfen nur auf Commits gesetzt werden, die auf `main` liegen.
Der Publish-Workflow prüft das vor dem Upload nach `pub.dev`.

## Release-Checkliste

Am Beispiel `qml4dart`:

1. `qml4dart/pubspec.yaml` auf die Zielversion setzen
2. `qml4dart/CHANGELOG.md` um `## X.Y.Z` ergänzen
3. lokal verifizieren:

   ```bash
   docker build --target qml-analyze .
   docker build --target qml-test .
   docker build --target qml-coverage-check --no-cache-filter qml-coverage --progress=plain .
   docker build --target qml-publish-check --progress=plain .
   ```

4. Änderungen committen und in `main` mergen
5. annotierten Tag anlegen:

   ```bash
   git tag -a qml4dart-vX.Y.Z -m "qml4dart vX.Y.Z"
   ```

6. Tag pushen:

   ```bash
   git push origin qml4dart-vX.Y.Z
   ```

Für andere Packages analog mit dem jeweiligen Präfix und Docker-Target.

## Docker-Targets pro Package

| Package | analyze | test | coverage-check | publish-check |
|---|---|---|---|---|
| mapstyler_style | `style-analyze` | `style-test` | `style-coverage-check` | `style-publish-check` |
| mapbox4dart | `mapbox4dart-analyze` | `mapbox4dart-test` | `mapbox4dart-coverage-check` | `mapbox4dart-publish-check` |
| mapstyler_mapbox_adapter | `mapbox-analyze` | `mapbox-test` | `mapbox-coverage-check` | `mapbox-publish-check` |
| mapstyler_sld_adapter | `sld-analyze` | `sld-test` | `sld-coverage-check` | `sld-publish-check` |
| qml4dart | `qml-analyze` | `qml-test` | `qml-coverage-check` | `qml-publish-check` |
| mapstyler_qml_adapter | `qml-adapter-analyze` | `qml-adapter-test` | `qml-adapter-coverage-check` | `qml-adapter-publish-check` |
| mapstyler_gdal_adapter | `gdal-analyze` | `gdal-test` | `gdal-coverage-check` | `gdal-publish-check` |
| flutter_mapstyler | `flutter-analyze` | `flutter-test` | `flutter-coverage-check` | `flutter-publish-check` |

## Automatisches Publish

Jedes Package hat einen eigenen Publish-Workflow unter `.github/workflows/publish-*.yml`.
Der Workflow wird nur für Tags im jeweiligen Schema gestartet.

GitHub Actions erzeugt keine `push`-Events, wenn mehr als drei Tags auf einmal
gepusht werden. Release-Tags deshalb einzeln oder maximal drei Tags pro Push
veröffentlichen, sonst starten die Publish-Workflows nicht.

Der eigentliche Upload läuft über den offiziellen
`dart-lang/setup-dart`-Publish-Workflow und das GitHub-Environment `pub.dev`.

## Manueller Publish via Docker

Für den allerersten Publish eines neuen Packages (automatisiertes Publishing
erfordert eine existierende Version auf pub.dev):

```bash
docker build --target qml-publish-check -t qml4dart:publish .
docker run --rm -it --net=host qml4dart:publish sh -c 'dart pub publish'
```

Der interaktive Modus (`-it`) ist nötig, damit die Authentifizierung über
den Browser abgeschlossen werden kann. `--net=host` ermöglicht den
Callback vom pub.dev OAuth-Flow.

Nach dem manuellen Erst-Publish sollte der annotierte Release-Tag trotzdem
gesetzt und gepusht werden. Der dadurch gestartete Publish-Workflow kann
fehlschlagen, wenn dieselbe Version bereits manuell auf pub.dev hochgeladen
wurde; in diesem Fall ist der manuelle Upload die maßgebliche Release-Quelle.
