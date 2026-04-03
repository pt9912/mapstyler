import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:mapstyler_sld_adapter/src/mapstyler_to_sld.dart';
import 'package:mapstyler_sld_adapter/src/sld_to_mapstyler.dart';
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:test/test.dart';

void main() {
  group('convertStyle', () {
    test('wraps rules in single SLD layer', () {
      final style = ms.Style(
        name: 'TestStyle',
        rules: [
          ms.Rule(name: 'Rule1'),
          ms.Rule(name: 'Rule2'),
        ],
      );

      final result = convertStyle(style);
      expect(result, isA<ms.WriteStyleSuccess<sld.SldDocument>>());

      final doc = (result as ms.WriteStyleSuccess<sld.SldDocument>).output;
      expect(doc.layers, hasLength(1));
      expect(doc.layers.first.name, 'TestStyle');
      expect(doc.layers.first.styles.first.featureTypeStyles.first.rules,
          hasLength(2));
    });
  });

  group('MarkSymbolizer round-trip', () {
    test('radius×2 → size → radius', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.MarkSymbolizer(
            wellKnownName: 'circle',
            radius: ms.LiteralExpression(10.0),
            color: ms.LiteralExpression('#ff0000'),
            strokeColor: ms.LiteralExpression('#000000'),
            strokeWidth: ms.LiteralExpression(2.0),
            rotate: ms.LiteralExpression(45.0),
            opacity: ms.LiteralExpression(0.8),
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final doc = writeResult.output;
      final sldRule =
          doc.layers.first.styles.first.featureTypeStyles.first.rules.first;

      expect(sldRule.pointSymbolizer?.graphic?.size, 20.0);
      expect(sldRule.pointSymbolizer?.graphic?.mark?.wellKnownName, 'circle');

      final readResult = convertDocument(doc) as ms.ReadStyleSuccess;
      final mark =
          readResult.output.rules.first.symbolizers.first as ms.MarkSymbolizer;
      expect(mark.radius, const ms.LiteralExpression(10.0));
      expect(mark.color, const ms.LiteralExpression('#ff0000'));
      expect(mark.wellKnownName, 'circle');
    });
  });

  group('IconSymbolizer round-trip (TEST-7)', () {
    test('preserves format, size, rotation', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.IconSymbolizer(
            image: ms.LiteralExpression('marker.png'),
            format: 'image/png',
            size: ms.LiteralExpression(32.0),
            opacity: ms.LiteralExpression(0.9),
            rotate: ms.LiteralExpression(90.0),
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final readResult =
          convertDocument(writeResult.output) as ms.ReadStyleSuccess;
      final icon = readResult.output.rules.first.symbolizers.first
          as ms.IconSymbolizer;
      expect(icon.image, const ms.LiteralExpression('marker.png'));
      expect(icon.format, 'image/png');
      expect(icon.size, const ms.LiteralExpression(32.0));
      expect(icon.opacity, const ms.LiteralExpression(0.9));
      expect(icon.rotate, const ms.LiteralExpression(90.0));
    });
  });

  group('LineSymbolizer round-trip', () {
    test('preserves stroke properties', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.LineSymbolizer(
            color: ms.LiteralExpression('#333333'),
            width: ms.LiteralExpression(2.5),
            opacity: ms.LiteralExpression(0.7),
            dasharray: [10, 5],
            cap: 'round',
            join: 'miter',
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final doc = writeResult.output;
      final sldRule =
          doc.layers.first.styles.first.featureTypeStyles.first.rules.first;

      expect(sldRule.lineSymbolizer?.stroke?.lineJoin, 'mitre');

      final readResult = convertDocument(doc) as ms.ReadStyleSuccess;
      final line =
          readResult.output.rules.first.symbolizers.first as ms.LineSymbolizer;
      expect(line.color, const ms.LiteralExpression('#333333'));
      expect(line.width, const ms.LiteralExpression(2.5));
      expect(line.join, 'miter');
    });
  });

  group('FillSymbolizer round-trip', () {
    test('preserves fill and outline', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.FillSymbolizer(
            color: ms.LiteralExpression('#ffcc00'),
            fillOpacity: ms.LiteralExpression(0.5),
            outlineColor: ms.LiteralExpression('#aa8800'),
            outlineWidth: ms.LiteralExpression(1.5),
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final readResult =
          convertDocument(writeResult.output) as ms.ReadStyleSuccess;
      final fill =
          readResult.output.rules.first.symbolizers.first as ms.FillSymbolizer;
      expect(fill.color, const ms.LiteralExpression('#ffcc00'));
      expect(fill.fillOpacity, const ms.LiteralExpression(0.5));
      expect(fill.outlineColor, const ms.LiteralExpression('#aa8800'));
      expect(fill.outlineWidth, const ms.LiteralExpression(1.5));
    });

    test('preserves fill when only opacity set (WRITE-3)', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.FillSymbolizer(
            fillOpacity: ms.LiteralExpression(0.5),
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final sldRule = writeResult.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first;
      // Fill should be created even without color.
      expect(sldRule.polygonSymbolizer?.fill, isNotNull);
      expect(sldRule.polygonSymbolizer?.fill?.opacity, 0.5);
    });

    test('preserves outline when only width set (WRITE-3)', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.FillSymbolizer(
            outlineWidth: ms.LiteralExpression(2.0),
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final sldRule = writeResult.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first;
      expect(sldRule.polygonSymbolizer?.stroke, isNotNull);
      expect(sldRule.polygonSymbolizer?.stroke?.width, 2.0);
    });
  });

  group('TextSymbolizer round-trip (TEST-8)', () {
    test('preserves label, font, color, halo, placement', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.TextSymbolizer(
            label: ms.FunctionExpression(ms.PropertyGet('name')),
            font: 'Arial',
            size: ms.LiteralExpression(14.0),
            color: ms.LiteralExpression('#333333'),
            haloColor: ms.LiteralExpression('#ffffff'),
            haloWidth: ms.LiteralExpression(2.0),
            placement: 'point',
            rotate: ms.LiteralExpression(30.0),
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final readResult =
          convertDocument(writeResult.output) as ms.ReadStyleSuccess;
      final text = readResult.output.rules.first.symbolizers.first
          as ms.TextSymbolizer;
      expect(text.label,
          const ms.FunctionExpression<String>(ms.PropertyGet('name')));
      expect(text.font, 'Arial');
      expect(text.color, const ms.LiteralExpression('#333333'));
      expect(text.haloColor, const ms.LiteralExpression('#ffffff'));
      expect(text.haloWidth, const ms.LiteralExpression(2.0));
      expect(text.placement, 'point');
    });

    test('preserves halo when only width set (WRITE-2)', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.TextSymbolizer(
            label: ms.LiteralExpression('Test'),
            haloWidth: ms.LiteralExpression(3.0),
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final sldRule = writeResult.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first;
      expect(sldRule.textSymbolizer?.halo, isNotNull);
      expect(sldRule.textSymbolizer?.halo?.radius, 3.0);
    });
  });

  group('RasterSymbolizer round-trip (TEST-6)', () {
    test('preserves colorMap and channels', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.RasterSymbolizer(
            opacity: const ms.LiteralExpression(0.8),
            colorMap: ms.ColorMap(
              type: 'ramp',
              colorMapEntries: const [
                ms.ColorMapEntry(color: '#00ff00', quantity: 0, opacity: 1.0),
                ms.ColorMapEntry(color: '#ff0000', quantity: 100, opacity: 1.0),
              ],
            ),
            channelSelection: const ms.ChannelSelection(
              grayChannel: ms.Channel(sourceChannelName: '1'),
            ),
          ),
        ]),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final readResult =
          convertDocument(writeResult.output) as ms.ReadStyleSuccess;
      final raster = readResult.output.rules.first.symbolizers.first
          as ms.RasterSymbolizer;
      expect(raster.opacity, const ms.LiteralExpression(0.8));
      expect(raster.colorMap?.type, 'ramp');
      expect(raster.colorMap?.colorMapEntries, hasLength(2));
      expect(raster.channelSelection?.grayChannel?.sourceChannelName, '1');
    });
  });

  group('Filter round-trip', () {
    test('preserves comparison filter (BUG-4 fix: value is Literal not PropertyName)',
        () {
      final style = ms.Style(rules: [
        ms.Rule(
          filter: const ms.ComparisonFilter(
            operator: ms.ComparisonOperator.eq,
            property: ms.LiteralExpression('type'),
            value: ms.LiteralExpression('road'),
          ),
        ),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final sldRule = writeResult.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first;
      final sldFilter = sldRule.filter as sld.PropertyIsEqualTo;
      // BUG-4 fix: expression1 = PropertyName, expression2 = Literal.
      expect(sldFilter.expression1, isA<sld.PropertyName>());
      expect(sldFilter.expression2, isA<sld.Literal>());
      expect((sldFilter.expression2 as sld.Literal).value, 'road');
    });

    test('preserves gt filter', () {
      final style = ms.Style(rules: [
        ms.Rule(
          filter: const ms.ComparisonFilter(
            operator: ms.ComparisonOperator.gt,
            property: ms.LiteralExpression('population'),
            value: ms.LiteralExpression(10000),
          ),
        ),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final sldRule = writeResult.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first;
      expect(sldRule.filter, isA<sld.PropertyIsGreaterThan>());
    });

    test('preserves combination filter', () {
      final style = ms.Style(rules: [
        ms.Rule(
          filter: const ms.CombinationFilter(
            operator: ms.CombinationOperator.and,
            filters: [
              ms.ComparisonFilter(
                operator: ms.ComparisonOperator.eq,
                property: ms.LiteralExpression('type'),
                value: ms.LiteralExpression('road'),
              ),
              ms.ComparisonFilter(
                operator: ms.ComparisonOperator.gt,
                property: ms.LiteralExpression('width'),
                value: ms.LiteralExpression(5),
              ),
            ],
          ),
        ),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final sldRule = writeResult.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first;
      expect(sldRule.filter, isA<sld.And>());
      expect((sldRule.filter as sld.And).filters, hasLength(2));
    });

    test('preserves Or filter (TEST-9)', () {
      final style = ms.Style(rules: [
        ms.Rule(
          filter: const ms.CombinationFilter(
            operator: ms.CombinationOperator.or,
            filters: [
              ms.ComparisonFilter(
                operator: ms.ComparisonOperator.eq,
                property: ms.LiteralExpression('type'),
                value: ms.LiteralExpression('a'),
              ),
              ms.ComparisonFilter(
                operator: ms.ComparisonOperator.eq,
                property: ms.LiteralExpression('type'),
                value: ms.LiteralExpression('b'),
              ),
            ],
          ),
        ),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final sldRule = writeResult.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first;
      expect(sldRule.filter, isA<sld.Or>());
    });

    test('preserves negation filter', () {
      final style = ms.Style(rules: [
        ms.Rule(
          filter: const ms.NegationFilter(
            filter: ms.ComparisonFilter(
              operator: ms.ComparisonOperator.eq,
              property: ms.LiteralExpression('hidden'),
              value: ms.LiteralExpression(true),
            ),
          ),
        ),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final sldRule = writeResult.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first;
      expect(sldRule.filter, isA<sld.Not>());
    });
  });

  group('Spatial filter round-trip', () {
    test('preserves spatial filter geometry', () {
      final style = ms.Style(rules: [
        ms.Rule(
          filter: const ms.SpatialFilter(
            operator: ms.SpatialOperator.intersects,
            geometry: ms.PointGeometry(8.5, 47.5),
          ),
        ),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final readResult =
          convertDocument(writeResult.output) as ms.ReadStyleSuccess;
      final filter = readResult.output.rules.first.filter as ms.SpatialFilter;
      expect(filter.operator, ms.SpatialOperator.intersects);
      expect(filter.geometry, const ms.PointGeometry(8.5, 47.5));
    });

    test('preserves Beyond distance filter (TEST-10)', () {
      final style = ms.Style(rules: [
        ms.Rule(
          filter: const ms.DistanceFilter(
            operator: ms.DistanceOperator.beyond,
            geometry: ms.PointGeometry(8.5, 47.5),
            distance: 5000,
            units: 'm',
          ),
        ),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final readResult =
          convertDocument(writeResult.output) as ms.ReadStyleSuccess;
      final df = readResult.output.rules.first.filter as ms.DistanceFilter;
      expect(df.operator, ms.DistanceOperator.beyond);
      expect(df.distance, 5000);
      expect(df.units, 'm');
    });
  });

  group('Scale denominator round-trip', () {
    test('preserves min and max', () {
      final style = ms.Style(rules: [
        ms.Rule(
          scaleDenominator: const ms.ScaleDenominator(min: 1000, max: 50000),
        ),
      ]);

      final writeResult = convertStyle(style) as ms.WriteStyleSuccess;
      final readResult =
          convertDocument(writeResult.output) as ms.ReadStyleSuccess;
      expect(readResult.output.rules.first.scaleDenominator?.min, 1000);
      expect(readResult.output.rules.first.scaleDenominator?.max, 50000);
    });
  });

  group('warnings', () {
    test('reports CSS-filter properties as unsupported', () {
      final style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          const ms.RasterSymbolizer(
            hueRotate: ms.LiteralExpression(90.0),
            saturation: ms.LiteralExpression(1.5),
          ),
        ]),
      ]);

      final result = convertStyle(style) as ms.WriteStyleSuccess;
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first, contains('CSS-filter'));
    });
  });
}
