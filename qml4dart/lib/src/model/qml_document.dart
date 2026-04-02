import 'qml_renderer.dart';

/// Root model for a QGIS QML layer style document.
///
/// Represents the top-level `<qgis>` element containing a single
/// [renderer] and optional scale-based visibility settings.
///
/// QML: `<qgis version="3.28.0" hasScaleBasedVisibilityFlag="1"
///        maxScale="1000" minScale="100000"> ... </qgis>`
class QmlDocument {
  const QmlDocument({
    this.version,
    required this.renderer,
    this.hasScaleBasedVisibility = false,
    this.maxScale,
    this.minScale,
  });

  /// QGIS version string from the `version` attribute (e.g. `"3.28.0"`).
  final String? version;

  /// The renderer that defines how features are styled.
  final QmlRenderer renderer;

  /// Whether document-level scale visibility is enabled
  /// (`hasScaleBasedVisibilityFlag="1"`).
  final bool hasScaleBasedVisibility;

  /// Most zoomed-in scale denominator (confusingly named `maxScale` in QML
  /// because it is the maximum zoom level, i.e. the *smallest* scale
  /// denominator value).
  final double? maxScale;

  /// Most zoomed-out scale denominator (`minScale` in QML — the minimum
  /// zoom level, i.e. the *largest* scale denominator value).
  final double? minScale;
}
