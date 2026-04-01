import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('FillSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Fill',
        'color': '#ffcc00',
        'opacity': 0.8,
        'fillOpacity': 0.5,
        'outlineColor': '#aa8800',
        'outlineWidth': 1.5,
      };
      final sym = Symbolizer.fromJson(json) as FillSymbolizer;
      expect(sym.kind, 'Fill');
      expect((sym.color as LiteralExpression<String>).value, '#ffcc00');
      expect((sym.opacity as LiteralExpression<double>).value, 0.8);
      expect((sym.fillOpacity as LiteralExpression<double>).value, 0.5);
      expect(
        (sym.outlineColor as LiteralExpression<String>).value,
        '#aa8800',
      );
      expect((sym.outlineWidth as LiteralExpression<double>).value, 1.5);
    });

    test('fromJson minimal (only kind)', () {
      final json = {'kind': 'Fill'};
      final sym = Symbolizer.fromJson(json) as FillSymbolizer;
      expect(sym.color, isNull);
      expect(sym.opacity, isNull);
    });

    test('fromJson with function expression', () {
      final json = {
        'kind': 'Fill',
        'color': {'name': 'property', 'args': ['fillColor']},
      };
      final sym = Symbolizer.fromJson(json) as FillSymbolizer;
      expect(sym.color, isA<FunctionExpression<String>>());
      final func = (sym.color as FunctionExpression<String>).function;
      expect((func as PropertyGet).propertyName, 'fillColor');
    });

    test('round-trip', () {
      final json = {
        'kind': 'Fill',
        'color': '#ffcc00',
        'opacity': 0.5,
        'outlineColor': '#000000',
        'outlineWidth': 2.0,
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('equality', () {
      const a = FillSymbolizer(color: LiteralExpression('#ff0000'));
      const b = FillSymbolizer(color: LiteralExpression('#ff0000'));
      const c = FillSymbolizer(color: LiteralExpression('#00ff00'));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('LineSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Line',
        'color': '#333333',
        'width': 2.0,
        'opacity': 1.0,
        'dasharray': [10.0, 5.0],
        'cap': 'round',
        'join': 'round',
      };
      final sym = Symbolizer.fromJson(json) as LineSymbolizer;
      expect((sym.color as LiteralExpression<String>).value, '#333333');
      expect((sym.width as LiteralExpression<double>).value, 2.0);
      expect(sym.dasharray, [10.0, 5.0]);
      expect(sym.cap, 'round');
      expect(sym.join, 'round');
    });

    test('round-trip', () {
      final json = {
        'kind': 'Line',
        'color': '#333333',
        'width': 2.0,
        'cap': 'round',
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('equality', () {
      const a = LineSymbolizer(
        color: LiteralExpression('#000'),
        width: LiteralExpression(1.0),
      );
      const b = LineSymbolizer(
        color: LiteralExpression('#000'),
        width: LiteralExpression(1.0),
      );
      expect(a, equals(b));
    });
  });

  group('MarkSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Mark',
        'wellKnownName': 'circle',
        'radius': 8.0,
        'color': '#ff0000',
        'opacity': 1.0,
        'strokeColor': '#990000',
        'strokeWidth': 1.0,
        'rotate': 45.0,
      };
      final sym = Symbolizer.fromJson(json) as MarkSymbolizer;
      expect(sym.wellKnownName, 'circle');
      expect((sym.radius as LiteralExpression<double>).value, 8.0);
      expect((sym.rotate as LiteralExpression<double>).value, 45.0);
    });

    test('round-trip', () {
      final json = {
        'kind': 'Mark',
        'wellKnownName': 'star',
        'radius': 10.0,
        'color': '#ffcc00',
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('equality', () {
      const a = MarkSymbolizer(wellKnownName: 'circle');
      const b = MarkSymbolizer(wellKnownName: 'circle');
      const c = MarkSymbolizer(wellKnownName: 'square');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('IconSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Icon',
        'image': 'https://example.com/icon.png',
        'format': 'image/png',
        'size': 24.0,
        'opacity': 0.9,
        'rotate': 90.0,
      };
      final sym = Symbolizer.fromJson(json) as IconSymbolizer;
      expect(
        (sym.image as LiteralExpression<String>).value,
        'https://example.com/icon.png',
      );
      expect(sym.format, 'image/png');
    });

    test('fromJson with function expression for image', () {
      final json = {
        'kind': 'Icon',
        'image': {'name': 'property', 'args': ['iconUrl']},
      };
      final sym = Symbolizer.fromJson(json) as IconSymbolizer;
      expect(sym.image, isA<FunctionExpression<String>>());
    });

    test('round-trip', () {
      final json = {
        'kind': 'Icon',
        'image': 'marker.svg',
        'size': 16.0,
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });
  });

  group('TextSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Text',
        'label': {'name': 'property', 'args': ['name']},
        'color': '#333333',
        'size': 12.0,
        'font': 'Arial',
        'opacity': 1.0,
        'rotate': 0.0,
        'haloColor': '#ffffff',
        'haloWidth': 2.0,
        'placement': 'point',
      };
      final sym = Symbolizer.fromJson(json) as TextSymbolizer;
      expect(sym.label, isA<FunctionExpression<String>>());
      expect(sym.font, 'Arial');
      expect(sym.placement, 'point');
      expect(
        (sym.haloColor as LiteralExpression<String>).value,
        '#ffffff',
      );
      expect((sym.haloWidth as LiteralExpression<double>).value, 2.0);
    });

    test('fromJson with literal label', () {
      final json = {
        'kind': 'Text',
        'label': 'Static Label',
        'size': 14.0,
      };
      final sym = Symbolizer.fromJson(json) as TextSymbolizer;
      expect(sym.label, isA<LiteralExpression<String>>());
      expect((sym.label as LiteralExpression<String>).value, 'Static Label');
    });

    test('round-trip', () {
      final json = {
        'kind': 'Text',
        'label': 'Hello',
        'color': '#000000',
        'size': 14.0,
        'font': 'Helvetica',
        'placement': 'line',
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });
  });

  group('Symbolizer.fromJson', () {
    test('throws on unknown kind', () {
      expect(
        () => Symbolizer.fromJson({'kind': 'Unknown'}),
        throwsFormatException,
      );
    });
  });
}
