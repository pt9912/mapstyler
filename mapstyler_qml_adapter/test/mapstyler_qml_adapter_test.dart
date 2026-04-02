import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:qml4dart/qml4dart.dart' as qml;
import 'package:test/test.dart';

void main() {
  const parser = QmlStyleParser();

  // ---------------------------------------------------------------------------
  // Color utilities
  // ---------------------------------------------------------------------------
  group('Color utilities', () {
    test('qgisColorToHex converts RGBA string', () {
      expect(qgisColorToHex('255,0,128,255'), '#ff0080');
      expect(qgisColorToHex('0,0,0,255'), '#000000');
    });

    test('qgisColorToHex returns null for invalid input', () {
      expect(qgisColorToHex(null), isNull);
      expect(qgisColorToHex('invalid'), isNull);
    });

    test('qgisColorToOpacity extracts alpha', () {
      expect(qgisColorToOpacity('0,0,0,128'), closeTo(0.502, 0.01));
      expect(qgisColorToOpacity('0,0,0,255'), isNull); // fully opaque
      expect(qgisColorToOpacity('0,0,0'), isNull); // no alpha
    });

    test('hexToQgisColor converts hex to RGBA', () {
      expect(hexToQgisColor('#ff0080'), '255,0,128,255');
      expect(hexToQgisColor('#000000', opacity: 0.5), '0,0,0,128');
    });

    test('hexToQgisColor handles short hex', () {
      expect(hexToQgisColor('#f00'), '255,0,0,255');
    });
  });

  // ---------------------------------------------------------------------------
  // QML → mapstyler_style (Read direction)
  // ---------------------------------------------------------------------------
  group('QML → mapstyler_style', () {
    test('singleSymbol SimpleFill', () async {
      final doc = qml.QmlDocument(
        version: '3.28.0',
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.singleSymbol,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.fill,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleFill,
                  className: 'SimpleFill',
                  properties: {
                    'color': '255,255,0,255',
                    'outline_color': '0,0,0,255',
                    'outline_width': '0.26',
                  },
                ),
              ],
            ),
          },
        ),
      );

      final result = await parser.readStyle(doc);
      expect(result, isA<ms.ReadStyleSuccess>());
      final style = (result as ms.ReadStyleSuccess).output;

      expect(style.rules, hasLength(1));
      final sym = style.rules.first.symbolizers.first;
      expect(sym, isA<ms.FillSymbolizer>());
      final fill = sym as ms.FillSymbolizer;
      expect(
        (fill.color as ms.LiteralExpression<String>).value,
        '#ffff00',
      );
      expect(
        (fill.outlineColor as ms.LiteralExpression<String>).value,
        '#000000',
      );
      expect(
        (fill.outlineWidth as ms.LiteralExpression<double>).value,
        0.26,
      );
    });

    test('singleSymbol SimpleLine with dash', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.singleSymbol,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.line,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleLine,
                  className: 'SimpleLine',
                  properties: {
                    'line_color': '255,0,0,255',
                    'line_width': '2.5',
                    'capstyle': 'round',
                    'joinstyle': 'bevel',
                    'customdash': '10;5',
                    'use_custom_dash': '1',
                  },
                ),
              ],
            ),
          },
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;
      final line = style.rules.first.symbolizers.first as ms.LineSymbolizer;

      expect((line.color as ms.LiteralExpression<String>).value, '#ff0000');
      expect((line.width as ms.LiteralExpression<double>).value, 2.5);
      expect(line.cap, 'round');
      expect(line.join, 'bevel');
      expect(line.dasharray, [10.0, 5.0]);
    });

    test('singleSymbol SimpleMarker', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.singleSymbol,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.marker,
              alpha: 0.8,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleMarker,
                  className: 'SimpleMarker',
                  properties: {
                    'color': '0,128,255,255',
                    'name': 'circle',
                    'size': '10',
                    'outline_color': '0,0,0,255',
                    'outline_width': '1',
                    'angle': '45',
                  },
                ),
              ],
            ),
          },
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;
      final mark = style.rules.first.symbolizers.first as ms.MarkSymbolizer;

      expect(mark.wellKnownName, 'circle');
      expect((mark.radius as ms.LiteralExpression<double>).value, 5.0); // size/2
      expect((mark.color as ms.LiteralExpression<String>).value, '#0080ff');
      expect(
        (mark.strokeWidth as ms.LiteralExpression<double>).value,
        1.0,
      );
      expect((mark.rotate as ms.LiteralExpression<double>).value, 45.0);
      // Opacity: alpha 0.8 * color alpha 1.0 = 0.8
      expect(
        (mark.opacity as ms.LiteralExpression<double>).value,
        closeTo(0.8, 0.01),
      );
    });

    test('singleSymbol SvgMarker → IconSymbolizer', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.singleSymbol,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.marker,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.svgMarker,
                  className: 'SvgMarker',
                  properties: {
                    'name': '/icons/hospital.svg',
                    'size': '12',
                    'angle': '90',
                  },
                ),
              ],
            ),
          },
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;
      final icon = style.rules.first.symbolizers.first as ms.IconSymbolizer;

      expect(
        (icon.image as ms.LiteralExpression<String>).value,
        '/icons/hospital.svg',
      );
      expect((icon.size as ms.LiteralExpression<double>).value, 12.0);
      expect((icon.rotate as ms.LiteralExpression<double>).value, 90.0);
    });

    test('categorizedSymbol generates equality filters', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.categorizedSymbol,
          attribute: 'landuse',
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.fill,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleFill,
                  className: 'SimpleFill',
                  properties: {'color': '255,255,0,255'},
                ),
              ],
            ),
            '1': qml.QmlSymbol(
              type: qml.QmlSymbolType.fill,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleFill,
                  className: 'SimpleFill',
                  properties: {'color': '255,0,0,255'},
                ),
              ],
            ),
          },
          categories: [
            qml.QmlCategory(
              value: 'residential',
              symbolKey: '0',
              label: 'Wohngebiet',
            ),
            qml.QmlCategory(
              value: 'industrial',
              symbolKey: '1',
              label: 'Industrie',
              render: false,
            ),
            qml.QmlCategory(value: '', symbolKey: '1', label: 'Sonstige'),
          ],
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;

      // industrial has render=false → skipped. Empty value → no filter.
      expect(style.rules, hasLength(2));

      expect(style.rules[0].name, 'Wohngebiet');
      final filter = style.rules[0].filter as ms.ComparisonFilter;
      expect(filter.operator, ms.ComparisonOperator.eq);
      expect(
        (filter.property as ms.LiteralExpression<String>).value,
        'landuse',
      );
      expect(
        (filter.value as ms.LiteralExpression<Object>).value,
        'residential',
      );

      // Empty value category has no filter.
      expect(style.rules[1].name, 'Sonstige');
      expect(style.rules[1].filter, isNull);
    });

    test('graduatedSymbol generates range filters', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.graduatedSymbol,
          attribute: 'population',
          graduatedMethod: 'GraduatedColor',
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.fill,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleFill,
                  className: 'SimpleFill',
                  properties: {'color': '255,255,255,255'},
                ),
              ],
            ),
          },
          ranges: [
            qml.QmlRange(
              lower: 0,
              upper: 1000,
              symbolKey: '0',
              label: '0–1000',
            ),
          ],
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;

      expect(style.rules, hasLength(1));
      final combFilter = style.rules[0].filter as ms.CombinationFilter;
      expect(combFilter.operator, ms.CombinationOperator.and);
      expect(combFilter.filters, hasLength(2));

      final gte = combFilter.filters[0] as ms.ComparisonFilter;
      expect(gte.operator, ms.ComparisonOperator.gte);
      expect((gte.value as ms.LiteralExpression<Object>).value, 0.0);

      final lt = combFilter.filters[1] as ms.ComparisonFilter;
      expect(lt.operator, ms.ComparisonOperator.lt);
      expect((lt.value as ms.LiteralExpression<Object>).value, 1000.0);
    });

    test('ruleRenderer with simple filters', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.ruleRenderer,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.marker,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleMarker,
                  className: 'SimpleMarker',
                  properties: {'color': '255,0,0,255', 'name': 'circle', 'size': '6'},
                ),
              ],
            ),
          },
          rules: [
            qml.QmlRule(
              key: 'r0',
              symbolKey: '0',
              label: 'Type A',
              filter: "type = 'A'",
              scaleMinDenominator: 100,
              scaleMaxDenominator: 5000,
            ),
            qml.QmlRule(
              key: 'r1',
              symbolKey: '0',
              label: 'Disabled',
              filter: "type = 'B'",
              enabled: false,
            ),
          ],
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;

      // Disabled rule skipped.
      expect(style.rules, hasLength(1));
      expect(style.rules[0].name, 'Type A');

      final filter = style.rules[0].filter as ms.ComparisonFilter;
      expect(filter.operator, ms.ComparisonOperator.eq);
      expect((filter.value as ms.LiteralExpression<Object>).value, 'A');

      expect(style.rules[0].scaleDenominator?.min, 100);
      expect(style.rules[0].scaleDenominator?.max, 5000);
    });

    test('nested rules combine parent filter', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.ruleRenderer,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.marker,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleMarker,
                  className: 'SimpleMarker',
                  properties: {'color': '255,0,0,255', 'name': 'circle', 'size': '4'},
                ),
              ],
            ),
          },
          rules: [
            qml.QmlRule(
              key: 'parent',
              label: 'Parent',
              filter: "type = 'A'",
              children: [
                qml.QmlRule(
                  key: 'child',
                  symbolKey: '0',
                  label: 'Child',
                  filter: 'subtype = 1',
                ),
              ],
            ),
          ],
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;

      expect(style.rules, hasLength(1));
      expect(style.rules[0].name, 'Child');

      // Parent + child filters combined with AND.
      final combined = style.rules[0].filter as ms.CombinationFilter;
      expect(combined.operator, ms.CombinationOperator.and);
      expect(combined.filters, hasLength(2));
    });

    test('scale visibility from document level', () async {
      final doc = qml.QmlDocument(
        hasScaleBasedVisibility: true,
        maxScale: 1000,
        minScale: 50000,
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.singleSymbol,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.fill,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleFill,
                  className: 'SimpleFill',
                  properties: {'color': '100,100,100,255'},
                ),
              ],
            ),
          },
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;

      expect(style.rules.first.scaleDenominator?.min, 1000);
      expect(style.rules.first.scaleDenominator?.max, 50000);
    });

    test('categorizedSymbol warns on missing symbol', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.categorizedSymbol,
          attribute: 'x',
          symbols: {},
          categories: [
            qml.QmlCategory(value: 'a', symbolKey: '99', label: 'Missing'),
          ],
        ),
      );
      final result = await parser.readStyle(doc);
      final success = result as ms.ReadStyleSuccess;
      expect(success.warnings, anyElement(contains('symbol 99 not found')));
      expect(success.output.rules, isEmpty);
    });

    test('graduatedSymbol warns on missing symbol', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.graduatedSymbol,
          attribute: 'pop',
          symbols: {},
          ranges: [
            qml.QmlRange(lower: 0, upper: 100, symbolKey: '99', label: 'Missing'),
          ],
        ),
      );
      final result = await parser.readStyle(doc);
      final success = result as ms.ReadStyleSuccess;
      expect(success.warnings, anyElement(contains('symbol 99 not found')));
    });

    test('unknown renderer type produces warning', () async {
      final doc = qml.QmlDocument(
        renderer: const qml.QmlRenderer(type: qml.QmlRendererType.unknown),
      );
      final result = await parser.readStyle(doc);
      final success = result as ms.ReadStyleSuccess;
      expect(success.warnings, anyElement(contains('Unknown renderer type')));
    });

    test('ruleRenderer warns on missing symbol', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.ruleRenderer,
          symbols: {},
          rules: [
            qml.QmlRule(key: 'r0', symbolKey: '99', label: 'Bad'),
          ],
        ),
      );
      final result = await parser.readStyle(doc);
      final success = result as ms.ReadStyleSuccess;
      expect(success.warnings, anyElement(contains('symbol 99 not found')));
    });

    test('ruleRenderer warns on unparseable filter', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.ruleRenderer,
          symbols: {
            '0': const qml.QmlSymbol(type: qml.QmlSymbolType.marker),
          },
          rules: [
            qml.QmlRule(
              key: 'r0',
              symbolKey: '0',
              label: 'Complex',
              filter: 'CASE WHEN x THEN y END',
            ),
          ],
        ),
      );
      final result = await parser.readStyle(doc);
      final success = result as ms.ReadStyleSuccess;
      expect(success.warnings, anyElement(contains('Could not parse filter')));
    });

    test('RasterFill and unknown layer type produce warnings', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.singleSymbol,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.fill,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.rasterFill,
                  className: 'RasterFill',
                  properties: {},
                ),
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.unknown,
                  className: 'WeirdLayer',
                  properties: {},
                ),
              ],
            ),
          },
        ),
      );
      final result = await parser.readStyle(doc);
      final success = result as ms.ReadStyleSuccess;
      expect(success.warnings, anyElement(contains('RasterFill')));
      expect(success.warnings, anyElement(contains('Unknown symbol layer')));
    });

    test('marker shape mapping covers all shapes', () async {
      for (final entry in {
        'diamond': 'diamond',
        'triangle': 'triangle',
        'equilateral_triangle': 'triangle',
        'star': 'star',
        'star_diamond': 'star',
        'cross': 'cross',
        'cross_fill': 'cross',
        'cross2': 'x',
        'x': 'x',
      }.entries) {
        final doc = qml.QmlDocument(
          renderer: qml.QmlRenderer(
            type: qml.QmlRendererType.singleSymbol,
            symbols: {
              '0': qml.QmlSymbol(
                type: qml.QmlSymbolType.marker,
                layers: [
                  qml.QmlSymbolLayer(
                    type: qml.QmlSymbolLayerType.simpleMarker,
                    className: 'SimpleMarker',
                    properties: {'name': entry.key, 'color': '0,0,0,255', 'size': '8'},
                  ),
                ],
              ),
            },
          ),
        );
        final result = await parser.readStyle(doc);
        final style = (result as ms.ReadStyleSuccess).output;
        final mark = style.rules.first.symbolizers.first as ms.MarkSymbolizer;
        expect(mark.wellKnownName, entry.value, reason: 'QGIS ${entry.key}');
      }
    });

    test('comparison operators in filter parsing', () async {
      for (final entry in {
        'val >= 10': ms.ComparisonOperator.gte,
        'val <= 10': ms.ComparisonOperator.lte,
        'val > 10': ms.ComparisonOperator.gt,
        'val < 10': ms.ComparisonOperator.lt,
        'val != 10': ms.ComparisonOperator.neq,
      }.entries) {
        final doc = qml.QmlDocument(
          renderer: qml.QmlRenderer(
            type: qml.QmlRendererType.ruleRenderer,
            symbols: {
              '0': const qml.QmlSymbol(
                type: qml.QmlSymbolType.fill,
                layers: [
                  qml.QmlSymbolLayer(
                    type: qml.QmlSymbolLayerType.simpleFill,
                    className: 'SimpleFill',
                    properties: {'color': '0,0,0,255'},
                  ),
                ],
              ),
            },
            rules: [
              qml.QmlRule(key: 'r', symbolKey: '0', filter: entry.key),
            ],
          ),
        );
        final result = await parser.readStyle(doc);
        final style = (result as ms.ReadStyleSuccess).output;
        final f = style.rules.first.filter as ms.ComparisonFilter;
        expect(f.operator, entry.value, reason: entry.key);
      }
    });

    test('multi-layer symbol produces multiple symbolizers', () async {
      final doc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.singleSymbol,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.marker,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleMarker,
                  className: 'SimpleMarker',
                  properties: {'color': '255,0,0,255', 'name': 'square', 'size': '20'},
                ),
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleMarker,
                  className: 'SimpleMarker',
                  properties: {'color': '0,0,255,255', 'name': 'circle', 'size': '8'},
                ),
              ],
            ),
          },
        ),
      );

      final result = await parser.readStyle(doc);
      final style = (result as ms.ReadStyleSuccess).output;

      expect(style.rules.first.symbolizers, hasLength(2));
      final mark0 = style.rules.first.symbolizers[0] as ms.MarkSymbolizer;
      final mark1 = style.rules.first.symbolizers[1] as ms.MarkSymbolizer;
      expect(mark0.wellKnownName, 'square');
      expect(mark1.wellKnownName, 'circle');
    });
  });

  // ---------------------------------------------------------------------------
  // mapstyler_style → QML (Write direction)
  // ---------------------------------------------------------------------------
  group('mapstyler_style → QML', () {
    test('single Fill rule → singleSymbol', () async {
      final style = ms.Style(
        name: 'Test',
        rules: [
          ms.Rule(
            symbolizers: [
              ms.FillSymbolizer(
                color: ms.LiteralExpression('#ff0000'),
                outlineColor: ms.LiteralExpression('#000000'),
                outlineWidth: ms.LiteralExpression(0.5),
              ),
            ],
          ),
        ],
      );

      final result = await parser.writeStyle(style);
      expect(result, isA<ms.WriteStyleSuccess<qml.QmlDocument>>());
      final doc =
          (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;

      expect(doc.renderer.type, qml.QmlRendererType.singleSymbol);
      expect(doc.renderer.symbols, hasLength(1));

      final layer = doc.renderer.symbols['0']!.layers.first;
      expect(layer.className, 'SimpleFill');
      expect(layer.properties['color'], '255,0,0,255');
      expect(layer.properties['outline_color'], '0,0,0,255');
      expect(layer.properties['outline_width'], '0.5');
    });

    test('multiple rules → RuleRenderer', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            name: 'Rule A',
            filter: ms.ComparisonFilter(
              operator: ms.ComparisonOperator.eq,
              property: ms.LiteralExpression('type'),
              value: ms.LiteralExpression<Object>('A'),
            ),
            symbolizers: [
              ms.MarkSymbolizer(
                wellKnownName: 'circle',
                radius: ms.LiteralExpression(5.0),
                color: ms.LiteralExpression('#ff0000'),
              ),
            ],
          ),
          ms.Rule(
            name: 'Rule B',
            symbolizers: [
              ms.MarkSymbolizer(
                wellKnownName: 'square',
                radius: ms.LiteralExpression(8.0),
                color: ms.LiteralExpression('#0000ff'),
              ),
            ],
          ),
        ],
      );

      final result = await parser.writeStyle(style);
      final doc =
          (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;

      expect(doc.renderer.type, qml.QmlRendererType.ruleRenderer);
      expect(doc.renderer.rules, hasLength(2));
      expect(doc.renderer.symbols, hasLength(2));

      expect(doc.renderer.rules[0].label, 'Rule A');
      expect(doc.renderer.rules[0].filter, "type = 'A'");
      expect(doc.renderer.rules[1].label, 'Rule B');

      // Marker: radius 5 → size 10 (diameter)
      final markerProps = doc.renderer.symbols['0']!.layers.first.properties;
      expect(markerProps['name'], 'circle');
      expect(markerProps['size'], '10.0');
      expect(markerProps['color'], '255,0,0,255');
    });

    test('Line symbolizer round-trip', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            symbolizers: [
              ms.LineSymbolizer(
                color: ms.LiteralExpression('#ff00ff'),
                width: ms.LiteralExpression(3.0),
                cap: 'round',
                join: 'bevel',
                dasharray: [10.0, 5.0],
              ),
            ],
          ),
        ],
      );

      final result = await parser.writeStyle(style);
      final doc =
          (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;
      final layer = doc.renderer.symbols['0']!.layers.first;

      expect(layer.className, 'SimpleLine');
      expect(layer.properties['line_color'], '255,0,255,255');
      expect(layer.properties['line_width'], '3.0');
      expect(layer.properties['capstyle'], 'round');
      expect(layer.properties['joinstyle'], 'bevel');
      expect(layer.properties['customdash'], '10.0;5.0');
      expect(layer.properties['use_custom_dash'], '1');
    });

    test('IconSymbolizer → SvgMarker', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            symbolizers: [
              ms.IconSymbolizer(
                image: ms.LiteralExpression('/icons/tree.svg'),
                size: ms.LiteralExpression(16.0),
                rotate: ms.LiteralExpression(45.0),
              ),
            ],
          ),
        ],
      );

      final result = await parser.writeStyle(style);
      final doc =
          (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;
      final layer = doc.renderer.symbols['0']!.layers.first;

      expect(layer.className, 'SvgMarker');
      expect(layer.properties['name'], '/icons/tree.svg');
      expect(layer.properties['size'], '16.0');
      expect(layer.properties['angle'], '45.0');
    });

    test('TextSymbolizer produces warning', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            symbolizers: [
              ms.TextSymbolizer(label: ms.LiteralExpression('test')),
            ],
          ),
        ],
      );

      final result = await parser.writeStyle(style);
      final success = result as ms.WriteStyleSuccess<qml.QmlDocument>;
      expect(
        success.warnings,
        contains(contains('TextSymbolizer not supported')),
      );
    });

    test('RasterSymbolizer produces warning', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            symbolizers: [
              ms.RasterSymbolizer(opacity: ms.LiteralExpression(0.5)),
            ],
          ),
        ],
      );
      final result = await parser.writeStyle(style);
      final success = result as ms.WriteStyleSuccess<qml.QmlDocument>;
      expect(
        success.warnings,
        contains(contains('RasterSymbolizer not supported')),
      );
    });

    test('MarkSymbolizer with all fields', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            symbolizers: [
              ms.MarkSymbolizer(
                wellKnownName: 'diamond',
                radius: ms.LiteralExpression(6.0),
                color: ms.LiteralExpression('#ff0000'),
                opacity: ms.LiteralExpression(0.8),
                strokeColor: ms.LiteralExpression('#333333'),
                strokeWidth: ms.LiteralExpression(1.5),
                rotate: ms.LiteralExpression(30.0),
              ),
            ],
          ),
        ],
      );
      final result = await parser.writeStyle(style);
      final doc =
          (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;
      final props = doc.renderer.symbols['0']!.layers.first.properties;
      expect(props['name'], 'diamond');
      expect(props['outline_color'], '51,51,51,255');
      expect(props['outline_width'], '1.5');
      expect(props['angle'], '30.0');
    });

    test('shape mapping covers all WKN values', () async {
      for (final wkn in ['diamond', 'triangle', 'star', 'cross', 'x']) {
        final style = ms.Style(
          rules: [
            ms.Rule(
              symbolizers: [
                ms.MarkSymbolizer(
                  wellKnownName: wkn,
                  color: ms.LiteralExpression('#000000'),
                ),
              ],
            ),
          ],
        );
        final result = await parser.writeStyle(style);
        final doc =
            (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;
        final name = doc.renderer.symbols['0']!.layers.first.properties['name'];
        expect(name, isNotNull, reason: wkn);
      }
    });

    test('CombinationFilter and NegationFilter in write', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            name: 'Combined',
            filter: ms.CombinationFilter(
              operator: ms.CombinationOperator.and,
              filters: [
                ms.ComparisonFilter(
                  operator: ms.ComparisonOperator.gte,
                  property: ms.LiteralExpression('pop'),
                  value: ms.LiteralExpression<Object>(1000),
                ),
                ms.ComparisonFilter(
                  operator: ms.ComparisonOperator.lte,
                  property: ms.LiteralExpression('pop'),
                  value: ms.LiteralExpression<Object>(5000),
                ),
              ],
            ),
            symbolizers: [
              ms.FillSymbolizer(color: ms.LiteralExpression('#ff0000')),
            ],
          ),
          ms.Rule(
            name: 'Negated',
            filter: ms.NegationFilter(
              filter: ms.ComparisonFilter(
                operator: ms.ComparisonOperator.eq,
                property: ms.LiteralExpression('hidden'),
                value: ms.LiteralExpression<Object>(1),
              ),
            ),
            symbolizers: [
              ms.FillSymbolizer(color: ms.LiteralExpression('#00ff00')),
            ],
          ),
        ],
      );
      final result = await parser.writeStyle(style);
      final doc =
          (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;

      expect(doc.renderer.rules[0].filter, 'pop >= 1000 AND pop <= 5000');
      expect(doc.renderer.rules[1].filter, "NOT (hidden = 1)");
    });

    test('FunctionExpression in filter property', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            name: 'FuncExpr',
            filter: ms.ComparisonFilter(
              operator: ms.ComparisonOperator.eq,
              property: ms.FunctionExpression(ms.PropertyGet('name')),
              value: ms.FunctionExpression<Object>(
                ms.ArgsFunction(name: 'custom'),
              ),
            ),
            symbolizers: [
              ms.FillSymbolizer(color: ms.LiteralExpression('#000000')),
            ],
          ),
        ],
      );
      final result = await parser.writeStyle(style);
      final doc =
          (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;

      expect(doc.renderer.rules.first.filter, contains('name'));
      expect(doc.renderer.rules.first.filter, contains('custom'));
    });

    test('filter with comparison operators', () async {
      final style = ms.Style(
        rules: [
          ms.Rule(
            name: 'Greater',
            filter: ms.ComparisonFilter(
              operator: ms.ComparisonOperator.gt,
              property: ms.LiteralExpression('value'),
              value: ms.LiteralExpression<Object>(100),
            ),
            symbolizers: [
              ms.FillSymbolizer(color: ms.LiteralExpression('#ff0000')),
            ],
          ),
        ],
      );

      final result = await parser.writeStyle(style);
      final doc =
          (result as ms.WriteStyleSuccess<qml.QmlDocument>).output;

      expect(doc.renderer.rules.first.filter, 'value > 100');
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip: QML → mapstyler → QML → mapstyler
  // ---------------------------------------------------------------------------
  group('Round-trip', () {
    test('singleSymbol Fill survives round-trip', () async {
      final originalDoc = qml.QmlDocument(
        renderer: qml.QmlRenderer(
          type: qml.QmlRendererType.singleSymbol,
          symbols: {
            '0': qml.QmlSymbol(
              type: qml.QmlSymbolType.fill,
              layers: [
                qml.QmlSymbolLayer(
                  type: qml.QmlSymbolLayerType.simpleFill,
                  className: 'SimpleFill',
                  properties: {
                    'color': '200,100,50,255',
                    'outline_color': '0,0,0,255',
                    'outline_width': '1',
                  },
                ),
              ],
            ),
          },
        ),
      );

      // QML → mapstyler
      final readResult = await parser.readStyle(originalDoc);
      final style = (readResult as ms.ReadStyleSuccess).output;

      // mapstyler → QML
      final writeResult = await parser.writeStyle(style);
      final roundTripDoc =
          (writeResult as ms.WriteStyleSuccess<qml.QmlDocument>).output;

      // QML → mapstyler again
      final readResult2 = await parser.readStyle(roundTripDoc);
      final style2 = (readResult2 as ms.ReadStyleSuccess).output;

      // Compare
      final fill1 = style.rules.first.symbolizers.first as ms.FillSymbolizer;
      final fill2 = style2.rules.first.symbolizers.first as ms.FillSymbolizer;
      expect(
        (fill2.color as ms.LiteralExpression<String>).value,
        (fill1.color as ms.LiteralExpression<String>).value,
      );
      expect(
        (fill2.outlineWidth as ms.LiteralExpression<double>).value,
        (fill1.outlineWidth as ms.LiteralExpression<double>).value,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // QmlStyleParser interface
  // ---------------------------------------------------------------------------
  group('QmlStyleParser', () {
    test('title is QML', () {
      expect(parser.title, 'QML');
    });
  });
}
