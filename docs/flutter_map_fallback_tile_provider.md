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
[1] Datei-Cache pruefen (<cacheNamespace>/z/x/y.tile)
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
beschnitten und auf die volle Ziel-Tile-Groesse hochskaliert:

```text
Parent-Tile (z-1)          Kind-Tile (z)
NxN                        NxN

+-------+-------+
| (0,0) | (1,0) |         +---------------+
|       |       |   -->    |               |
+-------+-------+  crop   | skaliert aus  |
| (0,1) | (1,1) | + scale | N/2 x N/2     |
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

### Cache-Namespace und Cache-Frische

Der Cache darf nicht nur aus `z/x/y` bestehen. Sonst kollidieren
unterschiedliche Tile-Quellen oder Varianten im selben `cacheDir`
(z.B. OSM vs. Mapbox, verschiedene Query-Parameter, Styles,
Sprachvarianten oder 256er vs. 512er Tiles).

Darum trennt der Provider Dateien standardmaessig pro Quelle in einem
eigenen Namespace, z.B. ueber einen stabilen Hash aus URL-Template und
relevanten Layer-Optionen.

Zusatzlich ersetzt der Datei-Cache den HTTP-Cache nicht blind: Tiles
sollten nur verwendet werden, solange sie noch frisch sind. Mindestens
ein `maxCacheAge` gehoert deshalb in den MVP; spaeter koennen
`Cache-Control`-, `ETag`- oder `Last-Modified`-basierte Revalidation
erganzt werden.

## Oeffentliche API (Entwurf)

```dart
class FallbackTileProvider extends TileProvider {
  FallbackTileProvider({
    required Directory cacheDir,
    String userAgent = 'flutter_map_fallback_tile_provider',
    int maxConcurrentDownloads = 6,
    int maxRetries = 3,
    Duration? maxCacheAge,
    int? maxCacheSizeBytes,
    Duration idleTimeout = const Duration(seconds: 5),
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
  });

  /// Trennt Cache-Dateien pro Tile-Quelle / Variantenraum.
  /// Default: stabiler Namespace aus URL-Template + relevanten Optionen.
  String cacheNamespaceFor(TileCoordinates coordinates, TileLayer options);

  /// Pfad zur Cache-Datei fuer ein Tile.
  /// Kann ueberschrieben werden fuer andere Cache-Schemata.
  File tileFile(String cacheNamespace, int z, int x, int y);

  /// Laedt ein Tile mit Retry-Logik herunter.
  /// Kann ueberschrieben werden fuer Custom-Header,
  /// Authentifizierung oder andere Protokolle.
  Future<List<int>> downloadTile(String url);

  /// Entfernt alle Cache-Dateien dieses Providers.
  Future<void> clearCache();

  /// Entfernt genau ein Tile aus dem Cache.
  Future<void> clearTile(String cacheNamespace, int z, int x, int y);

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
  maxCacheAge: const Duration(days: 7),
  maxCacheSizeBytes: 512 * 1024 * 1024,
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

// Tiled WMS / XYZ-kompatibler WMS-Endpunkt
TileLayer(
  urlTemplate: 'https://mein-server.de/wms?service=WMS&request=GetMap'
      '&layers=ortho&styles=&format=image/png&transparent=false'
      '&version=1.3.0&crs=EPSG:3857&width=256&height=256'
      '&bbox={bbox-epsg-3857}',
  tileProvider: tileProvider,
);
```

Fuer klassisches, frei parametrisiertes WMS ohne Tile-Platzhalter reicht
ein simples `TileLayer(urlTemplate: ...)` nicht aus. Dafuer braucht es
entweder einen tiled WMS-Endpunkt oder eine separate WMS-Integration.

## Caching-Schichten

```text
Schicht              Geschwindigkeit   Persistenz
------              ---------------   ----------
Flutter ImageCache   < 1ms             nein (RAM, begrenzt)
Datei-Cache (PNG)    1-5ms (SSD)       ja (ueberlebt Neustart, bis TTL)
Netzwerk             50-500ms          nein
```

Flutter's eingebauter `ImageCache` cached decodierte Bilder im RAM
automatisch. Der Datei-Cache liegt dazwischen und verhindert
Netzwerk-Zugriffe fuer bereits geladene Tiles, solange sie noch als
frisch gelten.

## Produktentscheidungen

- Cache-Freshness im MVP: Ein Tile ist gueltig, solange `maxCacheAge`
  nicht ueberschritten ist. HTTP-Revalidation via `ETag` oder
  `Last-Modified` ist bewusst nicht Teil von v1.
- Cache-Groesse im MVP: Optionales `maxCacheSizeBytes`. Wenn das Limit
  ueberschritten wird, loescht der Provider alte Dateien opportunistisch
  nach `mtime` (approximate LRU), z.B. beim Start und nach neuen
  Downloads. Kein harter Echtzeit-Garant.
- Manuelle Cache-Steuerung im MVP: `clearCache()` und
  `clearTile(cacheNamespace, z, x, y)` gehoeren zur oeffentlichen API.
- Zoom-out-Optimierung: Kind-Tile-Compositing beim Rauszoomen ist kein
  Bestandteil von v1. Der erste Scope optimiert nur das Reinzoomen ueber
  Parent-Tile-Fallback.
- Animationen: Kein eingebautes Fade-In im Provider. Bilduebergaenge
  sollen, falls gewuenscht, oberhalb des Providers im Widget-Layer
  geloest werden.
- COG/GeoTIFF: Kein Bestandteil dieses Packages. Falls noetig, spaeter
  als separater `CogTileProvider` mit gemeinsamer Cache- und
  Throttle-Infrastruktur.

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

## Spaetere Erweiterungen

- HTTP-Revalidation via `ETag` / `Last-Modified` als Upgrade ueber die
  einfache TTL-Logik hinaus
- Feineres Eviction-Tracking, falls approximate LRU ueber `mtime` nicht
  ausreicht
- Telemetrie / Debug-Hooks fuer Cache-Hits, Fallback-Hits und Downloads
- Separater `CogTileProvider` fuer COG/GeoTIFF mit HTTP-Range-Requests
