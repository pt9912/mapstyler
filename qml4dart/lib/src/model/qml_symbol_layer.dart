import 'qml_types.dart';

/// Smallest styling unit inside a QML symbol.
class QmlSymbolLayer {
  const QmlSymbolLayer({
    required this.type,
    required this.className,
    this.enabled = true,
    this.locked = false,
    this.pass = 0,
    this.properties = const <String, String>{},
  });

  final QmlSymbolLayerType type;
  final String className;
  final bool enabled;
  final bool locked;
  final int pass;
  final Map<String, String> properties;
}
