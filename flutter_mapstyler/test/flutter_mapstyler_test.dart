import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Expression evaluator
  // ---------------------------------------------------------------------------
  group('evaluateExpression', () {
    test('LiteralExpression returns value', () {
      expect(evaluateExpression(const LiteralExpression(42.0), {}), 42.0);
      expect(evaluateExpression(const LiteralExpression('hello'), {}), 'hello');
    });

    test('null expression returns null', () {
      expect(evaluateExpression<double>(null, {}), isNull);
    });

    test('PropertyGet reads from properties', () {
      const expr = FunctionExpression<String>(PropertyGet('name'));
      expect(evaluateExpression(expr, {'name': 'Berlin'}), 'Berlin');
    });

    test('PropertyGet returns null for missing key', () {
      const expr = FunctionExpression<String>(PropertyGet('missing'));
      expect(evaluateExpression(expr, {}), isNull);
    });

    test('ArgsFunction strConcat', () {
      const expr = FunctionExpression<String>(
        ArgsFunction(name: 'strConcat', args: [
          LiteralExpression<Object>('Hello'),
          LiteralExpression<Object>(' '),
          LiteralExpression<Object>('World'),
        ]),
      );
      expect(evaluateExpression(expr, {}), 'Hello World');
    });

    test('ArgsFunction add', () {
      const expr = FunctionExpression<double>(
        ArgsFunction(name: 'add', args: [
          LiteralExpression<Object>(10),
          LiteralExpression<Object>(5),
        ]),
      );
      expect(evaluateExpression(expr, {}), 15.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Filter evaluator
  // ---------------------------------------------------------------------------
  group('evaluateFilter', () {
    test('null filter matches everything', () {
      expect(evaluateFilter(null, {}), isTrue);
    });

    test('equality filter', () {
      const filter = ComparisonFilter(
        operator: ComparisonOperator.eq,
        property: LiteralExpression('type'),
        value: LiteralExpression<Object>('road'),
      );
      expect(evaluateFilter(filter, {'type': 'road'}), isTrue);
      expect(evaluateFilter(filter, {'type': 'river'}), isFalse);
    });

    test('numeric comparison', () {
      const filter = ComparisonFilter(
        operator: ComparisonOperator.gt,
        property: LiteralExpression('pop'),
        value: LiteralExpression<Object>(1000),
      );
      expect(evaluateFilter(filter, {'pop': 5000}), isTrue);
      expect(evaluateFilter(filter, {'pop': 500}), isFalse);
    });

    test('AND combination', () {
      const filter = CombinationFilter(
        operator: CombinationOperator.and,
        filters: [
          ComparisonFilter(
            operator: ComparisonOperator.eq,
            property: LiteralExpression('type'),
            value: LiteralExpression<Object>('road'),
          ),
          ComparisonFilter(
            operator: ComparisonOperator.gte,
            property: LiteralExpression('lanes'),
            value: LiteralExpression<Object>(2),
          ),
        ],
      );
      expect(evaluateFilter(filter, {'type': 'road', 'lanes': 4}), isTrue);
      expect(evaluateFilter(filter, {'type': 'road', 'lanes': 1}), isFalse);
    });

    test('OR combination', () {
      const filter = CombinationFilter(
        operator: CombinationOperator.or,
        filters: [
          ComparisonFilter(
            operator: ComparisonOperator.eq,
            property: LiteralExpression('type'),
            value: LiteralExpression<Object>('road'),
          ),
          ComparisonFilter(
            operator: ComparisonOperator.eq,
            property: LiteralExpression('type'),
            value: LiteralExpression<Object>('path'),
          ),
        ],
      );
      expect(evaluateFilter(filter, {'type': 'path'}), isTrue);
      expect(evaluateFilter(filter, {'type': 'river'}), isFalse);
    });

    test('negation filter', () {
      const filter = NegationFilter(
        filter: ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('hidden'),
          value: LiteralExpression<Object>(true),
        ),
      );
      expect(evaluateFilter(filter, {'hidden': false}), isTrue);
      expect(evaluateFilter(filter, {'hidden': true}), isFalse);
    });

    test('accepts optional geometry parameter', () {
      const filter = ComparisonFilter(
        operator: ComparisonOperator.eq,
        property: LiteralExpression('type'),
        value: LiteralExpression<Object>('park'),
      );
      expect(
        evaluateFilter(
          filter,
          {'type': 'park'},
          geometry: const PointGeometry(13, 52),
        ),
        isTrue,
      );
    });

    test('evaluates spatial filters against geometry', () {
      const filter = SpatialFilter(
        operator: SpatialOperator.within,
        geometry: PolygonGeometry([
          [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
        ]),
      );

      expect(
        evaluateFilter(
          filter,
          const {},
          geometry: const PointGeometry(5, 5),
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          filter,
          const {},
          geometry: const PointGeometry(15, 5),
        ),
        isFalse,
      );
    });

    test('evaluates distance filters against geometry', () {
      const filter = DistanceFilter(
        operator: DistanceOperator.dWithin,
        geometry: PointGeometry(0, 0),
        distance: 5,
      );

      expect(
        evaluateFilter(
          filter,
          const {},
          geometry: const PointGeometry(3, 4),
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          filter,
          const {},
          geometry: const PointGeometry(10, 0),
        ),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Color parser
  // ---------------------------------------------------------------------------
  group('parseHexColor', () {
    test('parses #rrggbb', () {
      final c = parseHexColor('#ff0000');
      expect(c, const Color(0xFFFF0000));
    });

    test('parses with opacity', () {
      final c = parseHexColor('#ff0000', opacity: 0.5);
      expect((c.a * 255).round(), 128);
      expect((c.r * 255).round(), 255);
    });

    test('parses short hex', () {
      final c = parseHexColor('#f00');
      expect(c, const Color(0xFFFF0000));
    });
  });

  // ---------------------------------------------------------------------------
  // StyledFeature
  // ---------------------------------------------------------------------------
  group('StyledFeature', () {
    test('can be constructed with Geometry from mapstyler_style', () {
      const f = StyledFeature(
        id: 'feature-1',
        geometry: PointGeometry(13.4, 52.5),
        properties: {'name': 'Berlin'},
      );
      expect(f.id, 'feature-1');
      expect(f.geometry, isA<PointGeometry>());
      expect(f.properties['name'], 'Berlin');
    });

    test('StyledFeatureCollection holds features', () {
      const col = StyledFeatureCollection([
        StyledFeature(geometry: PointGeometry(0, 0)),
        StyledFeature(geometry: PointGeometry(1, 1)),
      ]);
      expect(col.features, hasLength(2));
    });
  });

  // ---------------------------------------------------------------------------
  // StyleRenderer
  // ---------------------------------------------------------------------------
  group('StyleRenderer', () {
    const renderer = StyleRenderer();

    test('selectRulesAtScale filters by scale', () {
      final style = Style(rules: [
        Rule(
          name: 'visible',
          scaleDenominator: ScaleDenominator(min: 100, max: 10000),
          symbolizers: [FillSymbolizer(color: LiteralExpression('#ff0000'))],
        ),
        Rule(
          name: 'hidden',
          scaleDenominator: ScaleDenominator(min: 50000, max: 100000),
          symbolizers: [FillSymbolizer(color: LiteralExpression('#0000ff'))],
        ),
        Rule(
          name: 'always',
          symbolizers: [FillSymbolizer(color: LiteralExpression('#00ff00'))],
        ),
      ]);

      final selected = StyleRenderer.selectRulesAtScale(style, 5000);
      expect(selected.map((r) => r.name), ['visible', 'always']);
    });

    test('renderStyle produces layers for matching features', () {
      final style = Style(rules: [
        Rule(
          filter: ComparisonFilter(
            operator: ComparisonOperator.eq,
            property: LiteralExpression('type'),
            value: LiteralExpression<Object>('park'),
          ),
          symbolizers: [
            FillSymbolizer(
              color: LiteralExpression('#00ff00'),
              outlineColor: LiteralExpression('#008800'),
              outlineWidth: LiteralExpression(1.0),
            ),
          ],
        ),
      ]);

      final features = StyledFeatureCollection([
        StyledFeature(
          geometry: PolygonGeometry([
            [(13.0, 52.0), (14.0, 52.0), (14.0, 53.0), (13.0, 52.0)],
          ]),
          properties: {'type': 'park'},
        ),
        StyledFeature(
          geometry: PolygonGeometry([
            [(10.0, 50.0), (11.0, 50.0), (11.0, 51.0), (10.0, 50.0)],
          ]),
          properties: {'type': 'water'},
        ),
      ]);

      final layers = renderer.renderStyle(style: style, features: features);
      expect(layers, hasLength(1));
      expect(layers.first, isA<PolygonLayer>());
      final polygonLayer = layers.first as PolygonLayer;
      expect(polygonLayer.polygons, hasLength(1));
    });

    test('fill rendering keeps holes and combines opacity with fillOpacity', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const FillSymbolizer(
          color: LiteralExpression('#00ff00'),
          opacity: LiteralExpression(0.5),
          fillOpacity: LiteralExpression(0.4),
        ),
        features: const [
          StyledFeature(
            geometry: PolygonGeometry([
              [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
              [(2, 2), (4, 2), (4, 4), (2, 4), (2, 2)],
            ]),
          ),
        ],
      );

      expect(layer, isA<PolygonLayer<StyledFeature>>());
      final polygon = (layer as PolygonLayer<StyledFeature>).polygons.single;
      expect(polygon.holePointsList, isNotNull);
      expect(polygon.holePointsList, hasLength(1));
      expect((polygon.color!.a * 255).round(), 51);
    });

    test('renderStyle with no matching features returns empty', () {
      final style = Style(rules: [
        Rule(
          filter: ComparisonFilter(
            operator: ComparisonOperator.eq,
            property: LiteralExpression('type'),
            value: LiteralExpression<Object>('nonexistent'),
          ),
          symbolizers: [
            FillSymbolizer(color: LiteralExpression('#ff0000')),
          ],
        ),
      ]);

      final features = StyledFeatureCollection([
        StyledFeature(
          geometry: PolygonGeometry([
            [(13.0, 52.0), (14.0, 52.0), (14.0, 53.0), (13.0, 52.0)],
          ]),
          properties: {'type': 'park'},
        ),
      ]);

      final layers = renderer.renderStyle(style: style, features: features);
      expect(layers, isEmpty);
    });

    test('renderRule produces MarkerLayer for MarkSymbolizer', () {
      final rule = Rule(
        symbolizers: [
          MarkSymbolizer(
            wellKnownName: 'circle',
            radius: LiteralExpression(8.0),
            color: LiteralExpression('#ff0000'),
          ),
        ],
      );

      final features = [
        StyledFeature(
          geometry: PointGeometry(13.4, 52.5),
          properties: {},
        ),
      ];

      final layers = renderer.renderRule(rule: rule, features: features);
      expect(layers, hasLength(1));
      expect(layers.first, isA<MarkerLayer>());
      final markerLayer = layers.first as MarkerLayer;
      expect(markerLayer.markers, hasLength(1));
      expect(markerLayer.markers.first.width, 16.0);
    });

    test('renderRule produces PolylineLayer for LineSymbolizer', () {
      final rule = Rule(
        symbolizers: [
          LineSymbolizer(
            color: LiteralExpression('#333333'),
            width: LiteralExpression(2.0),
          ),
        ],
      );

      final features = [
        StyledFeature(
          geometry: LineStringGeometry([(13.0, 52.0), (14.0, 53.0)]),
          properties: {},
        ),
      ];

      final layers = renderer.renderRule(rule: rule, features: features);
      expect(layers, hasLength(1));
      expect(layers.first, isA<PolylineLayer>());
    });

    test('line rendering uses dash pattern, cap, and join', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const LineSymbolizer(
          color: LiteralExpression('#333333'),
          width: LiteralExpression(2.0),
          dasharray: [6, 2],
          cap: 'square',
          join: 'bevel',
        ),
        features: const [
          StyledFeature(
            geometry: LineStringGeometry([(13.0, 52.0), (14.0, 53.0)]),
          ),
        ],
      );

      expect(layer, isA<PolylineLayer<StyledFeature>>());
      final polyline =
          (layer as PolylineLayer<StyledFeature>).polylines.single;
      expect(polyline.pattern.segments, [6.0, 2.0]);
      expect(polyline.strokeCap, StrokeCap.square);
      expect(polyline.strokeJoin, StrokeJoin.bevel);
    });

    test('symbolizerToLayer for TextSymbolizer', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const TextSymbolizer(
          label: FunctionExpression<String>(PropertyGet('name')),
          color: LiteralExpression('#000000'),
          size: LiteralExpression(14.0),
          font: 'Fira Sans',
          opacity: LiteralExpression(0.5),
        ),
        features: const [
          StyledFeature(
            geometry: LineStringGeometry([(13.4, 52.5), (13.5, 52.6)]),
            properties: {'name': 'Berlin'},
          ),
        ],
      );
      expect(layer, isA<MarkerLayer>());
      final marker = (layer as MarkerLayer).markers.single;
      final text = marker.child as Text;
      expect(text.style?.fontFamily, 'Fira Sans');
      expect((text.style!.color!.a * 255).round(), 128);
    });

    test('symbolizerToLayer for IconSymbolizer', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const IconSymbolizer(
          image: LiteralExpression('asset:icons/marker.png'),
          size: LiteralExpression(32.0),
        ),
        features: const [
          StyledFeature(
            geometry: PointGeometry(13.4, 52.5),
            properties: {},
          ),
        ],
      );
      expect(layer, isA<MarkerLayer>());
    });

    test('symbolizerToLayer renders overlay raster layers', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const RasterSymbolizer(),
        features: const [
          StyledFeature(
            geometry: EnvelopeGeometry(
              minX: 13.0,
              minY: 52.0,
              maxX: 14.0,
              maxY: 53.0,
            ),
            properties: {'asset': 'images/raster.png'},
          ),
        ],
      );
      expect(layer, isA<OverlayImageLayer>());
    });
  });

  // ---------------------------------------------------------------------------
  // MarkPainter
  // ---------------------------------------------------------------------------
  group('MarkPainter', () {
    test('shouldRepaint returns true on change', () {
      const p1 = MarkPainter(
        wellKnownName: 'circle',
        color: Color(0xFFFF0000),
      );
      const p2 = MarkPainter(
        wellKnownName: 'square',
        color: Color(0xFFFF0000),
      );
      const p3 = MarkPainter(
        wellKnownName: 'circle',
        color: Color(0xFFFF0000),
      );
      expect(p1.shouldRepaint(p2), isTrue);
      expect(p1.shouldRepaint(p3), isFalse);
    });
  });

  testWidgets('marker tap and long-press callbacks are wired', (tester) async {
    final feature = const StyledFeature(
      id: 'feature-1',
      geometry: PointGeometry(13.4, 52.5),
    );

    StyledFeature? tapped;
    StyledFeature? longPressed;

    final layer = const StyleRenderer().symbolizerToLayer(
      symbolizer: MarkSymbolizer(
        wellKnownName: 'circle',
        radius: LiteralExpression(8.0),
        color: LiteralExpression('#ff0000'),
      ),
      features: [feature],
      onFeatureTap: null,
    );

    final interactiveLayer = const StyleRenderer().symbolizerToLayer(
      symbolizer: const MarkSymbolizer(
        wellKnownName: 'circle',
        radius: LiteralExpression(8.0),
        color: LiteralExpression('#ff0000'),
      ),
      features: [feature],
      onFeatureTap: (value) => tapped = value,
      onFeatureLongPress: (value) => longPressed = value,
    );

    expect(layer, isA<MarkerLayer>());
    expect(interactiveLayer, isA<MarkerLayer>());

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 300,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(52.5, 13.4),
              initialZoom: 10,
            ),
            children: [interactiveLayer!],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CustomPaint));
    await tester.pump();
    expect(tapped, same(feature));

    await tester.longPress(find.byType(CustomPaint));
    await tester.pump();
    expect(longPressed, same(feature));
  });
}
