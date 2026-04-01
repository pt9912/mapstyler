import 'qml_types.dart';

/// Smallest styling unit inside a QML symbol.
class QmlSymbolLayer {
  const QmlSymbolLayer({
    required this.type,
    this.className,
    this.enabled = true,
    this.properties = const <String, String>{},
  });

  final QmlSymbolLayerType type;
  final String? className;
  final bool enabled;
  final Map<String, String> properties;
}
