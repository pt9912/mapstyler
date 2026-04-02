# mapstyler_demo

Linux-Desktop-Demo fuer den `mapstyler`-Workspace. Die App verwendet direkt:

- `mapstyler_style`
- `mapbox4dart`
- `mapstyler_mapbox_adapter`
- `mapstyler_sld_adapter`
- `qml4dart`
- `mapstyler_qml_adapter`
- `flutter_mapstyler`

## Lokal mit Flutter

```bash
cd demo/mapstyler_demo
flutter run -d linux
```

## Mit Dockerfile bauen

```bash
docker build --target demo-linux-build -t mapstyler-demo-linux .
```

Der Target baut die Linux-Desktop-App komplett im Container.

Um das Release-Bundle auszugeben:

```bash
docker run --rm mapstyler-demo-linux > mapstyler_demo-linux-bundle.tar.gz
tar -xzf mapstyler_demo-linux-bundle.tar.gz
```

App ausführen:

```bash
./bundle/mapstyler_demo 
```

Hinweis: Flutter Linux erzeugt kein einzelnes statisch selbstgenuegsames Binary,
sondern ein Release-Bundle mit Executable und Runtime-Dateien.

## Inhalt

- linke Seite: Paketkarten mit kleinen Parse-/Write-Zusammenfassungen
- rechte Seite: Live-Preview mit `flutter_mapstyler`
- Umschalter fuer Core-, Mapbox-, QML- und SLD-Styles
