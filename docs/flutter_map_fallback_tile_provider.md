# flutter_map_fallback_tile_provider

Package-Entwurf fuer einen `TileProvider` fuer `flutter_map` mit
Datei-Cache, Parent-Tile-Fallback und Download-Throttle.

Aktueller Prototyp:
`demo/mapstyler_demo/lib/caching_tile_provider.dart`

## Motivation

Flutters `NetworkTileProvider` (Standard in `flutter_map`) hat auf
Desktop/Mobile drei Probleme gegenueber Web-Mapping-Libraries
(OpenLayers, Leaflet):

1. **Kein HTTP-Cache** -- Browser cachen Tiles automatisch; Flutter nicht.
   Jedes Tile wird bei jedem Besuch neu heruntergeladen.
2. **Leere Flaechen beim Zoomen** -- Waehrend neue Tiles laden, zeigt
   flutter_map leere Bereiche. OpenLayers zeigt stattdessen das
   Eltern-Tile skaliert an.
3. **Verbindungslimit** -- Ohne Throttle oeffnet Flutter hunderte
   parallele Verbindungen (`errno 24: Too many open files`).

## Strategie (angelehnt an OpenLayers)

```text
Tile z/x/y angefordert
      |
      v
[1] Datei-Cache pruefen (z/x/y.png)
      |-- Hit --> Bild sofort liefern, fertig
      |
      v
[2] Parent-Tile im Cache? (z-1, x/2, y/2)
      |-- Hit --> Quadrant beschneiden, hochskalieren, sofort anzeigen
      |
      v
[3] Download (mit Throttle + Retry)
      |-- Erfolg --> Bild liefern (ersetzt Fallback), in Cache schreiben
      |-- Fehler --> stiller Fehler (silent: true), kein Crash
```

### Parent-Tile-Fallback

Beim Reinzoomen wird der passende Quadrant des Eltern-Tiles
beschnitten und auf 256x256 hochskaliert:

```text
Parent-Tile (z-1)          Kind-Tile (z)
256x256                    256x256

+-------+-------+
| (0,0) | (1,0) |         +---------------+
|       |       |   -->    |               |
+-------+-------+  crop   | skaliert aus  |
| (0,1) | (1,1) | + scale | 128x128       |
|       |       |         |               |
+-------+-------+         +---------------+

Quadrant = (x % 2, y % 2)
```

Das Fallback-Tile wird ueber `ImageStreamCompleter.setImage()` sofort
emittiert. Wenn das echte Tile heruntergeladen ist, ersetzt ein zweiter
`setImage()`-Aufruf den Platzhalter.

### Download-Throttle

```text
_acquireSlot() / _releaseSlot()

Max N gleichzeitige Downloads (Default: 6).
Ueberzaehlige Requests warten in einer FIFO-Queue.
--> Verhindert errno 24 und reduziert Serverlast.
```

### Retry bei Connection-Fehlern

OSM und andere Tile-Server schliessen Keep-Alive-Verbindungen
aggressiv. Der Provider:

- setzt `HttpClient.idleTimeout` auf 5 Sekunden
- wiederholt fehlgeschlagene Downloads bis zu 2x bei
  `HttpException`, `SocketException` oder `connectionError`

## Oeffentliche API (Entwurf)

```dart
class FallbackTileProvider extends TileProvider {
  FallbackTileProvider({
    required Directory cacheDir,
    String userAgent = 'flutter_map_fallback_tile_provider',
    int maxConcurrentDownloads = 6,
    int maxRetries = 3,
    Duration idleTimeout = const Duration(seconds: 5),
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
  });

  /// Pfad zur Cache-Datei fuer ein Tile.
  /// Kann ueberschrieben werden fuer andere Cache-Schemata.
  File tileFile(int z, int x, int y);

  /// Laedt ein Tile mit Retry-Logik herunter.
  /// Kann ueberschrieben werden fuer Custom-Header,
  /// Authentifizierung oder andere Protokolle.
  Future<List<int>> downloadTile(String url);

  @override
  void dispose();
}
```

