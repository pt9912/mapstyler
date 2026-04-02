/// A rule in a QGIS rule-based renderer.
///
/// Rules form a tree: a rule without [symbolKey] but with [children] acts
/// as a grouping node whose [filter] is ANDed with each child's filter.
/// Leaf rules reference a symbol and optionally define scale visibility.
///
/// QML: `<rule key="r0" symbol="0" label="Roads" filter="type = 'road'"
///        scalemindenom="100" scalemaxdenom="5000"/>`
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

  /// Unique rule identifier (`key` attribute).
  final String? key;

  /// Key referencing a symbol in the renderer's symbol map.
  /// `null` for grouping-only rules that only carry a filter.
  final String? symbolKey;

  /// Human-readable display label shown in the QGIS legend.
  final String? label;

  /// QGIS filter expression string (e.g. `"type = 'road'"`).
  final String? filter;

  /// Minimum scale denominator at which the rule is active
  /// (`scalemindenom`). Features below this zoom level are hidden.
  final double? scaleMinDenominator;

  /// Maximum scale denominator at which the rule is active
  /// (`scalemaxdenom`). Features above this zoom level are hidden.
  final double? scaleMaxDenominator;

  /// Whether this rule is active (`checkstate` != `"0"`).
  final bool enabled;

  /// Nested child rules for hierarchical filtering.
  final List<QmlRule> children;
}
