import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

import 'package:mapstyler_demo/demo_data.dart';

void main() {
  group('DemoStyleKind', () {
    test('hat Labels fuer alle Werte', () {
      expect(DemoStyleKind.manual.label, 'mapstyler_style');
      expect(DemoStyleKind.mapbox.label, 'mapstyler_mapbox_adapter');
      expect(DemoStyleKind.qml.label, 'mapstyler_qml_adapter');
      expect(DemoStyleKind.sld.label, 'mapstyler_sld_adapter');
    });

    test('hat genau 4 Werte', () {
      expect(DemoStyleKind.values.length, 4);
    });
  });

  group('buildDemoFeatures', () {
    late StyledFeatureCollection features;

    setUp(() {
      features = buildDemoFeatures();
    });

    test('liefert 6 Features', () {
      expect(features.features.length, 6);
    });

    test('alle Features haben eine ID', () {
      for (final f in features.features) {
        expect(f.id, isNotNull);
        expect(f.id, isNotEmpty);
      }
    });

    test('alle Features haben einen Namen', () {
      for (final f in features.features) {
        expect(f.properties['name'], isNotNull);
      }
    });

    test('enthaelt erwartete Geometrie-Typen', () {
      final types = features.features
          .map((f) => f.geometry.runtimeType)
          .toSet();
      expect(types, contains(PolygonGeometry));
      expect(types, contains(LineStringGeometry));
      expect(types, contains(PointGeometry));
    });

    test('enthaelt water, residential, commercial, park, road, poi', () {
      final ids = features.features.map((f) => f.id).toSet();
      expect(ids, containsAll([
        'water-1',
        'residential-1',
        'commercial-1',
        'park-1',
        'road-1',
        'poi-1',
      ]));
    });
  });

  group('loadDemoData', () {
    late DemoData data;

    setUpAll(() async {
      data = await loadDemoData();
    });

    test('liefert 7 Package-Karten', () {
      expect(data.packages.length, 7);
    });

    test('alle Package-Karten haben Name, Caption und Zeilen', () {
      for (final pkg in data.packages) {
        expect(pkg.name, isNotEmpty);
        expect(pkg.caption, isNotEmpty);
        expect(pkg.lines, isNotEmpty);
      }
    });

    test('liefert Styles fuer alle 4 DemoStyleKinds', () {
      for (final kind in DemoStyleKind.values) {
        expect(data.styles[kind], isNotNull,
            reason: '${kind.name} fehlt in styles');
      }
    });

    test('jeder Style hat mindestens eine Regel', () {
      for (final entry in data.styles.entries) {
        expect(entry.value.style.rules, isNotEmpty,
            reason: '${entry.key.name} hat keine Regeln');
      }
    });

    test('jeder Style hat einen Titel und Notizen', () {
      for (final entry in data.styles.entries) {
        expect(entry.value.title, isNotEmpty);
        expect(entry.value.notes, isNotEmpty);
      }
    });

    test('Features werden mitgeliefert', () {
      expect(data.features.features, isNotEmpty);
    });
  });
}
