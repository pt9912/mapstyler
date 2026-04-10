/// Converts between ARGB integers (flutter_map_sld) and hex color strings
/// (mapstyler_style / GeoStyler).
library;

/// Converts an ARGB integer to a `#rrggbb` hex string.
///
/// The alpha channel is returned separately via [argbToOpacity].
String argbToHex(int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return '#${_hex(r)}${_hex(g)}${_hex(b)}';
}

/// Extracts the alpha channel from an ARGB integer as an opacity value
/// (0.0–1.0).
///
/// Returns `null` when fully opaque (alpha == 0xFF), since the default
/// opacity is 1.0 and omitting it keeps the output concise.
double? argbToOpacity(int argb) {
  final a = (argb >> 24) & 0xFF;
  if (a == 0xFF) return null;
  return a / 255.0;
}

/// Converts a `#rrggbb` or `#rrggbbaa` hex string to an ARGB integer.
///
/// [opacity] overrides the alpha channel (0.0–1.0). When `null` and no
/// alpha digits are present in [hex], defaults to fully opaque.
int hexToArgb(String hex, {double? opacity}) {
  var h = hex.startsWith('#') ? hex.substring(1) : hex;
  int a;
  if (opacity != null) {
    a = (opacity * 255).round();
  } else if (h.length == 8) {
    a = int.parse(h.substring(6, 8), radix: 16);
    h = h.substring(0, 6);
  } else {
    a = 0xFF;
  }
  if (h.length == 3) {
    h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
  }
  final rgb = int.parse(h.substring(0, 6), radix: 16);
  return (a << 24) | rgb;
}

String _hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
