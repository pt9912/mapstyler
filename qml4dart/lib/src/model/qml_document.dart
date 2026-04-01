import 'qml_renderer.dart';

/// Root model for a QGIS QML document.
class QmlDocument {
  const QmlDocument({
    this.version,
    this.name,
    required this.renderer,
    this.customProperties = const <String, String>{},
  });

  final String? version;
  final String? name;
  final QmlRenderer renderer;
  final Map<String, String> customProperties;
}
