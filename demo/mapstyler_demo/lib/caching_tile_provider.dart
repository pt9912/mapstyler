import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

/// Tile-Provider mit Datei-Cache, Parent-Fallback und Download-Throttle.
///
/// Strategie (angelehnt an OpenLayers):
/// 1. Exakter Cache-Hit → sofort anzeigen
/// 2. Parent-Tile gecached → Quadrant beschneiden, skaliert anzeigen
/// 3. Echtes Tile herunterladen → ersetzt den Fallback
///
/// Löst: errno 24 (Verbindungslimit), leere Flächen beim Zoomen,
/// langsames Nachladen ohne Disk-Cache.
class CachingTileProvider extends TileProvider {
  CachingTileProvider({required this.cacheDir}) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.bytes,
      headers: {'User-Agent': 'dev.mapstyler.demo'},
    ));
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      return HttpClient()
        ..maxConnectionsPerHost = _maxConcurrent
        // Idle-Verbindungen früh schließen, bevor der Server sie droppt.
        // OSM schließt Keep-Alive-Verbindungen aggressiv.
        ..idleTimeout = const Duration(seconds: 5);
    };
  }

  final Directory cacheDir;
  late final Dio _dio;

  // Download-Throttle: begrenzt gleichzeitige Netzwerk-Requests.
  int _active = 0;
  static const _maxConcurrent = 6;
  final _waitQueue = <Completer<void>>[];

  File tileFile(int z, int x, int y) =>
      File('${cacheDir.path}/$z/$x/$y.png');

  Future<void> _acquireSlot() async {
    if (_active < _maxConcurrent) {
      _active++;
      return;
    }
    final c = Completer<void>();
    _waitQueue.add(c);
    return c.future;
  }

  void _releaseSlot() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeAt(0).complete();
    } else {
      _active--;
    }
  }

  /// Download mit bis zu 2 Retries bei Connection-Fehlern
  /// (Server schließt Keep-Alive-Verbindung vor Wiederverwendung).
  Future<List<int>> downloadTile(String url) async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await _dio.get<List<int>>(url);
        return response.data!;
      } on DioException catch (e) {
        final isRetryable = e.error is HttpException ||
            e.error is SocketException ||
            e.type == DioExceptionType.connectionError;
        if (!isRetryable || attempt == maxAttempts) rethrow;
      }
    }
    throw StateError('unreachable');
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _CachedTileImage(
      url: getTileUrl(coordinates, options),
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
      provider: this,
    );
  }

  @override
  void dispose() {
    _dio.close();
    for (final c in _waitQueue) {
      c.completeError(StateError('Provider disposed'));
    }
    _waitQueue.clear();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------

/// Konkreter [ImageStreamCompleter] der [setImage] nach außen freigibt,
/// damit Fallback- und Final-Tile nacheinander emittiert werden können.
class _TileStreamCompleter extends ImageStreamCompleter {
  void reportImage(ImageInfo image) => setImage(image);
}

// ---------------------------------------------------------------------------

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  _CachedTileImage({
    required this.url,
    required this.z,
    required this.x,
    required this.y,
    required this.provider,
  });

  final String url;
  final int z;
  final int x;
  final int y;
  final CachingTileProvider provider;

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    final completer = _TileStreamCompleter();
    _loadWithFallback(completer, decode);
    return completer;
  }

  Future<void> _loadWithFallback(
    _TileStreamCompleter completer,
    ImageDecoderCallback decode,
  ) async {
    try {
      final cacheFile = provider.tileFile(z, x, y);

      // 1. Exakter Cache-Hit → fertig.
      if (await cacheFile.exists()) {
        final image = await _decodeBytes(await cacheFile.readAsBytes(), decode);
        _safeSetImage(completer, image);
        return;
      }

      // 2. Parent-Tile als Fallback (Quadrant beschnitten + hochskaliert).
      //    Wird sofort angezeigt, während das echte Tile lädt.
      if (z > 0) {
        final parentFile = provider.tileFile(z - 1, x ~/ 2, y ~/ 2);
        if (await parentFile.exists()) {
          final fallback = await _cropParentQuadrant(
            await parentFile.readAsBytes(),
          );
          if (fallback != null) {
            _safeSetImage(completer, ImageInfo(image: fallback));
          }
        }
      }

      // 3. Echtes Tile herunterladen (mit Throttle).
      await provider._acquireSlot();
      try {
        final bytes = Uint8List.fromList(await provider.downloadTile(url));

        // Cache-Write im Hintergrund.
        unawaited(() async {
          await cacheFile.parent.create(recursive: true);
          await cacheFile.writeAsBytes(bytes, flush: true);
        }());

        final image = await _decodeBytes(bytes, decode);
        _safeSetImage(completer, image);
      } finally {
        provider._releaseSlot();
      }
    } catch (e, st) {
      completer.reportError(
        exception: e,
        stack: st,
        informationCollector: () => [DiagnosticsProperty('URL', url)],
        silent: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Hilfsmethoden
  // ---------------------------------------------------------------------------

  /// Decodiert PNG-Bytes zu einem [ImageInfo].
  Future<ImageInfo> _decodeBytes(
    Uint8List bytes,
    ImageDecoderCallback decode,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await decode(buffer);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image);
  }

  /// Beschneidet das Parent-Tile auf den relevanten Quadranten und skaliert
  /// ihn auf die volle Tile-Größe.
  ///
  /// Quadrant-Zuordnung (wie bei OpenLayers):
  ///   (x%2, y%2) → (0,0)=oben-links, (1,0)=oben-rechts,
  ///                 (0,1)=unten-links, (1,1)=unten-rechts
  Future<ui.Image?> _cropParentQuadrant(Uint8List parentBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(parentBytes);
      final frame = await codec.getNextFrame();
      final src = frame.image;
      final qx = x % 2;
      final qy = y % 2;
      final half = src.width / 2;

      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        src,
        Rect.fromLTWH(qx * half, qy * half, half, half),
        Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
        Paint(),
      );
      final picture = recorder.endRecording();
      final result = await picture.toImage(src.width, src.height);

      src.dispose();
      picture.dispose();
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Setzt das Bild auf dem Completer, fängt Fehler ab falls der Completer
  /// bereits disposed wurde (z.B. Tile aus dem Viewport gescrollt).
  void _safeSetImage(_TileStreamCompleter completer, ImageInfo image) {
    try {
      completer.reportImage(image);
    } catch (_) {
      image.dispose();
    }
  }

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage && url == other.url;

  @override
  int get hashCode => url.hashCode;
}
