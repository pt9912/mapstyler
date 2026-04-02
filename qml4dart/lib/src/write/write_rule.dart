import 'package:xml/xml.dart';

import '../model/qml_rule.dart';

/// Writes [QmlRule]s as `<rules>` / `<rule>` elements to QML XML.
///
/// Supports nested rules: a rule with [QmlRule.children] is written
/// as a parent element containing child `<rule>` elements.
class WriteRule {
  const WriteRule();

  /// Wraps all [rules] in a `<rules key="renderer_rules">` element.
  void writeRules(XmlBuilder builder, List<QmlRule> rules) {
    builder.element('rules', attributes: {'key': 'renderer_rules'}, nest: () {
      for (final rule in rules) {
        writeRule(builder, rule);
      }
    });
  }

  void writeRule(XmlBuilder builder, QmlRule rule) {
    final attrs = <String, String>{};
    if (rule.key != null) attrs['key'] = rule.key!;
    if (rule.symbolKey != null) attrs['symbol'] = rule.symbolKey!;
    if (rule.label != null) attrs['label'] = rule.label!;
    if (rule.filter != null) attrs['filter'] = rule.filter!;
    if (rule.scaleMinDenominator != null) {
      attrs['scalemindenom'] = rule.scaleMinDenominator!.toStringAsFixed(0);
    }
    if (rule.scaleMaxDenominator != null) {
      attrs['scalemaxdenom'] = rule.scaleMaxDenominator!.toStringAsFixed(0);
    }
    if (!rule.enabled) attrs['checkstate'] = '0';

    if (rule.children.isEmpty) {
      builder.element('rule', attributes: attrs);
    } else {
      builder.element('rule', attributes: attrs, nest: () {
        for (final child in rule.children) {
          writeRule(builder, child);
        }
      });
    }
  }
}
