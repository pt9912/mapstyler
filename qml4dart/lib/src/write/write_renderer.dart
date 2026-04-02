import 'package:xml/xml.dart';

import '../model/qml_renderer.dart';
import 'write_rule.dart';
import 'write_symbol.dart';

/// Writes a `<renderer-v2>` element to QML XML.
class WriteRenderer {
  const WriteRenderer();

  static const _symbolWriter = WriteSymbol();
  static const _ruleWriter = WriteRule();

  void writeRenderer(XmlBuilder builder, QmlRenderer renderer) {
    final attrs = <String, String>{
      'type': renderer.type.toQmlString(),
    };
    if (renderer.attribute != null) attrs['attr'] = renderer.attribute!;
    if (renderer.graduatedMethod != null) {
      attrs['graduatedMethod'] = renderer.graduatedMethod!;
    }
    attrs.addAll(renderer.properties);

    builder.element('renderer-v2', attributes: attrs, nest: () {
      // Categories
      if (renderer.categories.isNotEmpty) {
        builder.element('categories', nest: () {
          for (final cat in renderer.categories) {
            final catAttrs = <String, String>{
              'value': cat.value,
              'symbol': cat.symbolKey,
              'render': cat.render ? 'true' : 'false',
            };
            if (cat.label != null) catAttrs['label'] = cat.label!;
            builder.element('category', attributes: catAttrs);
          }
        });
      }

      // Ranges
      if (renderer.ranges.isNotEmpty) {
        builder.element('ranges', nest: () {
          for (final range in renderer.ranges) {
            final rangeAttrs = <String, String>{
              'lower': range.lower.toStringAsFixed(15),
              'upper': range.upper.toStringAsFixed(15),
              'symbol': range.symbolKey,
              'render': range.render ? 'true' : 'false',
            };
            if (range.label != null) rangeAttrs['label'] = range.label!;
            builder.element('range', attributes: rangeAttrs);
          }
        });
      }

      // Rules
      if (renderer.rules.isNotEmpty) {
        _ruleWriter.writeRules(builder, renderer.rules);
      }

      // Symbols
      if (renderer.symbols.isNotEmpty) {
        _symbolWriter.writeSymbols(builder, renderer.symbols);
      }

      // Standard empty elements for compatibility
      builder.element('rotation');
      builder.element('sizescale');
    });
  }
}