### Verwendung

```dart
final tileProvider = FallbackTileProvider(
  cacheDir: Directory('/tmp/my_tiles'),
  userAgent: 'com.example.myapp',
  maxConcurrentDownloads: 8,
);

FlutterMap(
  options: MapOptions(...),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      tileProvider: tileProvider,
      maxNativeZoom: 19,
      keepBuffer: 5,
      panBuffer: 3,
    ),
  ],
);

// Dispose wenn nicht mehr gebraucht:
tileProvider.dispose();
```

### Verschiedene Tile-Server

```dart
// Stamen Terrain
TileLayer(
  urlTemplate: 'https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}.png',
  tileProvider: tileProvider,
);

// Mapbox Raster
TileLayer(
  urlTemplate: 'https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.png?access_token=TOKEN',
  tileProvider: tileProvider,
);

// Eigener WMS als Tiles
TileLayer(
  urlTemplate: 'https://mein-server.de/wms?service=WMS&request=GetMap&layers=ortho&...',
  tileProvider: tileProvider,
);
```

## Caching-Schichten

```text
Schicht              Geschwindigkeit   Persistenz
------              ---------------   ----------
Flutter ImageCache   < 1ms             nein (RAM, begrenzt)
Datei-Cache (PNG)    1-5ms (SSD)       ja (ueberlebt Neustart)
Netzwerk             50-500ms          nein
```

Flutter's eingebauter `ImageCache` cached decodierte Bilder im RAM
automatisch. Der Datei-Cache liegt dazwischen und verhindert
Netzwerk-Zugriffe fuer bereits geladene Tiles.

## Package-Struktur

```text
flutter_map_fallback_tile_provider/
  lib/
    flutter_map_fallback_tile_provider.dart      <-- barrel export
    src/
      fallback_tile_provider.dart                <-- TileProvider + Throttle
      fallback_tile_image.dart                   <-- ImageProvider + Fallback
      tile_stream_completer.dart               <-- ImageStreamCompleter
  test/
    fallback_tile_provider_test.dart             <-- Throttle, Cache-Hit/Miss
    fallback_tile_image_test.dart                <-- Fallback-Logik
    parent_quadrant_test.dart                  <-- Quadrant-Beschneidung
  pubspec.yaml
```

### Abhaengigkeiten

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0
  flutter_map: ^7.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

Keine weiteren Abhaengigkeiten. Kein SQLite, kein Hive,
kein `dio_cache_interceptor`.

## Abgrenzung zu bestehenden Packages

| Package | Ansatz | Nachteil |
|---------|--------|----------|
| `flutter_map_tile_caching` (FMTC) | SQLite-Backend, Region-Downloads | Schwer, viele Dependencies |
| `flutter_map_cancellable_tile_provider` | Cancelbare Requests via dio | Kein Disk-Cache, kein Fallback |
| `flutter_map_cached_tile_provider` | Einfacher Cache | Kein Parent-Fallback, v0.0.2 |
| `flutter_map_cache` | Slim Caching-Plugin | Kein Parent-Fallback |
| **flutter_map_fallback_tile_provider** | Datei-Cache + Parent-Fallback + Throttle | Kein Offline-Region-Download |

Zielgruppe: Projekte die schnelles Tile-Rendering mit Disk-Cache
wollen, ohne die Komplexitaet von FMTC.

## Offene Punkte / Erweiterungen

- [ ] Cache-Groesse begrenzen (max. Dateien oder MB, LRU-Eviction)
- [ ] Cache-Invalidierung (max. Alter pro Tile)
- [ ] `clearCache()` / `clearTile(z, x, y)` API
- [ ] Kind-Tile-Compositing beim Rauszoomen (4 Tiles zusammensetzen)
- [ ] Fade-In-Animation (optional, per Parameter)
- [ ] COG/GeoTIFF-Support als separater `CogTileProvider`
  (HTTP-Range-Requests auf `.tif`, gleiche Cache/Throttle-Infrastruktur)
