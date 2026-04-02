import 'package:flutter/widgets.dart';

/// Parses a hex color string to a Flutter [Color].
///
/// Supports `#rgb`, `#rrggbb`, and `#rrggbbaa` formats. When the input does not
/// contain an alpha channel, [opacity] is applied instead.
Color parseHexColor(String hex, {double opacity = 1.0}) {
  var h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 3) {
    h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
  }
  int a;
  if (h.length == 8) {
    a = int.parse(h.substring(6, 8), radix: 16);
    h = h.substring(0, 6);
  } else {
    a = (opacity * 255).round();
  }
  final rgb = int.parse(h.padRight(6, '0').substring(0, 6), radix: 16);
  return Color((a << 24) | rgb);
}
