import 'qml_rule.dart';
import 'qml_types.dart';

/// Renderer definition for a QML document.
class QmlRenderer {
  const QmlRenderer({
    required this.type,
    this.attribute,
    this.rules = const <QmlRule>[],
    this.properties = const <String, String>{},
  });

  final QmlRendererType type;
  final String? attribute;
  final List<QmlRule> rules;
  final Map<String, String> properties;
}
