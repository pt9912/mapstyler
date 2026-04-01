import 'package:mapstyler_sld_adapter/mapstyler_sld_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('argbToHex', () {
    test('converts opaque red', () {
      expect(argbToHex(0xFFFF0000), '#ff0000');
    });

    test('converts opaque white', () {
      expect(argbToHex(0xFFFFFFFF), '#ffffff');
    });

    test('converts opaque black', () {
      expect(argbToHex(0xFF000000), '#000000');
    });

    test('ignores alpha channel', () {
      // Alpha is 0x80, but argbToHex only outputs RGB.
      expect(argbToHex(0x80FF8800), '#ff8800');
    });

    test('converts GeoStyler forest green', () {
      expect(argbToHex(0xFF228B22), '#228b22');
    });
  });

  group('argbToOpacity', () {
    test('returns null for fully opaque', () {
      expect(argbToOpacity(0xFFFF0000), isNull);
    });

    test('returns 0.0 for fully transparent', () {
      expect(argbToOpacity(0x00FF0000), closeTo(0.0, 0.005));
    });

    test('returns ~0.5 for half transparent', () {
      expect(argbToOpacity(0x80FF0000), closeTo(0.502, 0.005));
    });
  });

  group('hexToArgb', () {
    test('converts 6-digit hex', () {
      expect(hexToArgb('#ff0000'), 0xFFFF0000);
    });

    test('converts without hash', () {
      expect(hexToArgb('228b22'), 0xFF228B22);
    });

    test('converts 3-digit shorthand', () {
      expect(hexToArgb('#f00'), 0xFFFF0000);
    });

    test('applies opacity override', () {
      expect(hexToArgb('#ff0000', opacity: 0.5), 0x80FF0000);
    });

    test('converts 8-digit hex with alpha', () {
      expect(hexToArgb('#ff000080'), 0x80FF0000);
    });
  });

  group('round-trip', () {
    test('opaque color survives round-trip', () {
      const argb = 0xFF228B22;
      final hex = argbToHex(argb);
      expect(hexToArgb(hex), argb);
    });

    test('hex survives round-trip', () {
      const hex = '#cc8844';
      final argb = hexToArgb(hex);
      expect(argbToHex(argb), hex);
    });
  });
}
