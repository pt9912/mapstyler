import 'package:xml/xml.dart';

/// Shared XML helper functions for QML parsing and writing.
class XmlHelpers {
  const XmlHelpers._();

  /// Extract properties from a `<layer>` element.
  ///
  /// Supports both formats:
  /// - **New** (QGIS >= 3.26): `<Option type="Map"><Option name="..." value="..."/></Option>`
  /// - **Old** (QGIS < 3.26): `<prop k="..." v="..."/>`
  static Map<String, String> extractProperties(XmlElement element) {
    final props = <String, String>{};

    // New format: <Option type="Map">
    final optionMap = element.findElements('Option').where(
      (e) => e.getAttribute('type') == 'Map',
    );
    if (optionMap.isNotEmpty) {
      for (final opt in optionMap.first.findElements('Option')) {
        final name = opt.getAttribute('name');
        final value = opt.getAttribute('value');
        if (name != null && value != null) {
          props[name] = value;
        }
      }
      return props;
    }

    // Old format: <prop k="..." v="..."/>
    for (final prop in element.findElements('prop')) {
      final k = prop.getAttribute('k');
      final v = prop.getAttribute('v');
      if (k != null && v != null) {
        props[k] = v;
      }
    }

    return props;
  }

  /// Parse "0"/"1" or "true"/"false" to bool.
  static bool parseBool(String? value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    return value == '1' || value.toLowerCase() == 'true';
  }

  /// Tolerantly parse a numeric string.
  static double? parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  /// Tolerantly parse an integer string.
  static int? parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }
}
