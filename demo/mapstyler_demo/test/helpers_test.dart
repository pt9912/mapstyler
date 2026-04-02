import 'package:flutter/material.dart';
import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

import 'package:mapstyler_demo/demo_data.dart';
import 'package:mapstyler_demo/widgets.dart';

void main() {
  group('shortLabel', () {
    test('liefert Kurzbezeichnungen fuer alle DemoStyleKinds', () {
      expect(shortLabel(DemoStyleKind.manual), 'Core');
      expect(shortLabel(DemoStyleKind.mapbox), 'Mapbox');
      expect(shortLabel(DemoStyleKind.qml), 'QML');
      expect(shortLabel(DemoStyleKind.sld), 'SLD');
    });
  });

  group('packageAccent', () {
    test('liefert 7 verschiedene Farben', () {
      final colors = List.generate(7, packageAccent);
      expect(colors.toSet().length, 7);
    });

    test('wiederholt Palette nach 7 Eintraegen', () {
      expect(packageAccent(0), packageAccent(7));
      expect(packageAccent(1), packageAccent(8));
      expect(packageAccent(6), packageAccent(13));
    });

    test('liefert gueltige Farben', () {
      for (var i = 0; i < 14; i++) {
        expect(packageAccent(i), isA<Color>());
      }
    });
  });

  group('featureBounds', () {
    test('berechnet Bounds aus PointGeometry', () {
      const features = StyledFeatureCollection([
        StyledFeature(
          id: 'p1',
          geometry: PointGeometry(13.4, 52.5),
          properties: {},
        ),
      ]);
      final bounds = featureBounds(features);
      expect(bounds.south, 52.5);
      expect(bounds.west, 13.4);
    });

    test('berechnet Bounds aus LineStringGeometry', () {
      const features = StyledFeatureCollection([
        StyledFeature(
          id: 'l1',
          geometry: LineStringGeometry([
            (13.3, 52.4),
            (13.5, 52.6),
          ]),
          properties: {},
        ),
      ]);
      final bounds = featureBounds(features);
      expect(bounds.south, 52.4);
      expect(bounds.north, 52.6);
      expect(bounds.west, 13.3);
      expect(bounds.east, 13.5);
    });

    test('berechnet Bounds aus PolygonGeometry', () {
      const features = StyledFeatureCollection([
        StyledFeature(
          id: 'poly1',
          geometry: PolygonGeometry([
            [
              (13.0, 52.0),
              (14.0, 52.0),
              (14.0, 53.0),
              (13.0, 53.0),
              (13.0, 52.0),
            ],
          ]),
          properties: {},
        ),
      ]);
      final bounds = featureBounds(features);
      expect(bounds.south, 52.0);
      expect(bounds.north, 53.0);
      expect(bounds.west, 13.0);
      expect(bounds.east, 14.0);
    });

    test('berechnet Bounds aus EnvelopeGeometry', () {
      const features = StyledFeatureCollection([
        StyledFeature(
          id: 'env1',
          geometry: EnvelopeGeometry(
            minX: 10.0,
            minY: 50.0,
            maxX: 12.0,
            maxY: 51.0,
          ),
          properties: {},
        ),
      ]);
      final bounds = featureBounds(features);
      expect(bounds.south, 50.0);
      expect(bounds.north, 51.0);
      expect(bounds.west, 10.0);
      expect(bounds.east, 12.0);
    });

    test('liefert Fallback-Bounds bei leerer Collection', () {
      const features = StyledFeatureCollection([]);
      final bounds = featureBounds(features);
      // Fallback: Berlin-Zentrum
      expect(bounds.south, 52.519);
      expect(bounds.west, 13.399);
    });

    test('berechnet Bounds ueber gemischte Geometrien', () {
      const features = StyledFeatureCollection([
        StyledFeature(
          id: 'p1',
          geometry: PointGeometry(13.0, 52.0),
          properties: {},
        ),
        StyledFeature(
          id: 'p2',
          geometry: PointGeometry(14.0, 53.0),
          properties: {},
        ),
      ]);
      final bounds = featureBounds(features);
      expect(bounds.south, 52.0);
      expect(bounds.north, 53.0);
      expect(bounds.west, 13.0);
      expect(bounds.east, 14.0);
    });
  });
}
