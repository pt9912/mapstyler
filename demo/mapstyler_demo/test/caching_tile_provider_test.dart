import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mapstyler_demo/caching_tile_provider.dart';

void main() {
  group('CachingTileProvider', () {
    late Directory tempDir;
    late CachingTileProvider provider;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tile_test_');
      provider = CachingTileProvider(cacheDir: tempDir);
    });

    tearDown(() {
      provider.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('tileFile', () {
      test('konstruiert korrekten Pfad aus z/x/y', () {
        final file = provider.tileFile(14, 8765, 5432);
        expect(file.path, '${tempDir.path}/14/8765/5432.png');
      });

      test('behandelt Zoom-Level 0', () {
        final file = provider.tileFile(0, 0, 0);
        expect(file.path, '${tempDir.path}/0/0/0.png');
      });

      test('behandelt hohe Koordinaten', () {
        final file = provider.tileFile(19, 262143, 174762);
        expect(file.path, '${tempDir.path}/19/262143/174762.png');
      });
    });

    test('kann erstellt und disposed werden ohne Fehler', () {
      final p = CachingTileProvider(cacheDir: tempDir);
      expect(() => p.dispose(), returnsNormally);
    });

    test('mehrfaches Dispose wirft keinen Fehler', () {
      final p = CachingTileProvider(cacheDir: tempDir);
      p.dispose();
      // Dio.close() ist idempotent
      expect(() => p.dispose(), returnsNormally);
    });
  });
}
