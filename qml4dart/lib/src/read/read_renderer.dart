import 'package:xml/xml.dart';

import '../model/qml_category.dart';
import '../model/qml_range.dart';
import '../model/qml_renderer.dart';
import '../model/qml_rule.dart';
import '../model/qml_symbol.dart';
import '../model/qml_types.dart';
import '../xml/xml_helpers.dart';
import 'read_rule.dart';
import 'read_symbol.dart';

/// Reads a `<renderer-v2>` element into a [QmlRenderer].
class ReadRenderer {
  const ReadRenderer();

  static const _symbolReader = ReadSymbol();
  static const _ruleReader = ReadRule();

  QmlRenderer readRenderer(XmlElement element, List<String> warnings) {
    final typeStr = element.getAttribute('type') ?? '';
    final type = QmlRendererType.fromString(typeStr);

    if (type == QmlRendererType.unknown) {
      warnings.add('Unknown renderer type: $typeStr');
    }

    // Shared symbols
    var symbols = <String, QmlSymbol>{};
    final symbolsEl = element.findElements('symbols').firstOrNull;
    if (symbolsEl != null) {
      symbols = _symbolReader.readSymbols(symbolsEl, warnings);
    }

    // Renderer-level properties
    final properties = <String, String>{};
    for (final attr in [
      'forceraster',
      'symbollevels',
      'enableorderby',
      'referencescale',
    ]) {
      final val = element.getAttribute(attr);
      if (val != null) properties[attr] = val;
    }

    // Categories (categorized renderer)
    final categories = <QmlCategory>[];
    final categoriesEl = element.findElements('categories').firstOrNull;
    if (categoriesEl != null) {
      for (final el in categoriesEl.findElements('category')) {
        categories.add(_readCategory(el));
      }
    }

    // Ranges (graduated renderer)
    final ranges = <QmlRange>[];
    final rangesEl = element.findElements('ranges').firstOrNull;
    if (rangesEl != null) {
      for (final el in rangesEl.findElements('range')) {
        ranges.add(_readRange(el));
      }
    }

    // Rules (rule-based renderer)
    var rules = <QmlRule>[];
    final rulesEl = element.findElements('rules').firstOrNull;
    if (rulesEl != null) {
      rules = _ruleReader.readRules(rulesEl, warnings);
    }

    return QmlRenderer(
      type: type,
      attribute: element.getAttribute('attr'),
      graduatedMethod: element.getAttribute('graduatedMethod'),
      symbols: symbols,
      categories: categories,
      ranges: ranges,
      rules: rules,
      properties: properties,
    );
  }

  QmlCategory _readCategory(XmlElement element) {
    return QmlCategory(
      value: element.getAttribute('value') ?? '',
      symbolKey: element.getAttribute('symbol') ?? '0',
      label: element.getAttribute('label'),
      render: XmlHelpers.parseBool(
        element.getAttribute('render'),
        defaultValue: true,
      ),
    );
  }

  QmlRange _readRange(XmlElement element) {
    return QmlRange(
      lower: XmlHelpers.parseDouble(element.getAttribute('lower')) ?? 0,
      upper: XmlHelpers.parseDouble(element.getAttribute('upper')) ?? 0,
      symbolKey: element.getAttribute('symbol') ?? '0',
      label: element.getAttribute('label'),
      render: XmlHelpers.parseBool(
        element.getAttribute('render'),
        defaultValue: true,
      ),
    );
  }
}
