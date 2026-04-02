import 'package:mapstyler_mapbox_adapter/src/read/expression_mapper.dart';
import 'package:mapstyler_mapbox_adapter/src/read/filter_mapper.dart';
import 'package:mapstyler_mapbox_adapter/src/read/zoom_mapper.dart';
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Expression mapper
  // ---------------------------------------------------------------------------
  group('expression mapper', () {
    final w = <String>[];
    setUp(() => w.clear());

    test('literal string', () {
      final e = convertValue<String>('#ff0000', (v) => '$v', w);
      expect((e as ms.LiteralExpression<String>).value, '#ff0000');
    });

    test('literal number', () {
      final e = convertValue<double>(42, (v) => (v as num).toDouble(), w);
      expect((e as ms.LiteralExpression<double>).value, 42.0);
    });

    test('get expression', () {
      final e = convertValue<String>(['get', 'name'], (v) => '$v', w);
      expect(e, isA<ms.FunctionExpression<String>>());
      final func = (e as ms.FunctionExpression<String>).function;
      expect((func as ms.PropertyGet).propertyName, 'name');
    });

    test('literal expression', () {
      final e = convertValue<String>(['literal', 'hello'], (v) => '$v', w);
      expect((e as ms.LiteralExpression<String>).value, 'hello');
    });

    test('interpolate expression', () {
      final e = convertValue<double>(
        ['interpolate', ['linear'], ['zoom'], 0, 1, 10, 5],
        (v) => (v as num).toDouble(),
        w,
      );
      expect(e, isA<ms.FunctionExpression<double>>());
      final func =
          (e as ms.FunctionExpression<double>).function as ms.InterpolateFunction;
      expect(func.mode, ['linear']);
      expect(func.stops, hasLength(2));
    });

    test('step expression', () {
      final e = convertValue<String>(
        ['step', ['zoom'], 'default', 5, 'a', 10, 'b'],
        (v) => '$v',
        w,
      );
      final func =
          (e as ms.FunctionExpression<String>).function as ms.StepFunction;
      expect(func.stops, hasLength(2));
    });

    test('case expression', () {
      final e = convertValue<String>(
        ['case', true, 'yes', false, 'no', 'fallback'],
        (v) => '$v',
        w,
      );
      final func =
          (e as ms.FunctionExpression<String>).function as ms.CaseFunction;
      expect(func.cases, hasLength(2));
    });

    test('match expression', () {
      final e = convertValue<String>(
        ['match', ['get', 'type'], 'a', 'red', 'b', 'blue', 'gray'],
        (v) => '$v',
        w,
      );
      final func =
          (e as ms.FunctionExpression<String>).function as ms.CaseFunction;
      expect(func.cases, hasLength(2));
    });

    test('match with array labels', () {
      final e = convertValue<String>(
        ['match', ['get', 'type'], ['a', 'b'], 'red', 'gray'],
        (v) => '$v',
        w,
      );
      final func =
          (e as ms.FunctionExpression<String>).function as ms.CaseFunction;
      expect(func.cases, hasLength(2)); // a→red, b→red
    });

    test('concat expression', () {
      final e = convertValue<String>(
        ['concat', 'hello', ' ', 'world'],
        (v) => '$v',
        w,
      );
      final func =
          (e as ms.FunctionExpression<String>).function as ms.ArgsFunction;
      expect(func.name, 'strConcat');
      expect(func.args, hasLength(3));
    });

    test('zoom expression', () {
      final e = convertValue<double>(['zoom'], (v) => (v as num).toDouble(), w);
      final func =
          (e as ms.FunctionExpression<double>).function as ms.ArgsFunction;
      expect(func.name, 'zoom');
    });

    test('unsupported expression warns', () {
      final e = convertValue<String>(['rgb', 255, 0, 0], (v) => '$v', w);
      expect(e, isNull);
      expect(w, anyElement(contains('Unsupported expression: rgb')));
    });

    test('null returns null', () {
      expect(convertValue<String>(null, (v) => '$v', w), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Filter mapper
  // ---------------------------------------------------------------------------
  group('filter mapper', () {
    final w = <String>[];
    setUp(() => w.clear());

    for (final entry in {
      '==': ms.ComparisonOperator.eq,
      '!=': ms.ComparisonOperator.neq,
      '<': ms.ComparisonOperator.lt,
      '>': ms.ComparisonOperator.gt,
      '<=': ms.ComparisonOperator.lte,
      '>=': ms.ComparisonOperator.gte,
    }.entries) {
      test('comparison ${entry.key}', () {
        final f = convertFilter([entry.key, 'field', 'value'], w)
            as ms.ComparisonFilter;
        expect(f.operator, entry.value);
      });
    }

    test('v2 expression-based filter', () {
      final f = convertFilter(['==', ['get', 'type'], 'road'], w)
          as ms.ComparisonFilter;
      expect(f.operator, ms.ComparisonOperator.eq);
      expect((f.property as ms.LiteralExpression<String>).value, 'type');
    });

    test('all combination', () {
      final f = convertFilter([
        'all',
        ['==', 'a', 1],
        ['>', 'b', 2],
      ], w) as ms.CombinationFilter;
      expect(f.operator, ms.CombinationOperator.and);
      expect(f.filters, hasLength(2));
    });

    test('any combination', () {
      final f = convertFilter([
        'any',
        ['==', 'a', 1],
        ['==', 'a', 2],
      ], w) as ms.CombinationFilter;
      expect(f.operator, ms.CombinationOperator.or);
    });

    test('none → negated any', () {
      final f = convertFilter([
        'none',
        ['==', 'a', 1],
      ], w) as ms.NegationFilter;
      expect(f.filter, isA<ms.ComparisonFilter>());
    });

    test('! negation', () {
      final f = convertFilter([
        '!',
        ['==', 'x', 1],
      ], w) as ms.NegationFilter;
      expect(f.filter, isA<ms.ComparisonFilter>());
    });

    test('has filter', () {
      final f = convertFilter(['has', 'name'], w);
      expect(f, isA<ms.ComparisonFilter>());
      expect(w, anyElement(contains('has')));
    });

    test('!has filter', () {
      final f = convertFilter(['!has', 'name'], w);
      expect(f, isA<ms.ComparisonFilter>());
    });

    test('in filter', () {
      final f = convertFilter(['in', 'type', 'a', 'b', 'c'], w)
          as ms.CombinationFilter;
      expect(f.operator, ms.CombinationOperator.or);
      expect(f.filters, hasLength(3));
    });

    test('!in filter', () {
      final f = convertFilter(['!in', 'type', 'a', 'b'], w)
          as ms.NegationFilter;
      expect(f.filter, isA<ms.CombinationFilter>());
    });

    test('unsupported operator warns', () {
      final f = convertFilter(['within', {}], w);
      expect(f, isNull);
      expect(w, anyElement(contains('Unsupported filter')));
    });

    test('null filter returns null', () {
      expect(convertFilter(null, w), isNull);
    });

    test('empty filter returns null', () {
      expect(convertFilter([], w), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Zoom mapper
  // ---------------------------------------------------------------------------
  group('zoom mapper', () {
    test('null returns null', () {
      expect(zoomToScaleDenominator(), isNull);
    });

    test('minzoom 0 → max ~559M', () {
      final sd = zoomToScaleDenominator(minzoom: 0)!;
      expect(sd.max, closeTo(559082264, 1));
    });

    test('maxzoom 18 → min ~2133', () {
      final sd = zoomToScaleDenominator(maxzoom: 18)!;
      expect(sd.min!, closeTo(2133, 1));
    });

    test('reverse: scaleDenominatorToZoom', () {
      final sd = ms.ScaleDenominator(min: 2133, max: 559082264);
      final z = scaleDenominatorToZoom(sd);
      expect(z.minzoom, closeTo(0, 0.1));
      expect(z.maxzoom, closeTo(18, 0.1));
    });

    test('reverse null returns nulls', () {
      final z = scaleDenominatorToZoom(null);
      expect(z.minzoom, isNull);
      expect(z.maxzoom, isNull);
    });
  });
}
