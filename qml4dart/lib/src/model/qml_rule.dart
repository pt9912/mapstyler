/// Rule in a QGIS rule-based renderer.
class QmlRule {
  const QmlRule({
    this.key,
    this.symbolKey,
    this.label,
    this.filter,
    this.scaleMinDenominator,
    this.scaleMaxDenominator,
    this.enabled = true,
    this.children = const <QmlRule>[],
  });

  /// Unique rule identifier.
  final String? key;

  /// Key referencing a symbol in the renderer's symbol map.
  /// Null for grouping-only rules.
  final String? symbolKey;

  /// Display label.
  final String? label;

  /// QGIS filter expression string.
  final String? filter;

  final double? scaleMinDenominator;
  final double? scaleMaxDenominator;

  /// Whether this rule is active (`checkstate` != "0").
  final bool enabled;

  /// Nested child rules for hierarchical filtering.
  final List<QmlRule> children;
}
