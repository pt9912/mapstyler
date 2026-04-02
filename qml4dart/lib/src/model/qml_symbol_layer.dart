import 'qml_types.dart';

/// Smallest styling unit inside a QML symbol (`<layer>` element).
///
/// Each layer has a [className] that determines which [properties] are
/// available. For example a `SimpleFill` layer supports `color`,
/// `outline_color`, `outline_width`, `style`, etc.
///
/// QML: `<layer class="SimpleFill" enabled="1" locked="0" pass="0">`
class QmlSymbolLayer {
  const QmlSymbolLayer({
    required this.type,
    required this.className,
    this.enabled = true,
    this.locked = false,
    this.pass = 0,
    this.properties = const <String, String>{},
  });

  /// Parsed layer type (e.g. [QmlSymbolLayerType.simpleFill]).
  final QmlSymbolLayerType type;

  /// Raw QGIS class name (e.g. `"SimpleFill"`, `"SvgMarker"`).
  final String className;

  /// Whether this layer is active. Disabled layers are preserved but
  /// not rendered.
  final bool enabled;

  /// Whether this layer is locked against interactive changes in QGIS.
  final bool locked;

  /// Rendering pass for symbol level ordering.
  final int pass;

  /// Key-value properties specific to [className]. Values are always strings
  /// (e.g. `"color"` → `"255,0,0,255"`, `"outline_width"` → `"0.26"`).
  final Map<String, String> properties;
}
