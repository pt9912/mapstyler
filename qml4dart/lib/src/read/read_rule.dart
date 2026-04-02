import 'package:xml/xml.dart';

import '../model/qml_rule.dart';
import '../xml/xml_helpers.dart';

/// Reads `<rules>` and `<rule>` elements from QML XML.
class ReadRule {
  const ReadRule();

  /// Parse all `<rule>` children of a `<rules>` element.
  List<QmlRule> readRules(XmlElement rulesElement, List<String> warnings) {
    final rules = <QmlRule>[];
    for (final el in rulesElement.findElements('rule')) {
      rules.add(readRule(el, warnings));
    }
    return rules;
  }

  /// Parse a single `<rule>` element, including nested children.
  QmlRule readRule(XmlElement element, List<String> warnings) {
    final children = <QmlRule>[];
    for (final childEl in element.findElements('rule')) {
      children.add(readRule(childEl, warnings));
    }

    return QmlRule(
      key: element.getAttribute('key'),
      symbolKey: element.getAttribute('symbol'),
      label: element.getAttribute('label'),
      filter: element.getAttribute('filter'),
      scaleMinDenominator:
          XmlHelpers.parseDouble(element.getAttribute('scalemindenom')),
      scaleMaxDenominator:
          XmlHelpers.parseDouble(element.getAttribute('scalemaxdenom')),
      enabled: element.getAttribute('checkstate') != '0',
      children: children,
    );
  }
}
