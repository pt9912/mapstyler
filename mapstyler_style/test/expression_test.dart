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
    test('fromJson throws on unknown function', () {
      expect(
        () => GeoStylerFunction.fromJson({'name': 'unknown', 'args': []}),
        throwsFormatException,
      );
    });

    test('PropertyGet round-trip', () {
      const original = PropertyGet('fieldName');
      final json = original.toJson();
      final restored = GeoStylerFunction.fromJson(json);
      expect(restored, original);
    });
  });
}
