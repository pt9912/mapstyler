import 'qml_category.dart';
import 'qml_range.dart';
import 'qml_rule.dart';
import 'qml_symbol.dart';
import 'qml_types.dart';

/// Renderer definition inside a QML document (`<renderer-v2>`).
///
/// The [type] determines which child collections are populated:
/// - [QmlRendererType.singleSymbol] — one entry in [symbols] at key `"0"`.
/// - [QmlRendererType.categorizedSymbol] — [categories] + [symbols],
///   classified by [attribute].
/// - [QmlRendererType.graduatedSymbol] — [ranges] + [symbols],
///   classified by [attribute] with [graduatedMethod].
/// - [QmlRendererType.ruleRenderer] — [rules] + [symbols].
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

  /// The renderer kind (single, categorized, graduated, rule-based).
  final QmlRendererType type;

  /// Classification field name (`attr` attribute). Used by categorized and
  /// graduated renderers.
  final String? attribute;

  /// Graduated classification method, e.g. `"GraduatedColor"` or
  /// `"GraduatedSize"`. Only set for graduated renderers.
  final String? graduatedMethod;

  /// Shared symbol map keyed by string index (e.g. `"0"`, `"1"`).
  /// Categories, ranges, and rules reference symbols by these keys.
  final Map<String, QmlSymbol> symbols;

  /// Category entries mapping field values to symbols.
  /// Populated for [QmlRendererType.categorizedSymbol].
  final List<QmlCategory> categories;

  /// Numeric range entries mapping value intervals to symbols.
  /// Populated for [QmlRendererType.graduatedSymbol].
  final List<QmlRange> ranges;

  /// Filter-based rules, optionally nested.
  /// Populated for [QmlRendererType.ruleRenderer].
  final List<QmlRule> rules;

  /// Renderer-level XML attributes (`forceraster`, `symbollevels`, etc.).
  final Map<String, String> properties;
}
