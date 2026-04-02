import 'package:mapbox4dart/mapbox4dart.dart' as mb;
import 'package:mapstyler_mapbox_parser/src/write/symbolizer_mapper.dart';
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:test/test.dart';

void main() {
  group('convertStyle', () {
    test('empty style produces empty layers', () {
      const style = ms.Style();
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      expect(result.output.layers, isEmpty);
      expect(result.output.version, 8);
    });

    test('fill symbolizer with filter and scale', () {
      const style = ms.Style(
        name: 'Test',
        rules: [
          ms.Rule(
            name: 'water',
            filter: ms.ComparisonFilter(
              operator: ms.ComparisonOperator.eq,
              property: ms.LiteralExpression('type'),
              value: ms.LiteralExpression<Object>('water'),
            ),
            scaleDenominator: ms.ScaleDenominator(min: 2133, max: 559082264),
            symbolizers: [
              ms.FillSymbolizer(
                color: ms.LiteralExpression('#0000ff'),
                opacity: ms.LiteralExpression(0.5),
                outlineColor: ms.LiteralExpression('#000080'),
              ),
            ],
          ),
        ],
      );

      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final layer = result.output.layers.first;
      expect(layer.type, mb.MapboxLayerType.fill);
      expect(layer.paint['fill-color'], '#0000ff');
      expect(layer.paint['fill-opacity'], 0.5);
      expect(layer.paint['fill-outline-color'], '#000080');
      expect(layer.filter, isNotNull);
      expect(layer.minzoom, isNotNull);
      expect(layer.maxzoom, isNotNull);
    });

    test('line symbolizer with dasharray', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.LineSymbolizer(
            color: ms.LiteralExpression('#333'),
            width: ms.LiteralExpression(2.0),
            opacity: ms.LiteralExpression(1.0),
            dasharray: [10, 5],
            cap: 'round',
            join: 'bevel',
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final layer = result.output.layers.first;
      expect(layer.type, mb.MapboxLayerType.line);
      expect(layer.paint['line-dasharray'], [10, 5]);
      expect(layer.layout['line-cap'], 'round');
      expect(layer.layout['line-join'], 'bevel');
    });

    test('circle mark symbolizer', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.MarkSymbolizer(
            wellKnownName: 'circle',
            radius: ms.LiteralExpression(5.0),
            color: ms.LiteralExpression('#ff0000'),
            opacity: ms.LiteralExpression(0.9),
            strokeColor: ms.LiteralExpression('#000'),
            strokeWidth: ms.LiteralExpression(1.0),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final layer = result.output.layers.first;
      expect(layer.type, mb.MapboxLayerType.circle);
      expect(layer.paint['circle-radius'], 5.0);
      expect(layer.paint['circle-stroke-color'], '#000');
    });

    test('non-circle mark produces warning', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.MarkSymbolizer(wellKnownName: 'star'),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      expect(result.warnings, anyElement(contains('star')));
      expect(result.output.layers, isEmpty);
    });

    test('text symbolizer', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.TextSymbolizer(
            label: ms.FunctionExpression(ms.PropertyGet('name')),
            size: ms.LiteralExpression(14.0),
            font: 'Arial',
            color: ms.LiteralExpression('#333'),
            opacity: ms.LiteralExpression(1.0),
            rotate: ms.LiteralExpression(0.0),
            haloColor: ms.LiteralExpression('#fff'),
            haloWidth: ms.LiteralExpression(2.0),
            placement: 'point',
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final layer = result.output.layers.first;
      expect(layer.type, mb.MapboxLayerType.symbol);
      expect(layer.layout['text-field'], ['get', 'name']);
      expect(layer.layout['text-size'], 14.0);
      expect(layer.layout['text-font'], ['Arial']);
      expect(layer.layout['symbol-placement'], 'point');
      expect(layer.paint['text-color'], '#333');
      expect(layer.paint['text-halo-width'], 2.0);
    });

    test('icon symbolizer', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.IconSymbolizer(
            image: ms.LiteralExpression('marker'),
            size: ms.LiteralExpression(1.5),
            opacity: ms.LiteralExpression(0.9),
            rotate: ms.LiteralExpression(45.0),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final layer = result.output.layers.first;
      expect(layer.type, mb.MapboxLayerType.symbol);
      expect(layer.layout['icon-image'], 'marker');
      expect(layer.layout['icon-size'], 1.5);
      expect(layer.layout['icon-rotate'], 45.0);
      expect(layer.paint['icon-opacity'], 0.9);
    });

    test('raster symbolizer', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.RasterSymbolizer(
            opacity: ms.LiteralExpression(0.7),
            hueRotate: ms.LiteralExpression(45.0),
            brightnessMin: ms.LiteralExpression(0.1),
            brightnessMax: ms.LiteralExpression(0.9),
            saturation: ms.LiteralExpression(0.5),
            contrast: ms.LiteralExpression(0.3),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final layer = result.output.layers.first;
      expect(layer.type, mb.MapboxLayerType.raster);
      expect(layer.paint['raster-opacity'], 0.7);
      expect(layer.paint['raster-hue-rotate'], 45.0);
      expect(layer.paint['raster-brightness-min'], 0.1);
      expect(layer.paint['raster-brightness-max'], 0.9);
      expect(layer.paint['raster-saturation'], 0.5);
      expect(layer.paint['raster-contrast'], 0.3);
    });

    test('combination filter serialized', () {
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.CombinationFilter(
            operator: ms.CombinationOperator.and,
            filters: [
              ms.ComparisonFilter(
                operator: ms.ComparisonOperator.eq,
                property: ms.LiteralExpression('a'),
                value: ms.LiteralExpression<Object>(1),
              ),
              ms.ComparisonFilter(
                operator: ms.ComparisonOperator.gt,
                property: ms.LiteralExpression('b'),
                value: ms.LiteralExpression<Object>(2),
              ),
            ],
          ),
          symbolizers: [
            ms.FillSymbolizer(color: ms.LiteralExpression('#f00')),
          ],
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final filter = result.output.layers.first.filter!;
      expect(filter[0], 'all');
    });

    test('negation filter', () {
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.NegationFilter(
            filter: ms.ComparisonFilter(
              operator: ms.ComparisonOperator.eq,
              property: ms.LiteralExpression('x'),
              value: ms.LiteralExpression<Object>(1),
            ),
          ),
          symbolizers: [
            ms.FillSymbolizer(color: ms.LiteralExpression('#f00')),
          ],
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      expect(result.output.layers.first.filter![0], '!');
    });

    test('spatial filter produces warning', () {
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.SpatialFilter(
            operator: ms.SpatialOperator.bbox,
            geometry: ms.EnvelopeGeometry(minX: 0, minY: 0, maxX: 1, maxY: 1),
          ),
          symbolizers: [
            ms.FillSymbolizer(color: ms.LiteralExpression('#f00')),
          ],
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      expect(result.warnings, anyElement(contains('SpatialFilter')));
    });

    test('interpolate expression roundtrip', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.LineSymbolizer(
            width: ms.FunctionExpression(ms.InterpolateFunction(
              mode: ['linear'],
              input: ms.FunctionExpression<Object>(
                  ms.ArgsFunction(name: 'zoom')),
              stops: [
                ms.InterpolateParameter(
                  stop: ms.LiteralExpression<Object>(5),
                  value: ms.LiteralExpression<Object>(1.0),
                ),
                ms.InterpolateParameter(
                  stop: ms.LiteralExpression<Object>(15),
                  value: ms.LiteralExpression<Object>(8.0),
                ),
              ],
            )),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final w = result.output.layers.first.paint['line-width'];
      expect(w, isList);
      expect((w as List)[0], 'interpolate');
    });

    test('step expression roundtrip', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.FillSymbolizer(
            color: ms.FunctionExpression(ms.StepFunction(
              input: ms.FunctionExpression<Object>(
                  ms.ArgsFunction(name: 'zoom')),
              defaultValue: ms.LiteralExpression<Object>('#000'),
              stops: [
                ms.StepParameter(
                  boundary: ms.LiteralExpression<Object>(10),
                  value: ms.LiteralExpression<Object>('#fff'),
                ),
              ],
            )),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final c = result.output.layers.first.paint['fill-color'];
      expect((c as List)[0], 'step');
    });

    test('case expression roundtrip', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.FillSymbolizer(
            color: ms.FunctionExpression(ms.CaseFunction(
              cases: [
                ms.CaseParameter(
                  condition: ms.LiteralExpression<Object>(true),
                  value: ms.LiteralExpression<Object>('#f00'),
                ),
              ],
              fallback: ms.LiteralExpression<Object>('#000'),
            )),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      final c = result.output.layers.first.paint['fill-color'];
      expect((c as List)[0], 'case');
    });

    test('all comparison operators', () {
      for (final op in ms.ComparisonOperator.values) {
        final style = ms.Style(rules: [
          ms.Rule(
            filter: ms.ComparisonFilter(
              operator: op,
              property: const ms.LiteralExpression('f'),
              value: const ms.LiteralExpression<Object>(1),
            ),
            symbolizers: const [
              ms.FillSymbolizer(color: ms.LiteralExpression('#f00')),
            ],
          ),
        ]);
        final result =
            convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
        expect(result.output.layers.first.filter, isNotNull, reason: '$op');
      }
    });

    test('multiple symbolizers produce multiple layers', () {
      const style = ms.Style(rules: [
        ms.Rule(
          name: 'multi',
          symbolizers: [
            ms.FillSymbolizer(color: ms.LiteralExpression('#f00')),
            ms.LineSymbolizer(color: ms.LiteralExpression('#333')),
          ],
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess<mb.MapboxStyle>;
      expect(result.output.layers, hasLength(2));
      expect(result.output.layers[0].type, mb.MapboxLayerType.fill);
      expect(result.output.layers[1].type, mb.MapboxLayerType.line);
    });
  });
}
