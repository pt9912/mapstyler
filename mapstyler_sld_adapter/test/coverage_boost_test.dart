/// Additional tests to reach ≥95% line coverage.
/// Covers write-direction paths, multi-geometry fallbacks, all spatial
/// operators, composite expression round-trips, and edge cases.
import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:gml4dart/gml4dart.dart' as gml;
import 'package:mapstyler_sld_adapter/src/mapstyler_to_sld.dart';
import 'package:mapstyler_sld_adapter/src/sld_to_mapstyler.dart';
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // Write-direction: all comparison operators
  // -----------------------------------------------------------------------
  group('Write: all comparison operators', () {
    for (final entry in [
      (ms.ComparisonOperator.eq, sld.PropertyIsEqualTo),
      (ms.ComparisonOperator.neq, sld.PropertyIsNotEqualTo),
      (ms.ComparisonOperator.lt, sld.PropertyIsLessThan),
      (ms.ComparisonOperator.gt, sld.PropertyIsGreaterThan),
      (ms.ComparisonOperator.lte, sld.PropertyIsLessThanOrEqualTo),
      (ms.ComparisonOperator.gte, sld.PropertyIsGreaterThanOrEqualTo),
    ]) {
      test('${entry.$1} writes correct SLD type', () {
        final style = ms.Style(rules: [
          ms.Rule(
            filter: ms.ComparisonFilter(
              operator: entry.$1,
              property: const ms.LiteralExpression('field'),
              value: const ms.LiteralExpression(42),
            ),
          ),
        ]);
        final result = convertStyle(style) as ms.WriteStyleSuccess;
        final sldFilter = result.output.layers.first.styles.first
            .featureTypeStyles.first.rules.first.filter;
        expect(sldFilter.runtimeType, entry.$2);
      });
    }
  });

  // -----------------------------------------------------------------------
  // Write-direction: all spatial operators
  // -----------------------------------------------------------------------
  group('Write: all spatial operators', () {
    for (final op in ms.SpatialOperator.values) {
      test('${op.name} writes correct SLD type', () {
        final style = ms.Style(rules: [
          ms.Rule(
            filter: ms.SpatialFilter(
              operator: op,
              geometry: op == ms.SpatialOperator.bbox
                  ? const ms.EnvelopeGeometry(
                      minX: 0, minY: 0, maxX: 1, maxY: 1)
                  : const ms.PointGeometry(1, 2),
            ),
          ),
        ]);
        final result = convertStyle(style) as ms.WriteStyleSuccess;
        final sldFilter = result.output.layers.first.styles.first
            .featureTypeStyles.first.rules.first.filter;
        expect(sldFilter, isA<sld.SpatialFilter>());
      });
    }
  });

  // -----------------------------------------------------------------------
  // Write-direction: distance filters (DWithin + Beyond)
  // -----------------------------------------------------------------------
  group('Write: distance filters', () {
    test('DWithin writes correctly', () {
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.DistanceFilter(
            operator: ms.DistanceOperator.dWithin,
            geometry: ms.PointGeometry(8, 47),
            distance: 500,
            units: 'm',
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final sldFilter = result.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first.filter;
      expect(sldFilter, isA<sld.DWithin>());
      final dw = sldFilter as sld.DWithin;
      expect(dw.distance, 500);
      expect(dw.units, 'm');
    });

    test('Beyond writes correctly', () {
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.DistanceFilter(
            operator: ms.DistanceOperator.beyond,
            geometry: ms.PointGeometry(8, 47),
            distance: 1000,
            units: 'km',
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final sldFilter = result.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first.filter;
      expect(sldFilter, isA<sld.Beyond>());
    });
  });

  // -----------------------------------------------------------------------
  // Write-direction: geometry types
  // -----------------------------------------------------------------------
  group('Write: geometry round-trip', () {
    test('EnvelopeGeometry → GmlEnvelope', () {
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.SpatialFilter(
            operator: ms.SpatialOperator.bbox,
            geometry: ms.EnvelopeGeometry(
              minX: 8, minY: 47, maxX: 9, maxY: 48),
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final readBack =
          convertDocument(result.output) as ms.ReadStyleSuccess;
      final sf = readBack.output.rules.first.filter as ms.SpatialFilter;
      final env = sf.geometry as ms.EnvelopeGeometry;
      expect(env.minX, 8);
      expect(env.maxY, 48);
    });

    test('LineStringGeometry round-trip', () {
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.SpatialFilter(
            operator: ms.SpatialOperator.intersects,
            geometry: ms.LineStringGeometry([(0.0, 0.0), (1.0, 1.0)]),
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final readBack =
          convertDocument(result.output) as ms.ReadStyleSuccess;
      final sf = readBack.output.rules.first.filter as ms.SpatialFilter;
      expect(sf.geometry, isA<ms.LineStringGeometry>());
      final ls = sf.geometry as ms.LineStringGeometry;
      expect(ls.coordinates, hasLength(2));
    });

    test('PolygonGeometry with holes round-trip', () {
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.SpatialFilter(
            operator: ms.SpatialOperator.within,
            geometry: ms.PolygonGeometry([
              [(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 0.0)],
              [(2.0, 2.0), (3.0, 2.0), (3.0, 3.0), (2.0, 2.0)],
            ]),
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final readBack =
          convertDocument(result.output) as ms.ReadStyleSuccess;
      final sf = readBack.output.rules.first.filter as ms.SpatialFilter;
      final pg = sf.geometry as ms.PolygonGeometry;
      expect(pg.rings, hasLength(2)); // exterior + 1 hole
    });
  });

  // -----------------------------------------------------------------------
  // Read-direction: multi-geometry fallback (EDGE-1)
  // -----------------------------------------------------------------------
  group('Read: multi-geometry fallback', () {
    test('GmlMultiPoint reduced to first point', () {
      final doc = _docWithRule(sld.Rule(
        filter: sld.Intersects(
          geometry: gml.GmlMultiPoint(points: [
            gml.GmlPoint(coordinate: const gml.GmlCoordinate(1, 2)),
            gml.GmlPoint(coordinate: const gml.GmlCoordinate(3, 4)),
          ]),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final sf = result.output.rules.first.filter as ms.SpatialFilter;
      expect(sf.geometry, const ms.PointGeometry(1, 2));
      expect(result.warnings, anyElement(contains('MultiPoint')));
    });

    test('GmlMultiLineString reduced to first linestring', () {
      final doc = _docWithRule(sld.Rule(
        filter: sld.Intersects(
          geometry: gml.GmlMultiLineString(lineStrings: [
            gml.GmlLineString(coordinates: const [
              gml.GmlCoordinate(0, 0),
              gml.GmlCoordinate(1, 1),
            ]),
          ]),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final sf = result.output.rules.first.filter as ms.SpatialFilter;
      expect(sf.geometry, isA<ms.LineStringGeometry>());
      expect(result.warnings, anyElement(contains('MultiLineString')));
    });

    test('GmlMultiPolygon reduced to first polygon', () {
      final doc = _docWithRule(sld.Rule(
        filter: sld.Intersects(
          geometry: gml.GmlMultiPolygon(polygons: [
            gml.GmlPolygon(
              exterior: gml.GmlLinearRing(coordinates: const [
                gml.GmlCoordinate(0, 0),
                gml.GmlCoordinate(1, 0),
                gml.GmlCoordinate(1, 1),
                gml.GmlCoordinate(0, 0),
              ]),
              interiors: [
                gml.GmlLinearRing(coordinates: const [
                  gml.GmlCoordinate(0.1, 0.1),
                  gml.GmlCoordinate(0.2, 0.1),
                  gml.GmlCoordinate(0.2, 0.2),
                  gml.GmlCoordinate(0.1, 0.1),
                ]),
              ],
            ),
          ]),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final sf = result.output.rules.first.filter as ms.SpatialFilter;
      expect(sf.geometry, isA<ms.PolygonGeometry>());
      final pg = sf.geometry as ms.PolygonGeometry;
      expect(pg.rings, hasLength(2)); // exterior + hole
      expect(result.warnings, anyElement(contains('MultiPolygon')));
    });

    test('GmlBox converted to EnvelopeGeometry', () {
      final doc = _docWithRule(sld.Rule(
        filter: sld.Intersects(
          geometry: gml.GmlBox(
            lowerCorner: const gml.GmlCoordinate(5, 6),
            upperCorner: const gml.GmlCoordinate(7, 8),
          ),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final sf = result.output.rules.first.filter as ms.SpatialFilter;
      expect(sf.geometry, isA<ms.EnvelopeGeometry>());
      final env = sf.geometry as ms.EnvelopeGeometry;
      expect(env.minX, 5);
      expect(env.maxY, 8);
    });

    test('unsupported GmlCurve falls back to PointGeometry(0,0)', () {
      final doc = _docWithRule(sld.Rule(
        filter: sld.Intersects(
          geometry: gml.GmlCurve(coordinates: const [
            gml.GmlCoordinate(1, 2),
            gml.GmlCoordinate(3, 4),
          ]),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final sf = result.output.rules.first.filter as ms.SpatialFilter;
      expect(sf.geometry, const ms.PointGeometry(0, 0));
      expect(result.warnings, anyElement(contains('Unsupported geometry')));
    });
  });

  // -----------------------------------------------------------------------
  // Write-direction: composite expression round-trips (WRITE-4)
  // -----------------------------------------------------------------------
  group('Write: composite expression round-trips', () {
    test('StepFunction → Categorize → StepFunction', () {
      const step = ms.FunctionExpression<Object>(ms.StepFunction(
        input: ms.FunctionExpression(ms.PropertyGet('pop')),
        defaultValue: ms.LiteralExpression('low'),
        stops: [
          ms.StepParameter(
            boundary: ms.LiteralExpression(1000),
            value: ms.LiteralExpression('medium'),
          ),
          ms.StepParameter(
            boundary: ms.LiteralExpression(10000),
            value: ms.LiteralExpression('high'),
          ),
        ],
      ));
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.ComparisonFilter(
            operator: ms.ComparisonOperator.eq,
            property: ms.LiteralExpression('cat'),
            value: step,
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final sldFilter = result.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first.filter as sld.PropertyIsEqualTo;
      expect(sldFilter.expression2, isA<sld.Categorize>());
      final cat = sldFilter.expression2 as sld.Categorize;
      expect(cat.thresholds, hasLength(2));
      expect(cat.values, hasLength(3));
    });

    test('InterpolateFunction → Interpolate → InterpolateFunction', () {
      const interp = ms.FunctionExpression<Object>(ms.InterpolateFunction(
        mode: ['linear'],
        input: ms.FunctionExpression(ms.PropertyGet('temp')),
        stops: [
          ms.InterpolateParameter(
            stop: ms.LiteralExpression(0),
            value: ms.LiteralExpression('#0000ff'),
          ),
          ms.InterpolateParameter(
            stop: ms.LiteralExpression(30),
            value: ms.LiteralExpression('#ff0000'),
          ),
        ],
      ));
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.ComparisonFilter(
            operator: ms.ComparisonOperator.eq,
            property: ms.LiteralExpression('color'),
            value: interp,
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final sldFilter = result.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first.filter as sld.PropertyIsEqualTo;
      expect(sldFilter.expression2, isA<sld.Interpolate>());
      final si = sldFilter.expression2 as sld.Interpolate;
      expect(si.mode, sld.InterpolateMode.linear);
      expect(si.dataPoints, hasLength(2));
    });

    test('CaseFunction → Recode → CaseFunction', () {
      const caseFunc = ms.FunctionExpression<Object>(ms.CaseFunction(
        cases: [
          ms.CaseParameter(
            condition: ms.FunctionExpression(ms.ArgsFunction(
              name: 'equalTo',
              args: [
                ms.FunctionExpression(ms.PropertyGet('type')),
                ms.LiteralExpression('A'),
              ],
            )),
            value: ms.LiteralExpression('#ff0000'),
          ),
        ],
        fallback: ms.LiteralExpression('#cccccc'),
      ));
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.ComparisonFilter(
            operator: ms.ComparisonOperator.eq,
            property: ms.LiteralExpression('result'),
            value: caseFunc,
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final sldFilter = result.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first.filter as sld.PropertyIsEqualTo;
      expect(sldFilter.expression2, isA<sld.Recode>());
      final recode = sldFilter.expression2 as sld.Recode;
      expect(recode.mappings, hasLength(1));
    });

    test('strConcat value expression writes Concatenate', () {
      const concat = ms.FunctionExpression<Object>(ms.ArgsFunction(
        name: 'strConcat',
        args: [
          ms.LiteralExpression('Hello '),
          ms.FunctionExpression(ms.PropertyGet('name')),
        ],
      ));
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.ComparisonFilter(
            operator: ms.ComparisonOperator.eq,
            property: ms.LiteralExpression('label'),
            value: concat,
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final sldFilter = result.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first.filter as sld.PropertyIsEqualTo;
      expect(sldFilter.expression2, isA<sld.Concatenate>());
    });

    test('numberFormat value expression writes FormatNumber', () {
      const fmt = ms.FunctionExpression<Object>(ms.ArgsFunction(
        name: 'numberFormat',
        args: [
          ms.FunctionExpression(ms.PropertyGet('value')),
          ms.LiteralExpression('#.##'),
        ],
      ));
      const style = ms.Style(rules: [
        ms.Rule(
          filter: ms.ComparisonFilter(
            operator: ms.ComparisonOperator.eq,
            property: ms.LiteralExpression('display'),
            value: fmt,
          ),
        ),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final sldFilter = result.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first.filter as sld.PropertyIsEqualTo;
      expect(sldFilter.expression2, isA<sld.FormatNumber>());
    });
  });

  // -----------------------------------------------------------------------
  // Write-direction: RasterSymbolizer with contrastEnhancement
  // -----------------------------------------------------------------------
  group('Write: RasterSymbolizer contrastEnhancement', () {
    test('writes and reads back contrastEnhancement', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.RasterSymbolizer(
            contrastEnhancement: ms.ContrastEnhancement(
              enhancementType: 'histogram',
              gammaValue: 0.8,
            ),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final readBack =
          convertDocument(result.output) as ms.ReadStyleSuccess;
      final raster = readBack.output.rules.first.symbolizers.first
          as ms.RasterSymbolizer;
      expect(raster.contrastEnhancement?.enhancementType, 'histogram');
      expect(raster.contrastEnhancement?.gammaValue, 0.8);
    });

    test('writes channelSelection with contrastEnhancement', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.RasterSymbolizer(
            channelSelection: ms.ChannelSelection(
              redChannel: ms.Channel(
                sourceChannelName: '1',
                contrastEnhancement: ms.ContrastEnhancement(
                  enhancementType: 'normalize',
                ),
              ),
            ),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final readBack =
          convertDocument(result.output) as ms.ReadStyleSuccess;
      final raster = readBack.output.rules.first.symbolizers.first
          as ms.RasterSymbolizer;
      expect(raster.channelSelection?.redChannel?.contrastEnhancement
          ?.enhancementType, 'normalize');
    });
  });

  // -----------------------------------------------------------------------
  // Write-direction: TextSymbolizer strConcat label
  // -----------------------------------------------------------------------
  group('Write: TextSymbolizer strConcat label', () {
    test('strConcat label writes as Concatenate', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.TextSymbolizer(
            label: ms.FunctionExpression(ms.ArgsFunction(
              name: 'strConcat',
              args: [
                ms.FunctionExpression(ms.PropertyGet('first')),
                ms.LiteralExpression(' '),
                ms.FunctionExpression(ms.PropertyGet('last')),
              ],
            )),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      final sldTs = result.output.layers.first.styles.first
          .featureTypeStyles.first.rules.first.textSymbolizer!;
      expect(sldTs.label, isA<sld.Concatenate>());
      final cat = sldTs.label as sld.Concatenate;
      expect(cat.expressions, hasLength(3));
    });

    test('unsupported label expression emits warning', () {
      const style = ms.Style(rules: [
        ms.Rule(symbolizers: [
          ms.TextSymbolizer(
            label: ms.FunctionExpression(ms.ArgsFunction(
              name: 'someUnknownFunc',
              args: [],
            )),
          ),
        ]),
      ]);
      final result = convertStyle(style) as ms.WriteStyleSuccess;
      expect(result.warnings, anyElement(contains('Unsupported label')));
    });
  });

  // -----------------------------------------------------------------------
  // Read-direction: GmlLineString and GmlPolygon via filter
  // -----------------------------------------------------------------------
  group('Read: geometry types in spatial filters', () {
    test('GmlLineString converts to LineStringGeometry', () {
      final doc = _docWithRule(sld.Rule(
        filter: sld.Intersects(
          geometry: gml.GmlLineString(coordinates: const [
            gml.GmlCoordinate(0, 0),
            gml.GmlCoordinate(1, 1),
            gml.GmlCoordinate(2, 0),
          ]),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final sf = result.output.rules.first.filter as ms.SpatialFilter;
      expect(sf.geometry, isA<ms.LineStringGeometry>());
      final ls = sf.geometry as ms.LineStringGeometry;
      expect(ls.coordinates, hasLength(3));
    });
  });

  // -----------------------------------------------------------------------
  // Read-direction: FormatNumber label expression
  // -----------------------------------------------------------------------
  group('Read: FormatNumber label', () {
    test('FormatNumber label converts to numberFormat FunctionExpression', () {
      final doc = _docWithRule(const sld.Rule(
        textSymbolizer: sld.TextSymbolizer(
          label: sld.FormatNumber(
            numericValue: sld.PropertyName('value'),
            pattern: '#.##',
          ),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final sym =
          result.output.rules.first.symbolizers.first as ms.TextSymbolizer;
      expect(sym.label, isA<ms.FunctionExpression<String>>());
      final func =
          (sym.label as ms.FunctionExpression<String>).function as ms.ArgsFunction;
      expect(func.name, 'numberFormat');
    });
  });

  // -----------------------------------------------------------------------
  // Read-direction: Concatenate and FormatNumber as value expressions
  // -----------------------------------------------------------------------
  group('Read: composite value expressions', () {
    test('Concatenate as filter value', () {
      final doc = _docWithRule(const sld.Rule(
        filter: sld.PropertyIsEqualTo(
          expression1: sld.PropertyName('label'),
          expression2: sld.Concatenate(expressions: [
            sld.PropertyName('first'),
            sld.Literal(' '),
            sld.PropertyName('last'),
          ]),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final cf = result.output.rules.first.filter as ms.ComparisonFilter;
      expect(cf.value, isA<ms.FunctionExpression<Object>>());
      final func = (cf.value as ms.FunctionExpression<Object>).function
          as ms.ArgsFunction;
      expect(func.name, 'strConcat');
      expect(func.args, hasLength(3));
    });

    test('FormatNumber as filter value', () {
      final doc = _docWithRule(const sld.Rule(
        filter: sld.PropertyIsEqualTo(
          expression1: sld.PropertyName('display'),
          expression2: sld.FormatNumber(
            numericValue: sld.PropertyName('value'),
            pattern: '0.00',
          ),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final cf = result.output.rules.first.filter as ms.ComparisonFilter;
      final func = (cf.value as ms.FunctionExpression<Object>).function
          as ms.ArgsFunction;
      expect(func.name, 'numberFormat');
    });
  });

  // -----------------------------------------------------------------------
  // Read-direction: PropertyName as value in filter (dynamic lookup)
  // -----------------------------------------------------------------------
  group('Read: PropertyName as value', () {
    test('PropertyName value becomes FunctionExpression(PropertyGet)', () {
      final doc = _docWithRule(const sld.Rule(
        filter: sld.PropertyIsEqualTo(
          expression1: sld.PropertyName('field_a'),
          expression2: sld.PropertyName('field_b'),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final cf = result.output.rules.first.filter as ms.ComparisonFilter;
      expect(cf.value,
          const ms.FunctionExpression<Object>(ms.PropertyGet('field_b')));
    });
  });

  // -----------------------------------------------------------------------
  // Read-direction: Mark fill alpha → opacity
  // -----------------------------------------------------------------------
  group('Read: Mark fill alpha extraction', () {
    test('semi-transparent fill color extracts alpha as opacity', () {
      final doc = _docWithRule(const sld.Rule(
        pointSymbolizer: sld.PointSymbolizer(
          graphic: sld.Graphic(
            mark: sld.Mark(
              wellKnownName: 'square',
              fill: sld.Fill(colorArgb: 0x80FF0000), // alpha=0x80
            ),
          ),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final mark =
          result.output.rules.first.symbolizers.first as ms.MarkSymbolizer;
      // opacity comes from alpha channel since graphic.opacity is null
      expect(mark.opacity, isA<ms.LiteralExpression<double>>());
      final op = (mark.opacity as ms.LiteralExpression<double>).value;
      expect(op, closeTo(0.502, 0.005));
    });

    test('fill.opacity overrides alpha opacity', () {
      final doc = _docWithRule(const sld.Rule(
        pointSymbolizer: sld.PointSymbolizer(
          graphic: sld.Graphic(
            mark: sld.Mark(
              wellKnownName: 'circle',
              fill: sld.Fill(colorArgb: 0x80FF0000, opacity: 0.3),
            ),
          ),
        ),
      ));
      final result = convertDocument(doc) as ms.ReadStyleSuccess;
      final mark =
          result.output.rules.first.symbolizers.first as ms.MarkSymbolizer;
      expect(mark.opacity, const ms.LiteralExpression(0.3));
    });
  });
}

sld.SldDocument _docWithRule(sld.Rule rule) => sld.SldDocument(
      layers: [
        sld.SldLayer(
          styles: [
            sld.UserStyle(
              featureTypeStyles: [
                sld.FeatureTypeStyle(rules: [rule]),
              ],
            ),
          ],
        ),
      ],
    );
