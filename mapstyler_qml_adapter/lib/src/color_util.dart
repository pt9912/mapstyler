/// Converts between QGIS "r,g,b,a" color strings and GeoStyler "#rrggbb"
/// hex strings.

/// Converts a QGIS color string ("r,g,b,a") to a "#rrggbb" hex string.
///
/// Returns `null` if the input is null or cannot be parsed.
String? qgisColorToHex(String? color) {
  if (color == null) return null;
  final parts = color.split(',');
  if (parts.length < 3) return null;
  final r = int.tryParse(parts[0].trim());
  final g = int.tryParse(parts[1].trim());
  final b = int.tryParse(parts[2].trim());
  if (r == null || g == null || b == null) return null;
  return '#${_hex(r)}${_hex(g)}${_hex(b)}';
}

/// Extracts the alpha channel from a QGIS color string ("r,g,b,a") as an
/// opacity value (0.0–1.0).
///
/// Returns `null` when fully opaque (alpha == 255) or when not parseable.
double? qgisColorToOpacity(String? color) {
  if (color == null) return null;
  final parts = color.split(',');
  if (parts.length < 4) return null;
  final a = int.tryParse(parts[3].trim());
  if (a == null || a == 255) return null;
  return a / 255.0;
}

/// Converts a "#rrggbb" hex string and optional opacity to a QGIS
/// "r,g,b,a" color string.
String hexToQgisColor(String hex, {double? opacity}) {
  var h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 3) {
    h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
  }
  final r = int.parse(h.substring(0, 2), radix: 16);
  final g = int.parse(h.substring(2, 4), radix: 16);
  final b = int.parse(h.substring(4, 6), radix: 16);
  final a = opacity != null ? (opacity * 255).round() : 255;
  return '$r,$g,$b,$a';
}

String _hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
