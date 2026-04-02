import 'qml_renderer.dart';

/// Root model for a QGIS QML document.
class QmlDocument {
  const QmlDocument({
    this.version,
    required this.renderer,
    this.hasScaleBasedVisibility = false,
    this.maxScale,
    this.minScale,
  });

  /// QGIS version string from the root element.
  final String? version;

  final QmlRenderer renderer;

  /// Whether layer-level scale visibility is enabled.
  final bool hasScaleBasedVisibility;

  /// Most zoomed-in scale denominator.
  final double? maxScale;

  /// Most zoomed-out scale denominator.
  final double? minScale;
}
