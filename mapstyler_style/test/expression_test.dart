import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('LiteralExpression', () {
    test('fromJson with string', () {
      final expr = Expression.fromJson<String>('#ff0000', (v) => v as String);
      expect(expr, isA<LiteralExpression<String>>());
      expect((expr as LiteralExpression<String>).value, '#ff0000');
    });

    test('fromJson with double', () {
      final expr =
          Expression.fromJson<double>(0.5, (v) => (v as num).toDouble());
      expect((expr as LiteralExpression<double>).value, 0.5);
    });

    test('fromJson with int coerced to double', () {
      final expr =
          Expression.fromJson<double>(2, (v) => (v as num).toDouble());
      expect((expr as LiteralExpression<double>).value, 2.0);
    });

    test('toJson returns raw value', () {
      const expr = LiteralExpression<String>('#ff0000');
      expect(expr.toJson(), '#ff0000');
    });

    test('round-trip', () {
      const original = LiteralExpression<double>(12.0);
      final json = original.toJson();
      final restored =
          Expression.fromJson<double>(json, (v) => (v as num).toDouble());
      expect(restored, original);
    });

    test('equality', () {
      const a = LiteralExpression<String>('red');
      const b = LiteralExpression<String>('red');
      const c = LiteralExpression<String>('blue');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('FunctionExpression', () {
    test('fromJson with property function', () {
      final json = {'name': 'property', 'args': ['size']};
      final expr =
          Expression.fromJson<double>(json, (v) => (v as num).toDouble());
      expect(expr, isA<FunctionExpression<double>>());
      final func = (expr as FunctionExpression<double>).function;
      expect(func, isA<PropertyGet>());
      expect((func as PropertyGet).propertyName, 'size');
    });

    test('toJson produces function map', () {
      const expr =
          FunctionExpression<String>(PropertyGet('color'));
      expect(expr.toJson(), {
        'name': 'property',
        'args': ['color'],
      });
    });

    test('round-trip', () {
      const original =
          FunctionExpression<double>(PropertyGet('radius'));
      final json = original.toJson();
      final restored =
          Expression.fromJson<double>(json, (v) => (v as num).toDouble());
      expect(restored, original);
    });

    test('equality', () {
      const a = FunctionExpression<String>(PropertyGet('name'));
      const b = FunctionExpression<String>(PropertyGet('name'));
      const c = FunctionExpression<String>(PropertyGet('type'));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('GeoStylerFunction', () {
    test('unknown function names parse as ArgsFunction', () {
      final func =
          GeoStylerFunction.fromJson({'name': 'customFunc', 'args': [42]});
      expect(func, isA<ArgsFunction>());
      expect(func.name, 'customFunc');
    });

    test('PropertyGet name getter', () {
      const pg = PropertyGet('f');
      expect(pg.name, 'property');
    });

    test('PropertyGet round-trip', () {
      const original = PropertyGet('fieldName');
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });
  });

  group('ArgsFunction', () {
    test('fromJson parses add with literal args', () {
      final json = {
        'name': 'add',
        'args': [5, 10],
      };
      final func = GeoStylerFunction.fromJson(json) as ArgsFunction;
      expect(func.name, 'add');
      expect(func.args.length, 2);
      expect((func.args[0] as LiteralExpression<Object>).value, 5);
      expect((func.args[1] as LiteralExpression<Object>).value, 10);
    });

    test('fromJson parses nested function in args', () {
      final json = {
        'name': 'multiply',
        'args': [
          {'name': 'property', 'args': ['width']},
          2,
        ],
      };
      final func = GeoStylerFunction.fromJson(json) as ArgsFunction;
      expect(func.args[0], isA<FunctionExpression<Object>>());
      final inner =
          (func.args[0] as FunctionExpression<Object>).function as PropertyGet;
      expect(inner.propertyName, 'width');
      expect((func.args[1] as LiteralExpression<Object>).value, 2);
    });

    test('fromJson with no args', () {
      final json = {'name': 'pi', 'args': <dynamic>[]};
      final func = GeoStylerFunction.fromJson(json) as ArgsFunction;
      expect(func.name, 'pi');
      expect(func.args, isEmpty);
    });

    test('fromJson with missing args key', () {
      final json = {'name': 'random'};
      final func = GeoStylerFunction.fromJson(json) as ArgsFunction;
      expect(func.args, isEmpty);
    });

    test('round-trip for math function', () {
      const original = ArgsFunction(
        name: 'add',
        args: [
          LiteralExpression<Object>(5),
          LiteralExpression<Object>(10),
        ],
      );
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });

    test('round-trip for string function', () {
      const original = ArgsFunction(
        name: 'strConcat',
        args: [
          LiteralExpression<Object>('Hello'),
          LiteralExpression<Object>(' '),
          LiteralExpression<Object>('World'),
        ],
      );
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });

    test('round-trip with nested functions', () {
      const original = ArgsFunction(
        name: 'strToUpperCase',
        args: [
          FunctionExpression<Object>(PropertyGet('name')),
        ],
      );
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });

    test('round-trip for boolean function', () {
      const original = ArgsFunction(
        name: 'greaterThan',
        args: [
          FunctionExpression<Object>(PropertyGet('pop')),
          LiteralExpression<Object>(1000000),
        ],
      );
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });

    test('equality', () {
      const a = ArgsFunction(
        name: 'abs',
        args: [LiteralExpression<Object>(-5)],
      );
      const b = ArgsFunction(
        name: 'abs',
        args: [LiteralExpression<Object>(-5)],
      );
      const c = ArgsFunction(
        name: 'abs',
        args: [LiteralExpression<Object>(5)],
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CaseParameter', () {
    test('equality', () {
      const a = CaseParameter(
        condition: LiteralExpression<Object>(true),
        value: LiteralExpression<Object>('yes'),
      );
      const b = CaseParameter(
        condition: LiteralExpression<Object>(true),
        value: LiteralExpression<Object>('yes'),
      );
      const c = CaseParameter(
        condition: LiteralExpression<Object>(false),
        value: LiteralExpression<Object>('yes'),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('fromJson round-trip', () {
      final json = {
        'case': true,
        'value': 'result',
      };
      final cp = CaseParameter.fromJson(json);
      expect(cp.toJson(), json);
    });
  });

  group('StepParameter', () {
    test('equality', () {
      const a = StepParameter(
        boundary: LiteralExpression<Object>(10),
        value: LiteralExpression<Object>('a'),
      );
      const b = StepParameter(
        boundary: LiteralExpression<Object>(10),
        value: LiteralExpression<Object>('a'),
      );
      const c = StepParameter(
        boundary: LiteralExpression<Object>(20),
        value: LiteralExpression<Object>('a'),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('InterpolateParameter', () {
    test('equality', () {
      const a = InterpolateParameter(
        stop: LiteralExpression<Object>(0),
        value: LiteralExpression<Object>('#000'),
      );
      const b = InterpolateParameter(
        stop: LiteralExpression<Object>(0),
        value: LiteralExpression<Object>('#000'),
      );
      const c = InterpolateParameter(
        stop: LiteralExpression<Object>(100),
        value: LiteralExpression<Object>('#000'),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CaseFunction', () {
    test('fromJson parses case with fallback', () {
      final json = {
        'name': 'case',
        'args': [
          {
            'case': {'name': 'equalTo', 'args': ['type', 'road']},
            'value': '#333333',
          },
          {
            'case': {'name': 'equalTo', 'args': ['type', 'river']},
            'value': '#0000ff',
          },
          '#cccccc', // fallback
        ],
      };
      final func = GeoStylerFunction.fromJson(json) as CaseFunction;
      expect(func.cases.length, 2);
      expect(func.cases[0].condition, isA<FunctionExpression<Object>>());
      expect(
        (func.cases[0].value as LiteralExpression<Object>).value,
        '#333333',
      );
      expect(
        (func.fallback as LiteralExpression<Object>).value,
        '#cccccc',
      );
    });

    test('round-trip', () {
      const original = CaseFunction(
        cases: [
          CaseParameter(
            condition: FunctionExpression<Object>(ArgsFunction(
              name: 'equalTo',
              args: [
                FunctionExpression<Object>(PropertyGet('type')),
                LiteralExpression<Object>('road'),
              ],
            )),
            value: LiteralExpression<Object>('#333333'),
          ),
        ],
        fallback: LiteralExpression<Object>('#cccccc'),
      );
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });

    test('name getter', () {
      const cf = CaseFunction(
        cases: [],
        fallback: LiteralExpression<Object>('x'),
      );
      expect(cf.name, 'case');
    });

    test('equality', () {
      const a = CaseFunction(
        cases: [
          CaseParameter(
            condition: LiteralExpression<Object>(true),
            value: LiteralExpression<Object>('yes'),
          ),
        ],
        fallback: LiteralExpression<Object>('no'),
      );
      const b = CaseFunction(
        cases: [
          CaseParameter(
            condition: LiteralExpression<Object>(true),
            value: LiteralExpression<Object>('yes'),
          ),
        ],
        fallback: LiteralExpression<Object>('no'),
      );
      const c = CaseFunction(
        cases: [],
        fallback: LiteralExpression<Object>('no'),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('StepFunction', () {
    test('name getter', () {
      const sf = StepFunction(
        input: LiteralExpression<Object>(0),
        defaultValue: LiteralExpression<Object>('x'),
      );
      expect(sf.name, 'step');
    });

    test('fromJson parses step with stops', () {
      final json = {
        'name': 'step',
        'args': [
          {'name': 'property', 'args': ['population']},
          '#ffffff', // default
          1000, '#00ff00', // stop 1
          50000, '#ffff00', // stop 2
          1000000, '#ff0000', // stop 3
        ],
      };
      final func = GeoStylerFunction.fromJson(json) as StepFunction;
      expect(func.input, isA<FunctionExpression<Object>>());
      expect(
        (func.defaultValue as LiteralExpression<Object>).value,
        '#ffffff',
      );
      expect(func.stops.length, 3);
      expect(
        (func.stops[0].boundary as LiteralExpression<Object>).value,
        1000,
      );
      expect(
        (func.stops[0].value as LiteralExpression<Object>).value,
        '#00ff00',
      );
    });

    test('fromJson with no stops', () {
      final json = {
        'name': 'step',
        'args': [
          {'name': 'property', 'args': ['val']},
          'default',
        ],
      };
      final func = GeoStylerFunction.fromJson(json) as StepFunction;
      expect(func.stops, isEmpty);
    });

    test('round-trip', () {
      const original = StepFunction(
        input: FunctionExpression<Object>(PropertyGet('zoom')),
        defaultValue: LiteralExpression<Object>(1.0),
        stops: [
          StepParameter(
            boundary: LiteralExpression<Object>(5),
            value: LiteralExpression<Object>(2.0),
          ),
          StepParameter(
            boundary: LiteralExpression<Object>(10),
            value: LiteralExpression<Object>(4.0),
          ),
        ],
      );
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });

    test('equality', () {
      const a = StepFunction(
        input: LiteralExpression<Object>(5),
        defaultValue: LiteralExpression<Object>('a'),
        stops: [
          StepParameter(
            boundary: LiteralExpression<Object>(10),
            value: LiteralExpression<Object>('b'),
          ),
        ],
      );
      const b = StepFunction(
        input: LiteralExpression<Object>(5),
        defaultValue: LiteralExpression<Object>('a'),
        stops: [
          StepParameter(
            boundary: LiteralExpression<Object>(10),
            value: LiteralExpression<Object>('b'),
          ),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('InterpolateFunction', () {
    test('name getter', () {
      const ip = InterpolateFunction(
        mode: ['linear'],
        input: LiteralExpression<Object>(0),
      );
      expect(ip.name, 'interpolate');
    });

    test('fromJson parses linear interpolation', () {
      final json = {
        'name': 'interpolate',
        'args': [
          ['linear'],
          {'name': 'property', 'args': ['elevation']},
          0, '#0000ff',
          1000, '#00ff00',
          3000, '#ff0000',
        ],
      };
      final func =
          GeoStylerFunction.fromJson(json) as InterpolateFunction;
      expect(func.mode, ['linear']);
      expect(func.input, isA<FunctionExpression<Object>>());
      expect(func.stops.length, 3);
      expect(
        (func.stops[0].stop as LiteralExpression<Object>).value,
        0,
      );
      expect(
        (func.stops[2].value as LiteralExpression<Object>).value,
        '#ff0000',
      );
    });

    test('fromJson parses exponential mode', () {
      final json = {
        'name': 'interpolate',
        'args': [
          ['exponential', 1.5],
          {'name': 'property', 'args': ['zoom']},
          1, 1.0,
          18, 20.0,
        ],
      };
      final func =
          GeoStylerFunction.fromJson(json) as InterpolateFunction;
      expect(func.mode, ['exponential', 1.5]);
      expect(func.stops.length, 2);
    });

    test('fromJson parses cubic mode', () {
      final json = {
        'name': 'interpolate',
        'args': [
          ['cubic'],
          0,
          0, 0.0,
          100, 1.0,
        ],
      };
      final func =
          GeoStylerFunction.fromJson(json) as InterpolateFunction;
      expect(func.mode, ['cubic']);
    });

    test('round-trip', () {
      const original = InterpolateFunction(
        mode: ['linear'],
        input: FunctionExpression<Object>(PropertyGet('temp')),
        stops: [
          InterpolateParameter(
            stop: LiteralExpression<Object>(0),
            value: LiteralExpression<Object>('#0000ff'),
          ),
          InterpolateParameter(
            stop: LiteralExpression<Object>(30),
            value: LiteralExpression<Object>('#ff0000'),
          ),
        ],
      );
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });

    test('equality', () {
      const a = InterpolateFunction(
        mode: ['linear'],
        input: LiteralExpression<Object>(0),
        stops: [
          InterpolateParameter(
            stop: LiteralExpression<Object>(0),
            value: LiteralExpression<Object>(0.0),
          ),
        ],
      );
      const b = InterpolateFunction(
        mode: ['linear'],
        input: LiteralExpression<Object>(0),
        stops: [
          InterpolateParameter(
            stop: LiteralExpression<Object>(0),
            value: LiteralExpression<Object>(0.0),
          ),
        ],
      );
      const c = InterpolateFunction(
        mode: ['cubic'],
        input: LiteralExpression<Object>(0),
        stops: [],
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });
}
