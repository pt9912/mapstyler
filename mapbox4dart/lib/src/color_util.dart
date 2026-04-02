/// Normalizes a Mapbox color string to `#rrggbb` hex with separate opacity.
///
/// Supports: `#rgb`, `#rrggbb`, `rgb(r,g,b)`, `rgba(r,g,b,a)`,
/// `hsl(h,s%,l%)`, `hsla(h,s%,l%,a)`, and CSS named colors.
///
/// Returns `null` if the input cannot be parsed.
({String hex, double? opacity})? normalizeColor(String input) {
  final s = input.trim().toLowerCase();

  // Hex
  if (s.startsWith('#')) {
    return _parseHex(s);
  }

  // rgba(r, g, b, a)
  if (s.startsWith('rgba(') && s.endsWith(')')) {
    final parts = _parseArgs(s, 'rgba(');
    if (parts.length == 4) {
      final r = int.tryParse(parts[0]);
      final g = int.tryParse(parts[1]);
      final b = int.tryParse(parts[2]);
      final a = double.tryParse(parts[3]);
      if (r != null && g != null && b != null && a != null) {
        return (hex: _toHex(r, g, b), opacity: a < 1.0 ? a : null);
      }
    }
    return null;
  }

  // rgb(r, g, b)
  if (s.startsWith('rgb(') && s.endsWith(')')) {
    final parts = _parseArgs(s, 'rgb(');
    if (parts.length == 3) {
      final r = int.tryParse(parts[0]);
      final g = int.tryParse(parts[1]);
      final b = int.tryParse(parts[2]);
      if (r != null && g != null && b != null) {
        return (hex: _toHex(r, g, b), opacity: null);
      }
    }
    return null;
  }

  // hsla(h, s%, l%, a)
  if (s.startsWith('hsla(') && s.endsWith(')')) {
    final parts = _parseArgs(s, 'hsla(');
    if (parts.length == 4) {
      return _parseHsl(parts[0], parts[1], parts[2],
          alpha: double.tryParse(parts[3]));
    }
    return null;
  }

  // hsl(h, s%, l%)
  if (s.startsWith('hsl(') && s.endsWith(')')) {
    final parts = _parseArgs(s, 'hsl(');
    if (parts.length == 3) {
      return _parseHsl(parts[0], parts[1], parts[2]);
    }
    return null;
  }

  // Named colors
  final named = _namedColors[s];
  if (named != null) {
    return (hex: named, opacity: s == 'transparent' ? 0.0 : null);
  }

  return null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _parseArgs(String s, String prefix) =>
    s.substring(prefix.length, s.length - 1).split(',').map((p) => p.trim().replaceAll('%', '')).toList();

final _hexDigit = RegExp(r'^[0-9a-f]+$');

({String hex, double? opacity})? _parseHex(String s) {
  var h = s.substring(1);
  if (!_hexDigit.hasMatch(h)) return null;
  if (h.length == 3) {
    h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
  } else if (h.length == 4) {
    final a = int.parse('${h[3]}${h[3]}', radix: 16) / 255.0;
    h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
    return (hex: '#$h', opacity: a < 1.0 ? a : null);
  } else if (h.length == 8) {
    final a = int.parse(h.substring(6), radix: 16) / 255.0;
    h = h.substring(0, 6);
    return (hex: '#$h', opacity: a < 1.0 ? a : null);
  } else if (h.length != 6) {
    return null;
  }
  return (hex: '#$h', opacity: null);
}

({String hex, double? opacity})? _parseHsl(
  String hStr, String sStr, String lStr,
  {double? alpha}) {
  final h = double.tryParse(hStr);
  final s = (double.tryParse(sStr) ?? 0) / 100;
  final l = (double.tryParse(lStr) ?? 0) / 100;
  if (h == null) return null;

  // HSL to RGB
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = l - c / 2;

  double r1, g1, b1;
  if (h < 60) {
    (r1, g1, b1) = (c, x, 0.0);
  } else if (h < 120) {
    (r1, g1, b1) = (x, c, 0.0);
  } else if (h < 180) {
    (r1, g1, b1) = (0.0, c, x);
  } else if (h < 240) {
    (r1, g1, b1) = (0.0, x, c);
  } else if (h < 300) {
    (r1, g1, b1) = (x, 0.0, c);
  } else {
    (r1, g1, b1) = (c, 0.0, x);
  }

  final r = ((r1 + m) * 255).round().clamp(0, 255);
  final g = ((g1 + m) * 255).round().clamp(0, 255);
  final b = ((b1 + m) * 255).round().clamp(0, 255);

  return (
    hex: _toHex(r, g, b),
    opacity: alpha != null && alpha < 1.0 ? alpha : null,
  );
}

String _toHex(int r, int g, int b) =>
    '#${_h(r)}${_h(g)}${_h(b)}';

String _h(int v) => v.toRadixString(16).padLeft(2, '0');

const _namedColors = <String, String>{
  'transparent': '#000000',
  'black': '#000000',
  'white': '#ffffff',
  'red': '#ff0000',
  'green': '#008000',
  'blue': '#0000ff',
  'yellow': '#ffff00',
  'cyan': '#00ffff',
  'magenta': '#ff00ff',
  'orange': '#ffa500',
  'purple': '#800080',
  'pink': '#ffc0cb',
  'brown': '#a52a2a',
  'gray': '#808080',
  'grey': '#808080',
  'silver': '#c0c0c0',
  'gold': '#ffd700',
  'navy': '#000080',
  'teal': '#008080',
  'olive': '#808000',
  'maroon': '#800000',
  'aqua': '#00ffff',
  'fuchsia': '#ff00ff',
  'lime': '#00ff00',
  'coral': '#ff7f50',
  'salmon': '#fa8072',
  'tomato': '#ff6347',
  'khaki': '#f0e68c',
  'crimson': '#dc143c',
  'indigo': '#4b0082',
  'violet': '#ee82ee',
  'plum': '#dda0dd',
  'orchid': '#da70d6',
  'sienna': '#a0522d',
  'tan': '#d2b48c',
  'beige': '#f5f5dc',
  'ivory': '#fffff0',
  'linen': '#faf0e6',
  'wheat': '#f5deb3',
  'chocolate': '#d2691e',
  'firebrick': '#b22222',
  'darkred': '#8b0000',
  'darkgreen': '#006400',
  'darkblue': '#00008b',
  'darkcyan': '#008b8b',
  'darkmagenta': '#8b008b',
  'darkgray': '#a9a9a9',
  'darkgrey': '#a9a9a9',
  'lightgray': '#d3d3d3',
  'lightgrey': '#d3d3d3',
  'lightblue': '#add8e6',
  'lightgreen': '#90ee90',
  'lightyellow': '#ffffe0',
  'lightcoral': '#f08080',
  'lightsalmon': '#ffa07a',
  'lightpink': '#ffb6c1',
  'lightcyan': '#e0ffff',
  'lightsteelblue': '#b0c4de',
  'steelblue': '#4682b4',
  'royalblue': '#4169e1',
  'dodgerblue': '#1e90ff',
  'deepskyblue': '#00bfff',
  'skyblue': '#87ceeb',
  'midnightblue': '#191970',
  'cornflowerblue': '#6495ed',
  'slateblue': '#6a5acd',
  'mediumblue': '#0000cd',
  'darkslateblue': '#483d8b',
  'mediumslateblue': '#7b68ee',
  'mediumpurple': '#9370db',
  'mediumorchid': '#ba55d3',
  'mediumvioletred': '#c71585',
  'darkviolet': '#9400d3',
  'darkorchid': '#9932cc',
  'deeppink': '#ff1493',
  'hotpink': '#ff69b4',
  'palevioletred': '#db7093',
  'springgreen': '#00ff7f',
  'mediumspringgreen': '#00fa9a',
  'lawngreen': '#7cfc00',
  'chartreuse': '#7fff00',
  'greenyellow': '#adff2f',
  'yellowgreen': '#9acd32',
  'olivedrab': '#6b8e23',
  'darkolivegreen': '#556b2f',
  'forestgreen': '#228b22',
  'limegreen': '#32cd32',
  'mediumseagreen': '#3cb371',
  'seagreen': '#2e8b57',
  'darkseagreen': '#8fbc8f',
  'palegreen': '#98fb98',
  'mediumaquamarine': '#66cdaa',
  'aquamarine': '#7fffd4',
  'turquoise': '#40e0d0',
  'mediumturquoise': '#48d1cc',
  'darkturquoise': '#00ced1',
  'cadetblue': '#5f9ea0',
  'peru': '#cd853f',
  'sandybrown': '#f4a460',
  'goldenrod': '#daa520',
  'darkgoldenrod': '#b8860b',
  'rosybrown': '#bc8f8f',
  'indianred': '#cd5c5c',
  'saddlebrown': '#8b4513',
  'burlywood': '#deb887',
  'moccasin': '#ffe4b5',
  'navajowhite': '#ffdead',
  'peachpuff': '#ffdab9',
  'mistyrose': '#ffe4e1',
  'lavenderblush': '#fff0f5',
  'lavender': '#e6e6fa',
  'thistle': '#d8bfd8',
  'blanchedalmond': '#ffebcd',
  'papayawhip': '#ffefd5',
  'antiquewhite': '#faebd7',
  'cornsilk': '#fff8dc',
  'lemonchiffon': '#fffacd',
  'oldlace': '#fdf5e6',
  'seashell': '#fff5ee',
  'floralwhite': '#fffaf0',
  'snow': '#fffafa',
  'mintcream': '#f5fffa',
  'azure': '#f0ffff',
  'aliceblue': '#f0f8ff',
  'ghostwhite': '#f8f8ff',
  'whitesmoke': '#f5f5f5',
  'honeydew': '#f0fff0',
  'gainsboro': '#dcdcdc',
  'dimgray': '#696969',
  'dimgrey': '#696969',
  'slategray': '#708090',
  'slategrey': '#708090',
  'lightslategray': '#778899',
  'lightslategrey': '#778899',
  'darkslategray': '#2f4f4f',
  'darkslategrey': '#2f4f4f',
};
