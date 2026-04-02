import 'package:mapbox4dart/mapbox4dart.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeColor', () {
    group('hex', () {
      test('#rrggbb', () {
        final r = normalizeColor('#ff0080');
        expect(r?.hex, '#ff0080');
        expect(r?.opacity, isNull);
      });

      test('#rgb short form', () {
        final r = normalizeColor('#f00');
        expect(r?.hex, '#ff0000');
        expect(r?.opacity, isNull);
      });

      test('#rrggbbaa with alpha', () {
        final r = normalizeColor('#ff000080');
        expect(r?.hex, '#ff0000');
        expect(r?.opacity, closeTo(0.502, 0.01));
      });

      test('#rgba short form with alpha', () {
        final r = normalizeColor('#f008');
        expect(r?.hex, '#ff0000');
        expect(r?.opacity, closeTo(0.533, 0.01));
      });

      test('fully opaque alpha returns null opacity', () {
        final r = normalizeColor('#ff0000ff');
        expect(r?.hex, '#ff0000');
        expect(r?.opacity, isNull);
      });

      test('invalid hex returns null', () {
        expect(normalizeColor('#xyz'), isNull);
      });
    });

    group('rgb', () {
      test('rgb(r, g, b)', () {
        final r = normalizeColor('rgb(255, 0, 128)');
        expect(r?.hex, '#ff0080');
        expect(r?.opacity, isNull);
      });

      test('handles whitespace', () {
        final r = normalizeColor('  rgb( 0 , 255 , 0 )  ');
        expect(r?.hex, '#00ff00');
      });
    });

    group('rgba', () {
      test('rgba(r, g, b, a)', () {
        final r = normalizeColor('rgba(255, 0, 0, 0.5)');
        expect(r?.hex, '#ff0000');
        expect(r?.opacity, 0.5);
      });

      test('fully opaque alpha returns null', () {
        final r = normalizeColor('rgba(0, 0, 0, 1.0)');
        expect(r?.hex, '#000000');
        expect(r?.opacity, isNull);
      });
    });

    group('hsl', () {
      test('hsl(0, 100%, 50%) is red', () {
        final r = normalizeColor('hsl(0, 100%, 50%)');
        expect(r?.hex, '#ff0000');
        expect(r?.opacity, isNull);
      });

      test('hsl(120, 100%, 50%) is green', () {
        final r = normalizeColor('hsl(120, 100%, 50%)');
        expect(r?.hex, '#00ff00');
      });

      test('hsl(240, 100%, 50%) is blue', () {
        final r = normalizeColor('hsl(240, 100%, 50%)');
        expect(r?.hex, '#0000ff');
      });
    });

    group('hsla', () {
      test('hsla with alpha', () {
        final r = normalizeColor('hsla(0, 100%, 50%, 0.5)');
        expect(r?.hex, '#ff0000');
        expect(r?.opacity, 0.5);
      });

      test('hsla fully opaque', () {
        final r = normalizeColor('hsla(0, 100%, 50%, 1.0)');
        expect(r?.opacity, isNull);
      });
    });

    group('named colors', () {
      test('red', () {
        expect(normalizeColor('red')?.hex, '#ff0000');
      });

      test('blue', () {
        expect(normalizeColor('blue')?.hex, '#0000ff');
      });

      test('transparent', () {
        final r = normalizeColor('transparent');
        expect(r?.hex, '#000000');
        expect(r?.opacity, 0.0);
      });

      test('case insensitive', () {
        expect(normalizeColor('Red')?.hex, '#ff0000');
        expect(normalizeColor('BLUE')?.hex, '#0000ff');
      });

      test('unknown name returns null', () {
        expect(normalizeColor('notacolor'), isNull);
      });
    });

    test('empty string returns null', () {
      expect(normalizeColor(''), isNull);
    });
  });
}
