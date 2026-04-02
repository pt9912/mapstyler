import 'qml_category.dart';
import 'qml_range.dart';
import 'qml_rule.dart';
import 'qml_symbol.dart';
import 'qml_types.dart';

/// Renderer definition for a QML document.
class QmlRenderer {
  const QmlRenderer({
    required this.type,
    this.attribute,
    this.graduatedMethod,
    this.symbols = const <String, QmlSymbol>{},
    this.categories = const <QmlCategory>[],
    this.ranges = const <QmlRange>[],
    this.rules = const <QmlRule>[],
    this.properties = const <String, String>{},
  });

  final QmlRendererType type;

  /// Classification field name (for categorized / graduated).
  final String? attribute;

  /// Graduated method, e.g. `GraduatedColor` (for graduated).
  final String? graduatedMethod;

  /// Shared symbol map keyed by string name (e.g. "0", "1").
  final Map<String, QmlSymbol> symbols;

  /// Category entries (for categorized renderer).
  final List<QmlCategory> categories;

  /// Range entries (for graduated renderer).
  final List<QmlRange> ranges;

  /// Rules (for rule-based renderer).
  final List<QmlRule> rules;

  /// Renderer-level properties (forceraster, symbollevels, etc.).
  final Map<String, String> properties;
}
