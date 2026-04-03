import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:flutter_mapstyler/src/geometry_ops.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

void main() {
  group('geometry_ops', () {
    test('geometryEnvelope covers all geometry types', () {
      expect(
        geometryEnvelope(const PointGeometry(1, 2)),
        const EnvelopeGeometry(minX: 1, minY: 2, maxX: 1, maxY: 2),
      );
      expect(
        geometryEnvelope(
          const LineStringGeometry([(0, 0), (5, 2), (2, 7)]),
        ),
        const EnvelopeGeometry(minX: 0, minY: 0, maxX: 5, maxY: 7),
      );
      expect(
        geometryEnvelope(
          const PolygonGeometry([
            [(1, 1), (4, 1), (4, 3), (1, 1)],
          ]),
        ),
        const EnvelopeGeometry(minX: 1, minY: 1, maxX: 4, maxY: 3),
      );
    });

    test('geometryAsPolygon converts envelope and line geometries', () {
      final envelopePolygon = geometryAsPolygon(
        const EnvelopeGeometry(minX: 0, minY: 0, maxX: 2, maxY: 1),
      );
      expect(envelopePolygon.rings.first, [
        (0.0, 0.0),
        (2.0, 0.0),
        (2.0, 1.0),
        (0.0, 1.0),
        (0.0, 0.0),
      ]);

      final linePolygon = geometryAsPolygon(
        const LineStringGeometry([(0, 0), (1, 1)]),
      );
      expect(linePolygon.rings.single, [
        (0.0, 0.0),
        (1.0, 1.0),
      ]);
    });

    test('geometryAsPolygon converts point geometry into a degenerate polygon', () {
      final pointPolygon = geometryAsPolygon(const PointGeometry(1, 2));
      expect(pointPolygon.rings.single, [
        (1.0, 2.0),
        (1.0, 2.0),
        (1.0, 2.0),
        (1.0, 2.0),
      ]);
    });

    test('intersects and disjoint handle points, lines, and polygons', () {
      const polygon = PolygonGeometry([
        [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
      ]);
      const crossingLine = LineStringGeometry([(-1, 5), (11, 5)]);
      const farLine = LineStringGeometry([(20, 20), (30, 30)]);

      expect(intersectsGeometry(const PointGeometry(5, 5), polygon), isTrue);
      expect(intersectsGeometry(crossingLine, polygon), isTrue);
      expect(disjointGeometry(farLine, polygon), isTrue);
      expect(intersectsGeometry(farLine, polygon), isFalse);
    });

    test('contains and within handle polygon, line, and point combinations', () {
      const polygon = PolygonGeometry([
        [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
      ]);
      const innerPolygon = PolygonGeometry([
        [(2, 2), (4, 2), (4, 4), (2, 2)],
      ]);
      const innerLine = LineStringGeometry([(2, 2), (3, 3), (4, 4)]);
      const outerPoint = PointGeometry(20, 20);

      expect(containsGeometry(polygon, innerPolygon), isTrue);
      expect(containsGeometry(polygon, innerLine), isTrue);
      expect(withinGeometry(innerLine, polygon), isTrue);
      expect(containsGeometry(polygon, outerPoint), isFalse);
    });

    test('containsGeometry covers point, line, and envelope candidates', () {
      expect(
        containsGeometry(
          const PointGeometry(1, 2),
          const PointGeometry(1, 2),
        ),
        isTrue,
      );
      expect(
        containsGeometry(
          const LineStringGeometry([(0, 0), (5, 5)]),
          const PointGeometry(3, 3),
        ),
        isTrue,
      );
      expect(
        containsGeometry(
          const LineStringGeometry([(0, 0), (5, 5)]),
          const LineStringGeometry([(1, 1), (4, 4)]),
        ),
        isTrue,
      );
      expect(
        containsGeometry(
          const EnvelopeGeometry(minX: 0, minY: 0, maxX: 10, maxY: 10),
          const EnvelopeGeometry(minX: 2, minY: 2, maxX: 4, maxY: 4),
        ),
        isTrue,
      );
    });

    test('overlaps touches and crosses differentiate geometry relations', () {
      const a = PolygonGeometry([
        [(0, 0), (5, 0), (5, 5), (0, 5), (0, 0)],
      ]);
      const b = PolygonGeometry([
        [(3, 3), (8, 3), (8, 8), (3, 8), (3, 3)],
      ]);
      const touchingPoint = PointGeometry(5, 2);
      const lineA = LineStringGeometry([(0, 0), (10, 10)]);
      const lineB = LineStringGeometry([(0, 10), (10, 0)]);

      expect(overlapsGeometry(a, b), isTrue);
      expect(touchesGeometry(touchingPoint, a), isFalse);
      expect(crossesGeometry(lineA, lineB), isTrue);
    });

    test('envelope overlaps and boundary touches are handled explicitly', () {
      const envelopeA = EnvelopeGeometry(minX: 0, minY: 0, maxX: 5, maxY: 5);
      const envelopeB = EnvelopeGeometry(minX: 3, minY: 3, maxX: 8, maxY: 8);
      const polygon = PolygonGeometry([
        [(3, 3), (8, 3), (8, 8), (3, 8), (3, 3)],
      ]);
      const square = PolygonGeometry([
        [(0, 0), (6, 0), (6, 6), (0, 6), (0, 0)],
      ]);
      const withHole = PolygonGeometry([
        [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
        [(3, 3), (7, 3), (7, 7), (3, 7), (3, 3)],
      ]);

      expect(overlapsGeometry(envelopeA, envelopeB), isTrue);
      expect(overlapsGeometry(envelopeA, polygon), isTrue);
      expect(
        touchesGeometry(
          const PointGeometry(0, 2),
          const EnvelopeGeometry(minX: 0, minY: 0, maxX: 4, maxY: 4),
        ),
        isFalse,
      );
      expect(
        touchesGeometry(const PointGeometry(0, 2), square),
        isFalse,
      );
      expect(
        pointInGeometry(const PointGeometry(5, 5), withHole),
        isFalse,
      );
    });

    test('touches and crosses cover line and polygon variants', () {
      const lineA = LineStringGeometry([(0, 0), (5, 5)]);
      const lineB = LineStringGeometry([(5, 5), (8, 8)]);
      const polygon = PolygonGeometry([
        [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
      ]);
      const crossingLine = LineStringGeometry([(-1, 5), (5, 5), (11, 5)]);

      expect(touchesGeometry(lineA, lineB), isFalse);
      expect(crossesGeometry(crossingLine, polygon), isTrue);
      expect(crossesGeometry(polygon, crossingLine), isTrue);
      expect(
        intersectsGeometry(polygon, const LineStringGeometry([(-1, 5), (11, 5)])),
        isTrue,
      );
    });

    test('distanceBetweenGeometries handles several geometry combinations', () {
      expect(
        distanceBetweenGeometries(
          const PointGeometry(0, 0),
          const PointGeometry(3, 4),
        ),
        5,
      );
      expect(
        distanceBetweenGeometries(
          const PointGeometry(0, 0),
          const LineStringGeometry([(5, 0), (5, 5)]),
        ),
        5,
      );
      expect(
        distanceBetweenGeometries(
          const PolygonGeometry([
            [(0, 0), (2, 0), (2, 2), (0, 2), (0, 0)],
          ]),
          const PolygonGeometry([
            [(4, 0), (6, 0), (6, 2), (4, 2), (4, 0)],
          ]),
        ),
        2,
      );
    });

    test('distanceBetweenGeometries covers reverse and degenerate cases', () {
      expect(
        distanceBetweenGeometries(
          const LineStringGeometry([(5, 0), (5, 5)]),
          const PointGeometry(0, 0),
        ),
        5,
      );
      expect(
        distanceBetweenGeometries(
          const PointGeometry(5, 1),
          const EnvelopeGeometry(minX: 0, minY: 0, maxX: 2, maxY: 2),
        ),
        3,
      );
      expect(
        distanceBetweenGeometries(
          const LineStringGeometry([(5, 0), (5, 5)]),
          const LineStringGeometry([(8, 0), (8, 5)]),
        ),
        3,
      );
      expect(
        distanceBetweenGeometries(
          const LineStringGeometry([(5, 1), (6, 1)]),
          const EnvelopeGeometry(minX: 0, minY: 0, maxX: 2, maxY: 2),
        ),
        3,
      );
      expect(
        distanceBetweenGeometries(
          const LineStringGeometry([(5, 1), (6, 1)]),
          const PolygonGeometry([
            [(0, 0), (2, 0), (2, 2), (0, 2), (0, 0)],
          ]),
        ),
        3,
      );
      expect(
        distanceBetweenGeometries(
          const PointGeometry(3, 4),
          const LineStringGeometry([(0, 0), (0, 0)]),
        ),
        5,
      );
    });

    test('pointOnLineAtMidpoint handles empty, singleton, and multi-point', () {
      expect(
        pointOnLineAtMidpoint(const LineStringGeometry([])).latitude,
        0,
      );
      expect(
        pointOnLineAtMidpoint(const LineStringGeometry([])).longitude,
        0,
      );
      expect(
        pointOnLineAtMidpoint(const LineStringGeometry([(1, 2)])).latitude,
        2,
      );
      expect(
        pointOnLineAtMidpoint(const LineStringGeometry([(1, 2)])).longitude,
        1,
      );
      expect(
        pointOnLineAtMidpoint(
          const LineStringGeometry([(0, 0), (10, 0), (10, 10)]),
        ).latitude,
        0,
      );
      expect(
        pointOnLineAtMidpoint(
          const LineStringGeometry([(0, 0), (10, 0), (10, 10)]),
        ).longitude,
        10,
      );
    });

    test('centroidOfPolygon handles normal and degenerate polygons', () {
      final normal = centroidOfPolygon(
        const PolygonGeometry([
          [(0, 0), (4, 0), (4, 4), (0, 4), (0, 0)],
        ]),
      );
      expect(normal.latitude, closeTo(2, 1e-6));
      expect(normal.longitude, closeTo(2, 1e-6));

      final degenerate = centroidOfPolygon(
        const PolygonGeometry([
          [(0, 0), (1, 1), (2, 2), (0, 0)],
        ]),
      );
      expect(degenerate.latitude, 0);
      expect(degenerate.longitude, 0);
    });

    test('pointInGeometry works for polygon and line boundary checks', () {
      expect(
        pointInGeometry(
          const PointGeometry(5, 5),
          const PolygonGeometry([
            [(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
          ]),
        ),
        isTrue,
      );
      expect(
        pointInGeometry(
          const PointGeometry(2, 2),
          const LineStringGeometry([(0, 0), (4, 4)]),
        ),
        isTrue,
      );
    });

    test('pointInGeometry and touches cover envelope and polygon boundaries', () {
      expect(
        intersectsGeometry(
          const PointGeometry(1, 1),
          const EnvelopeGeometry(minX: 0, minY: 0, maxX: 2, maxY: 2),
        ),
        isTrue,
      );
      expect(
        pointInGeometry(
          const PointGeometry(0, 2),
          const PolygonGeometry([
            [(0, 0), (4, 0), (4, 4), (0, 4), (0, 0)],
          ]),
        ),
        isTrue,
      );
    });
  });

  group('color parser', () {
    test('supports short and alpha hex notations', () {
      expect(parseHexColor('#abc'), const Color(0xFFAABBCC));
      expect(parseHexColor('#11223344'), const Color(0x44112233));
    });
  });

  group('evaluateExpression extended', () {
    test('case function returns matching branch or fallback', () {
      final expr = FunctionExpression<String>(
        CaseFunction(
          cases: const [
            CaseParameter(
              condition: LiteralExpression<Object>(false),
              value: LiteralExpression<Object>('first'),
            ),
            CaseParameter(
              condition: LiteralExpression<Object>(true),
              value: LiteralExpression<Object>('second'),
            ),
          ],
          fallback: const LiteralExpression<Object>('fallback'),
        ),
      );
      expect(evaluateExpression(expr, const {}), 'second');
    });

    test('step function handles default and boundaries', () {
      final expr = FunctionExpression<double>(
        StepFunction(
          input: const FunctionExpression<Object>(PropertyGet('zoom')),
          defaultValue: const LiteralExpression<Object>(1.0),
          stops: const [
            StepParameter(
              boundary: LiteralExpression<Object>(5),
              value: LiteralExpression<Object>(2.0),
            ),
            StepParameter(
              boundary: LiteralExpression<Object>(10),
              value: LiteralExpression<Object>(3.0),
            ),
          ],
        ),
      );
      expect(evaluateExpression(expr, const {'zoom': 2}), 1.0);
      expect(evaluateExpression(expr, const {'zoom': 5}), 2.0);
      expect(evaluateExpression(expr, const {'zoom': 12}), 3.0);
    });

    test('interpolate supports numeric and fallback-like values', () {
      final linear = FunctionExpression<double>(
        InterpolateFunction(
          mode: const ['linear'],
          input: const FunctionExpression<Object>(PropertyGet('zoom')),
          stops: const [
            InterpolateParameter(
              stop: LiteralExpression<Object>(0),
              value: LiteralExpression<Object>(1.0),
            ),
            InterpolateParameter(
              stop: LiteralExpression<Object>(10),
              value: LiteralExpression<Object>(3.0),
            ),
          ],
        ),
      );
      expect(evaluateExpression(linear, const {'zoom': 5}), 2.0);

      final exponential = FunctionExpression<double>(
        InterpolateFunction(
          mode: const ['exponential', 2.0],
          input: const FunctionExpression<Object>(PropertyGet('zoom')),
          stops: const [
            InterpolateParameter(
              stop: LiteralExpression<Object>(0),
              value: LiteralExpression<Object>(0.0),
            ),
            InterpolateParameter(
              stop: LiteralExpression<Object>(10),
              value: LiteralExpression<Object>(10.0),
            ),
          ],
        ),
      );
      expect(evaluateExpression(exponential, const {'zoom': 10}), 10.0);

      final stringy = FunctionExpression<String>(
        InterpolateFunction(
          mode: const ['linear'],
          input: const FunctionExpression<Object>(PropertyGet('zoom')),
          stops: const [
            InterpolateParameter(
              stop: LiteralExpression<Object>(0),
              value: LiteralExpression<Object>('low'),
            ),
            InterpolateParameter(
              stop: LiteralExpression<Object>(10),
              value: LiteralExpression<Object>('high'),
            ),
          ],
        ),
      );
      expect(evaluateExpression(stringy, const {'zoom': 2}), 'low');
      expect(evaluateExpression(stringy, const {'zoom': 8}), 'high');
    });

    test('string helpers work', () {
      expect(
        evaluateExpression(
          const FunctionExpression<String>(
            ArgsFunction(
              name: 'strToLowerCase',
              args: [LiteralExpression<Object>('HELLO')],
            ),
          ),
          const {},
        ),
        'hello',
      );
      expect(
        evaluateExpression(
          const FunctionExpression<String>(
            ArgsFunction(
              name: 'strToUpperCase',
              args: [LiteralExpression<Object>('hello')],
            ),
          ),
          const {},
        ),
        'HELLO',
      );
      expect(
        evaluateExpression(
          const FunctionExpression<String>(
            ArgsFunction(
              name: 'strTrim',
              args: [LiteralExpression<Object>('  hi  ')],
            ),
          ),
          const {},
        ),
        'hi',
      );
      expect(
        evaluateExpression(
          const FunctionExpression<int>(
            ArgsFunction(
              name: 'strLength',
              args: [LiteralExpression<Object>('hello')],
            ),
          ),
          const {},
        ),
        5,
      );
    });

    test('extended string and formatting helpers work', () {
      expect(
        evaluateExpression(
          const FunctionExpression<String>(
            ArgsFunction(
              name: 'strSubstring',
              args: [
                LiteralExpression<Object>('cartography'),
                LiteralExpression<Object>(4),
                LiteralExpression<Object>(8),
              ],
            ),
          ),
          const {},
        ),
        'ogra',
      );
      expect(
        evaluateExpression(
          const FunctionExpression<String>(
            ArgsFunction(
              name: 'strReplace',
              args: [
                LiteralExpression<Object>('tile_layer'),
                LiteralExpression<Object>('_'),
                LiteralExpression<Object>('-'),
              ],
            ),
          ),
          const {},
        ),
        'tile-layer',
      );
      expect(
        evaluateExpression(
          const FunctionExpression<int>(
            ArgsFunction(
              name: 'strIndexOf',
              args: [
                LiteralExpression<Object>('renderer'),
                LiteralExpression<Object>('der'),
              ],
            ),
          ),
          const {},
        ),
        3,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'strStartsWith',
              args: [
                LiteralExpression<Object>('feature-id'),
                LiteralExpression<Object>('feature'),
              ],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'strEndsWith',
              args: [
                LiteralExpression<Object>('feature-id'),
                LiteralExpression<Object>('id'),
              ],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'strMatches',
              args: [
                LiteralExpression<Object>('tile-12'),
                LiteralExpression<Object>(r'^tile-\d+$'),
              ],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<String>(
            ArgsFunction(
              name: 'numberFormat',
              args: [
                LiteralExpression<Object>(12.3456),
                LiteralExpression<Object>(2),
              ],
            ),
          ),
          const {},
        ),
        '12.35',
      );
    });

    test('numeric and boolean helpers work', () {
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'subtract',
              args: [LiteralExpression<Object>(10), LiteralExpression<Object>(4)],
            ),
          ),
          const {},
        ),
        6.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'multiply',
              args: [LiteralExpression<Object>(3), LiteralExpression<Object>(4)],
            ),
          ),
          const {},
        ),
        12.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'divide',
              args: [LiteralExpression<Object>(8), LiteralExpression<Object>(2)],
            ),
          ),
          const {},
        ),
        4.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'divide',
              args: [LiteralExpression<Object>(8), LiteralExpression<Object>(0)],
            ),
          ),
          const {},
        ),
        isNull,
      );

      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'equalTo',
              args: [LiteralExpression<Object>('2'), LiteralExpression<Object>(2)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'notEqualTo',
              args: [LiteralExpression<Object>(2), LiteralExpression<Object>(3)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'greaterThan',
              args: [LiteralExpression<Object>(3), LiteralExpression<Object>(2)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'greaterThanOrEqualTo',
              args: [LiteralExpression<Object>(3), LiteralExpression<Object>(3)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'lessThan',
              args: [LiteralExpression<Object>(2), LiteralExpression<Object>(3)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'lessThanOrEqualTo',
              args: [LiteralExpression<Object>(2), LiteralExpression<Object>(2)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'all',
              args: [LiteralExpression<Object>(true), LiteralExpression<Object>(true)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'any',
              args: [LiteralExpression<Object>(false), LiteralExpression<Object>(true)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'between',
              args: [
                LiteralExpression<Object>(3),
                LiteralExpression<Object>(1),
                LiteralExpression<Object>(5),
              ],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'in',
              args: [
                LiteralExpression<Object>('road'),
                LiteralExpression<Object>('park'),
                LiteralExpression<Object>('road'),
              ],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'not',
              args: [LiteralExpression<Object>(false)],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<String>(
            ArgsFunction(name: 'unsupported', args: []),
          ),
          const {},
        ),
        isNull,
      );
    });

    test('extended numeric helpers and parseBoolean work', () {
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'modulo',
              args: [LiteralExpression<Object>(10), LiteralExpression<Object>(4)],
            ),
          ),
          const {},
        ),
        2.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'pow',
              args: [LiteralExpression<Object>(2), LiteralExpression<Object>(3)],
            ),
          ),
          const {},
        ),
        8.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'abs', args: [LiteralExpression<Object>(-6)]),
          ),
          const {},
        ),
        6.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<int>(
            ArgsFunction(name: 'ceil', args: [LiteralExpression<Object>(3.1)]),
          ),
          const {},
        ),
        4,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<int>(
            ArgsFunction(name: 'floor', args: [LiteralExpression<Object>(3.9)]),
          ),
          const {},
        ),
        3,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<int>(
            ArgsFunction(name: 'round', args: [LiteralExpression<Object>(3.6)]),
          ),
          const {},
        ),
        4,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'sqrt', args: [LiteralExpression<Object>(9)]),
          ),
          const {},
        ),
        3.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'log', args: [LiteralExpression<Object>(1)]),
          ),
          const {},
        ),
        0.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'exp', args: [LiteralExpression<Object>(0)]),
          ),
          const {},
        ),
        1.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'min',
              args: [
                LiteralExpression<Object>(3),
                LiteralExpression<Object>(1),
                LiteralExpression<Object>(2),
              ],
            ),
          ),
          const {},
        ),
        1.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'max',
              args: [
                LiteralExpression<Object>(3),
                LiteralExpression<Object>(1),
                LiteralExpression<Object>(2),
              ],
            ),
          ),
          const {},
        ),
        3.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(ArgsFunction(name: 'pi')),
          const {},
        ),
        closeTo(3.141592653589793, 1e-12),
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'toDegrees',
              args: [LiteralExpression<Object>(3.141592653589793 / 2)],
            ),
          ),
          const {},
        ),
        closeTo(90.0, 1e-9),
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'toRadians',
              args: [LiteralExpression<Object>(180)],
            ),
          ),
          const {},
        ),
        closeTo(3.141592653589793, 1e-12),
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'parseBoolean',
              args: [LiteralExpression<Object>('yes')],
            ),
          ),
          const {},
        ),
        isTrue,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'parseBoolean',
              args: [LiteralExpression<Object>(0)],
            ),
          ),
          const {},
        ),
        isFalse,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'add',
              args: [LiteralExpression<Object>(true), LiteralExpression<Object>(2)],
            ),
          ),
          const {},
        ),
        3.0,
      );
    });

    test('trigonometric, rounding, and random helpers work', () {
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'rint', args: [LiteralExpression<Object>(3.6)]),
          ),
          const {},
        ),
        4.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'acos', args: [LiteralExpression<Object>(1)]),
          ),
          const {},
        ),
        0.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'asin', args: [LiteralExpression<Object>(1)]),
          ),
          const {},
        ),
        closeTo(3.141592653589793 / 2, 1e-12),
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'atan', args: [LiteralExpression<Object>(1)]),
          ),
          const {},
        ),
        closeTo(3.141592653589793 / 4, 1e-12),
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'atan2',
              args: [LiteralExpression<Object>(1), LiteralExpression<Object>(1)],
            ),
          ),
          const {},
        ),
        closeTo(3.141592653589793 / 4, 1e-12),
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'cos', args: [LiteralExpression<Object>(0)]),
          ),
          const {},
        ),
        1.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'sin',
              args: [LiteralExpression<Object>(3.141592653589793 / 2)],
            ),
          ),
          const {},
        ),
        closeTo(1.0, 1e-12),
      );
      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(name: 'tan', args: [LiteralExpression<Object>(0)]),
          ),
          const {},
        ),
        0.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<String>(
            ArgsFunction(
              name: 'numberFormat',
              args: [LiteralExpression<Object>(12)],
            ),
          ),
          const {},
        ),
        '12',
      );
      final randomValue = evaluateExpression(
        const FunctionExpression<double>(ArgsFunction(name: 'random')),
        const {},
      );
      expect(randomValue, isNotNull);
      expect(randomValue!, inInclusiveRange(0.0, 1.0));
    });

    test('fallback and string coercion branches are covered', () {
      final fallbackCase = FunctionExpression<String>(
        CaseFunction(
          cases: const [
            CaseParameter(
              condition: LiteralExpression<Object>(false),
              value: LiteralExpression<Object>('first'),
            ),
          ],
          fallback: const LiteralExpression<Object>('fallback'),
        ),
      );
      expect(evaluateExpression(fallbackCase, const {}), 'fallback');

      final nonNumericStep = FunctionExpression<double>(
        StepFunction(
          input: const FunctionExpression<Object>(PropertyGet('kind')),
          defaultValue: const LiteralExpression<Object>(1.0),
          stops: const [
            StepParameter(
              boundary: LiteralExpression<Object>(5),
              value: LiteralExpression<Object>(2.0),
            ),
          ],
        ),
      );
      expect(evaluateExpression(nonNumericStep, const {'kind': 'road'}), 1.0);

      final belowFirst = FunctionExpression<double>(
        InterpolateFunction(
          mode: const ['linear'],
          input: const FunctionExpression<Object>(PropertyGet('zoom')),
          stops: const [
            InterpolateParameter(
              stop: LiteralExpression<Object>(10),
              value: LiteralExpression<Object>(5.0),
            ),
            InterpolateParameter(
              stop: LiteralExpression<Object>(20),
              value: LiteralExpression<Object>(10.0),
            ),
          ],
        ),
      );
      expect(evaluateExpression(belowFirst, const {'zoom': 5}), 5.0);
      expect(evaluateExpression(belowFirst, const {'zoom': 25}), 10.0);

      final cubic = FunctionExpression<double>(
        InterpolateFunction(
          mode: const ['cubic'],
          input: const FunctionExpression<Object>(PropertyGet('zoom')),
          stops: const [
            InterpolateParameter(
              stop: LiteralExpression<Object>(0),
              value: LiteralExpression<Object>(0.0),
            ),
            InterpolateParameter(
              stop: LiteralExpression<Object>(10),
              value: LiteralExpression<Object>(10.0),
            ),
          ],
        ),
      );
      expect(evaluateExpression(cubic, const {'zoom': 5}), closeTo(5.0, 1.0));

      final brokenStep = FunctionExpression<double>(
        StepFunction(
          input: const LiteralExpression<Object>(8),
          defaultValue: const LiteralExpression<Object>(1.0),
          stops: const [
            StepParameter(
              boundary: LiteralExpression<Object>('invalid'),
              value: LiteralExpression<Object>(2.0),
            ),
          ],
        ),
      );
      expect(evaluateExpression(brokenStep, const {}), 1.0);

      final invalidInterpolate = FunctionExpression<double>(
        InterpolateFunction(
          mode: const ['linear'],
          input: const LiteralExpression<Object>('bad'),
          stops: const [
            InterpolateParameter(
              stop: LiteralExpression<Object>(0),
              value: LiteralExpression<Object>(1.0),
            ),
          ],
        ),
      );
      expect(evaluateExpression(invalidInterpolate, const {}), isNull);

      expect(
        evaluateExpression(
          const FunctionExpression<double>(
            ArgsFunction(
              name: 'add',
              args: [LiteralExpression<Object>('2'), LiteralExpression<Object>('3')],
            ),
          ),
          const {},
        ),
        5.0,
      );
      expect(
        evaluateExpression(
          const FunctionExpression<bool>(
            ArgsFunction(
              name: 'lessThan',
              args: [LiteralExpression<Object>('alpha'), LiteralExpression<Object>('beta')],
            ),
          ),
          const {},
        ),
        isTrue,
      );
    });
  });

  group('evaluateFilter extended', () {
    test('spatial operators cover remaining branches', () {
      expect(
        evaluateFilter(
          const SpatialFilter(
            operator: SpatialOperator.bbox,
            geometry: EnvelopeGeometry(minX: 0, minY: 0, maxX: 2, maxY: 2),
          ),
          const {},
          geometry: const PointGeometry(1, 1),
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          const SpatialFilter(
            operator: SpatialOperator.contains,
            geometry: PointGeometry(2, 2),
          ),
          const {},
          geometry: const PolygonGeometry([
            [(0, 0), (4, 0), (4, 4), (0, 4), (0, 0)],
          ]),
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          const SpatialFilter(
            operator: SpatialOperator.touches,
            geometry: EnvelopeGeometry(minX: 0, minY: 0, maxX: 4, maxY: 4),
          ),
          const {},
          geometry: const PointGeometry(0, 2),
        ),
        isFalse,
      );
      expect(
        evaluateFilter(
          const SpatialFilter(
            operator: SpatialOperator.crosses,
            geometry: PolygonGeometry([
              [(0, 0), (4, 0), (4, 4), (0, 4), (0, 0)],
            ]),
          ),
          const {},
          geometry: const LineStringGeometry([(-1, 2), (2, 2), (5, 2)]),
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          const SpatialFilter(
            operator: SpatialOperator.overlaps,
            geometry: PolygonGeometry([
              [(2, 2), (6, 2), (6, 6), (2, 6), (2, 2)],
            ]),
          ),
          const {},
          geometry: const PolygonGeometry([
            [(0, 0), (4, 0), (4, 4), (0, 4), (0, 0)],
          ]),
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          const SpatialFilter(
            operator: SpatialOperator.disjoint,
            geometry: PolygonGeometry([
              [(10, 10), (12, 10), (12, 12), (10, 12), (10, 10)],
            ]),
          ),
          const {},
          geometry: const PointGeometry(0, 0),
        ),
        isTrue,
      );
    });

    test('distance and comparison helpers cover string branches', () {
      expect(
        evaluateFilter(
          const DistanceFilter(
            operator: DistanceOperator.beyond,
            geometry: PointGeometry(0, 0),
            distance: 5,
          ),
          const {},
          geometry: const PointGeometry(10, 0),
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          const ComparisonFilter(
            operator: ComparisonOperator.eq,
            property: LiteralExpression('rank'),
            value: LiteralExpression('7'),
          ),
          const {'rank': '7'},
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          const ComparisonFilter(
            operator: ComparisonOperator.lt,
            property: LiteralExpression('name'),
            value: LiteralExpression('beta'),
          ),
          const {'name': 'alpha'},
        ),
        isTrue,
      );
    });

    test('numeric _compare path (gt with numeric property and value)', () {
      expect(
        evaluateFilter(
          const ComparisonFilter(
            operator: ComparisonOperator.gt,
            property: LiteralExpression('score'),
            value: LiteralExpression<Object>(50),
          ),
          const {'score': 100},
        ),
        isTrue,
      );
      expect(
        evaluateFilter(
          const ComparisonFilter(
            operator: ComparisonOperator.lt,
            property: LiteralExpression('score'),
            value: LiteralExpression<Object>(50),
          ),
          const {'score': 100},
        ),
        isFalse,
      );
    });
  });

  group('evaluateExpression coverage gaps', () {
    test('null expression returns null', () {
      expect(evaluateExpression<double>(null, const {}), isNull);
      expect(evaluateExpression<String>(null, const {}), isNull);
    });

    test('_toInt with double and string args via strSubstring', () {
      // strSubstring calls _toInt on its positional arguments.
      // Pass a double (3.7 → 3) and a string ('6') to exercise both paths.
      expect(
        evaluateExpression(
          const FunctionExpression<Object>(ArgsFunction(
            name: 'strSubstring',
            args: [
              LiteralExpression<Object>('Hello World'),
              LiteralExpression<Object>(3.7), // num → _toInt
              LiteralExpression<Object>('8'), // String → _toInt
            ],
          )),
          const {},
        ),
        'lo Wo',
      );
    });

    test('parseBoolean with y/on/n/off string variants', () {
      for (final (input, expected) in [
        ('y', true),
        ('on', true),
        ('n', false),
        ('off', false),
        ('Y', true),
        ('ON', true),
        ('N', false),
        ('OFF', false),
      ]) {
        expect(
          evaluateExpression(
            FunctionExpression<Object>(ArgsFunction(
              name: 'parseBoolean',
              args: [LiteralExpression<Object>(input)],
            )),
            const {},
          ),
          expected,
          reason: 'parseBoolean("$input") should be $expected',
        );
      }
    });
  });

  group('RTree.any with branches', () {
    test('any() traverses branch nodes on large trees', () {
      // >9 features forces the R-Tree to create branch nodes
      // (maxEntries default is 9).
      final geometries = <Geometry>[
        for (var i = 0; i < 20; i++)
          PointGeometry(i.toDouble(), i.toDouble()),
      ];
      final tree = RTree.bulk(geometries);
      expect(tree.length, 20);

      // Point 10,10 exists — any() must traverse branches to find it.
      expect(
        tree.any(const EnvelopeGeometry(
          minX: 9.5, minY: 9.5, maxX: 10.5, maxY: 10.5,
        )),
        isTrue,
      );

      // No point near 99,99 — any() traverses all branches, returns false.
      expect(
        tree.any(const EnvelopeGeometry(
          minX: 98, minY: 98, maxX: 100, maxY: 100,
        )),
        isFalse,
      );
    });
  });

  group('MarkPainter paint branches', () {
    Future<void> paintShape(
      WidgetTester tester,
      String shape, {
      Color? strokeColor,
    }) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomPaint(
            size: const Size(32, 32),
            painter: MarkPainter(
              wellKnownName: shape,
              color: const Color(0xFFFF0000),
              strokeColor: strokeColor,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    testWidgets('paints all supported shapes and fallback', (tester) async {
      for (final shape in [
        'circle',
        'square',
        'diamond',
        'triangle',
        'star',
        'cross',
        'x',
        'unknown',
      ]) {
        await paintShape(tester, shape);
      }
    });

    testWidgets('paints with stroke color set', (tester) async {
      for (final shape in ['circle', 'triangle', 'star', 'cross', 'x']) {
        await paintShape(
          tester,
          shape,
          strokeColor: const Color(0xFF000000),
        );
      }
    });
  });

  group('style renderer extended branches', () {
    const renderer = StyleRenderer();

    test('top-level selectRulesAtScale delegates', () {
      final style = Style(rules: [
        Rule(
          name: 'a',
          scaleDenominator: const ScaleDenominator(min: 0, max: 5),
          symbolizers: const [FillSymbolizer()],
        ),
        Rule(name: 'b', symbolizers: const [FillSymbolizer()]),
      ]);
      expect(selectRulesAtScale(style, 3).map((rule) => rule.name), ['a', 'b']);
    });

    test('mark renderer covers rotation and stroke color branches', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const MarkSymbolizer(
          wellKnownName: 'diamond',
          radius: LiteralExpression(6.0),
          color: LiteralExpression('#00ff00'),
          opacity: LiteralExpression(0.5),
          strokeColor: LiteralExpression('#000000'),
          strokeWidth: LiteralExpression(2.0),
          rotate: LiteralExpression(45.0),
        ),
        features: const [
          StyledFeature(
            id: 'mark-1',
            geometry: PointGeometry(13.4, 52.5),
          ),
        ],
      );
      expect(layer, isA<MarkerLayer>());
      final marker = (layer as MarkerLayer).markers.single;
      expect(marker.child, isA<Transform>());
    });

    test('icon renderer handles empty paths and file/network schemes', () {
      expect(
        renderer.symbolizerToLayer(
          symbolizer: const IconSymbolizer(
            image: LiteralExpression(''),
          ),
          features: const [
            StyledFeature(geometry: PointGeometry(0, 0)),
          ],
        ),
        isNull,
      );

      final networkLayer = renderer.symbolizerToLayer(
        symbolizer: const IconSymbolizer(
          image: LiteralExpression('https://example.com/icon.png'),
          rotate: LiteralExpression(10.0),
        ),
        features: const [
          StyledFeature(geometry: PointGeometry(0, 0)),
        ],
      ) as MarkerLayer;
      expect(networkLayer.markers.single.child, isA<Transform>());

      final tempDir = Directory.systemTemp.createTempSync('flutter_mapstyler');
      final file = File('${tempDir.path}/icon.png')..writeAsBytesSync([0, 1, 2]);
      final fileLayer = renderer.symbolizerToLayer(
        symbolizer: IconSymbolizer(
          image: LiteralExpression(file.uri.toString()),
        ),
        features: const [
          StyledFeature(geometry: PointGeometry(0, 0)),
        ],
      ) as MarkerLayer;
      final image = (((fileLayer.markers.single.child as Opacity).child) as Image);
      expect(image.image, isA<FileImage>());

      final absoluteLayer = renderer.symbolizerToLayer(
        symbolizer: IconSymbolizer(
          image: LiteralExpression(file.path),
        ),
        features: const [
          StyledFeature(geometry: PointGeometry(0, 0)),
        ],
      ) as MarkerLayer;
      final absoluteImage =
          (((absoluteLayer.markers.single.child as Opacity).child) as Image);
      expect(absoluteImage.image, isA<FileImage>());
    });

    test('text renderer handles polygon and envelope anchors', () {
      final layer = renderer.renderRule(
        rule: Rule(
          symbolizers: const [
            TextSymbolizer(
              label: LiteralExpression('Area'),
              haloColor: LiteralExpression('#ffffff'),
              haloWidth: LiteralExpression(2.0),
              rotate: LiteralExpression(15.0),
            ),
          ],
        ),
        features: const [
          StyledFeature(
            geometry: PolygonGeometry([
              [(0, 0), (4, 0), (4, 4), (0, 4), (0, 0)],
            ]),
          ),
          StyledFeature(
            geometry: EnvelopeGeometry(minX: 10, minY: 10, maxX: 12, maxY: 12),
          ),
        ],
        onFeatureTap: (_) {},
      );
      expect(layersOfType<MarkerLayer>(layer), hasLength(1));
      expect((layer.first as MarkerLayer).markers, hasLength(2));
      expect((layer.first as MarkerLayer).markers.first.child, isA<GestureDetector>());
    });

    test('text renderer handles point anchors without callbacks', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const TextSymbolizer(
          label: LiteralExpression('Point'),
          color: LiteralExpression('#000000'),
        ),
        features: const [
          StyledFeature(
            geometry: PointGeometry(13.4, 52.5),
          ),
        ],
      ) as MarkerLayer;
      expect(layer.markers, hasLength(1));
      expect(layer.markers.single.child, isA<Text>());
    });

    test('raster renderer handles tile layers and color filters', () {
      final widget = renderer.symbolizerToLayer(
        symbolizer: const RasterSymbolizer(
          opacity: LiteralExpression(0.6),
          saturation: LiteralExpression(1.2),
          contrast: LiteralExpression(1.1),
          hueRotate: LiteralExpression(15.0),
          brightnessMin: LiteralExpression(0.1),
          brightnessMax: LiteralExpression(0.9),
        ),
        features: const [
          StyledFeature(
            id: 'tile-1',
            geometry: EnvelopeGeometry(minX: 0, minY: 0, maxX: 1, maxY: 1),
            properties: {
              'urlTemplate': 'https://tiles/{z}/{x}/{y}.png',
              'fallbackUrl': 'https://fallback/{z}/{x}/{y}.png',
              'additionalOptions': {'token': 'abc'},
              'subdomains': ['a', 'b'],
              'tms': true,
              'minZoom': '1',
              'maxZoom': 18,
              'minNativeZoom': '2',
              'maxNativeZoom': 19,
            },
          ),
        ],
      );
      expect(widget, isA<ColorFiltered>());
      expect((widget as ColorFiltered).child, isA<Opacity>());
      expect(((widget.child as Opacity).child), isA<TileLayer>());
    });

    test('raster renderer coerces generic maps and lists for tile options', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const RasterSymbolizer(),
        features: const [
          StyledFeature(
            id: 'tile-2',
            geometry: EnvelopeGeometry(minX: 0, minY: 0, maxX: 1, maxY: 1),
            properties: {
              'urlTemplate': 'https://tiles/{z}/{x}/{y}.png',
              'additionalOptions': {'token': 7},
              'subdomains': [1, 2],
            },
          ),
        ],
      ) as TileLayer;

      expect(layer.additionalOptions, {'token': '7'});
      expect(layer.subdomains, ['1', '2']);
    });

    test('raster overlay returns null when no valid sources exist', () {
      expect(
        renderer.symbolizerToLayer(
          symbolizer: const RasterSymbolizer(),
          features: const [
            StyledFeature(
              geometry: EnvelopeGeometry(minX: 0, minY: 0, maxX: 1, maxY: 1),
            ),
          ],
        ),
        isNull,
      );
    });

    test('geometry layers wrap when callbacks are provided', () {
      final polygon = const StyledFeature(
        id: 'polygon',
        geometry: PolygonGeometry([
          [(13.0, 52.0), (14.0, 52.0), (14.0, 53.0), (13.0, 53.0), (13.0, 52.0)],
        ]),
      );
      final line = const StyledFeature(
        id: 'line',
        geometry: LineStringGeometry([(13.0, 52.0), (14.0, 53.0)]),
      );

      final polygonLayer = renderer.symbolizerToLayer(
        symbolizer: const FillSymbolizer(color: LiteralExpression('#00ff00')),
        features: [polygon],
        onFeatureTap: (_) {},
      );
      final lineLayer = renderer.symbolizerToLayer(
        symbolizer: const LineSymbolizer(
          color: LiteralExpression('#000000'),
          width: LiteralExpression(4.0),
        ),
        features: [line],
        onFeatureLongPress: (_) {},
      );

      expect(polygonLayer, isNot(isA<PolygonLayer<StyledFeature>>()));
      expect(lineLayer, isNot(isA<PolylineLayer<StyledFeature>>()));
    });

    test('line renderer uses dotted pattern for single dash value', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const LineSymbolizer(
          color: LiteralExpression('#000000'),
          width: LiteralExpression(2.0),
          dasharray: [3.0],
        ),
        features: const [
          StyledFeature(
            geometry: LineStringGeometry([(0, 0), (1, 1)]),
          ),
        ],
      ) as PolylineLayer;

      expect(layer.polylines.single.pattern, isA<StrokePattern>());
    });

    test('renderStyle can be called repeatedly with scale caching active', () {
      final style = Style(rules: [
        Rule(
          scaleDenominator: const ScaleDenominator(min: 0, max: 10),
          symbolizers: const [
            FillSymbolizer(color: LiteralExpression('#00ff00')),
          ],
        ),
      ]);
      const features = StyledFeatureCollection([
        StyledFeature(
          id: 'polygon',
          geometry: PolygonGeometry([
            [(0, 0), (1, 0), (1, 1), (0, 1), (0, 0)],
          ]),
        ),
      ]);

      final first = renderer.renderStyle(
        style: style,
        features: features,
        scaleDenominator: 5,
      );
      final second = renderer.renderStyle(
        style: style,
        features: features,
        scaleDenominator: 5,
      );

      expect(first, hasLength(1));
      expect(second, hasLength(1));
    });

    test('renderStyle invalidates persistent expression cache on property change', () {
      final style = Style(rules: [
        Rule(
          symbolizers: const [
            TextSymbolizer(
              label: FunctionExpression(PropertyGet('name')),
            ),
          ],
        ),
      ]);

      final first = renderer.renderStyle(
        style: style,
        features: const StyledFeatureCollection([
          StyledFeature(
            id: 'feature-1',
            geometry: PointGeometry(0, 0),
            properties: {'name': 'First'},
          ),
        ]),
      );
      final second = renderer.renderStyle(
        style: style,
        features: const StyledFeatureCollection([
          StyledFeature(
            id: 'feature-1',
            geometry: PointGeometry(0, 0),
            properties: {'name': 'Second'},
          ),
        ]),
      );

      final firstText =
          (layersOfType<MarkerLayer>(first).single.markers.single.child as Text).data;
      final secondText =
          (layersOfType<MarkerLayer>(second).single.markers.single.child as Text).data;

      expect(firstText, 'First');
      expect(secondText, 'Second');
    });

    test('renderStyle filters features by viewport before rendering', () {
      final style = Style(rules: [
        Rule(
          symbolizers: const [
            MarkSymbolizer(
              wellKnownName: 'circle',
              radius: LiteralExpression(6.0),
              color: LiteralExpression('#ff0000'),
            ),
          ],
        ),
      ]);

      final layers = renderer.renderStyle(
        style: style,
        features: const StyledFeatureCollection([
          StyledFeature(
            id: 'inside',
            geometry: PointGeometry(13.4, 52.5),
          ),
          StyledFeature(
            id: 'outside',
            geometry: PointGeometry(30.0, 10.0),
          ),
        ]),
        viewport: LatLngBounds(
          const LatLng(52.4, 13.3),
          const LatLng(52.6, 13.5),
        ),
      );

      expect(layersOfType<MarkerLayer>(layers), hasLength(1));
      expect(layersOfType<MarkerLayer>(layers).single.markers, hasLength(1));
    });

    test('renderStyle does not persist random expression results across renders', () {
      final style = Style(rules: [
        Rule(
          symbolizers: const [
            TextSymbolizer(
              label: FunctionExpression(
                ArgsFunction(
                  name: 'numberFormat',
                  args: [
                    FunctionExpression(ArgsFunction(name: 'random')),
                    LiteralExpression<Object>(6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ]);

      final first = renderer.renderStyle(
        style: style,
        features: const StyledFeatureCollection([
          StyledFeature(
            id: 'feature-1',
            geometry: PointGeometry(0, 0),
          ),
        ]),
      );
      final second = renderer.renderStyle(
        style: style,
        features: const StyledFeatureCollection([
          StyledFeature(
            id: 'feature-1',
            geometry: PointGeometry(0, 0),
          ),
        ]),
      );

      final firstText =
          (layersOfType<MarkerLayer>(first).single.markers.single.child as Text).data;
      final secondText =
          (layersOfType<MarkerLayer>(second).single.markers.single.child as Text).data;

      expect(firstText, isNotNull);
      expect(secondText, isNotNull);
      expect(secondText, isNot(firstText));
    });

    test('symbolizerToLayer also filters by viewport', () {
      final layer = renderer.symbolizerToLayer(
        symbolizer: const TextSymbolizer(
          label: FunctionExpression(PropertyGet('name')),
        ),
        features: const [
          StyledFeature(
            id: 'inside',
            geometry: PointGeometry(13.4, 52.5),
            properties: {'name': 'Inside'},
          ),
          StyledFeature(
            id: 'outside',
            geometry: PointGeometry(20.0, 20.0),
            properties: {'name': 'Outside'},
          ),
        ],
        viewport: LatLngBounds(
          const LatLng(52.4, 13.3),
          const LatLng(52.6, 13.5),
        ),
      ) as MarkerLayer;

      expect(layer.markers, hasLength(1));
      expect((layer.markers.single.child as Text).data, 'Inside');
    });
  });

  testWidgets('geometry layer tap and long-press callbacks are wired through the map', (
    tester,
  ) async {
    const renderer = StyleRenderer();
    final polygonFeature = const StyledFeature(
      id: 'polygon-feature',
      geometry: PolygonGeometry([
        [(13.0, 52.0), (14.0, 52.0), (14.0, 53.0), (13.0, 53.0), (13.0, 52.0)],
      ]),
    );
    final lineFeature = const StyledFeature(
      id: 'line-feature',
      geometry: LineStringGeometry([(12.8, 52.5), (14.2, 52.5)]),
    );

    StyledFeature? tapped;
    StyledFeature? longPressed;

    Widget buildMap(Widget child) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 300,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(52.5, 13.5),
              initialZoom: 8,
            ),
            children: [child],
          ),
        ),
      );
    }

    final polygonLayer = renderer.symbolizerToLayer(
      symbolizer: const FillSymbolizer(color: LiteralExpression('#00ff00')),
      features: [polygonFeature],
      onFeatureTap: (feature) => tapped = feature,
    )!;

    await tester.pumpWidget(buildMap(polygonLayer));
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump();
    expect(tapped, same(polygonFeature));

    final lineLayer = renderer.symbolizerToLayer(
      symbolizer: const LineSymbolizer(
        color: LiteralExpression('#000000'),
        width: LiteralExpression(8.0),
      ),
      features: [lineFeature],
      onFeatureLongPress: (feature) => longPressed = feature,
    )!;

    await tester.pumpWidget(buildMap(lineLayer));
    await tester.pump();
    await tester.longPressAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump();
    expect(longPressed, same(lineFeature));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

List<T> layersOfType<T>(List<Widget> layers) =>
    layers.whereType<T>().toList(growable: false);
