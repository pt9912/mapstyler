import 'package:xml/xml.dart';

import '../model/qml_symbol.dart';
import '../model/qml_symbol_layer.dart';

/// Writes `<symbols>` and `<symbol>` elements to QML XML.
class WriteSymbol {
  const WriteSymbol();

  void writeSymbols(XmlBuilder builder, Map<String, QmlSymbol> symbols) {
    builder.element('symbols', nest: () {
      for (final entry in symbols.entries) {
        _writeSymbol(builder, entry.key, entry.value);
      }
    });
  }

  void _writeSymbol(XmlBuilder builder, String key, QmlSymbol symbol) {
    builder.element('symbol', attributes: {
      'type': symbol.type.toQmlString(),
      'name': key,
      'alpha': symbol.alpha.toString(),
      'clip_to_extent': symbol.clipToExtent ? '1' : '0',
      'force_rhr': symbol.forceRhr ? '1' : '0',
    }, nest: () {
      for (final layer in symbol.layers) {
        _writeSymbolLayer(builder, layer);
      }
    });
  }

  void _writeSymbolLayer(XmlBuilder builder, QmlSymbolLayer layer) {
    builder.element('layer', attributes: {
      'class': layer.className,
      'enabled': layer.enabled ? '1' : '0',
      'locked': layer.locked ? '1' : '0',
      'pass': layer.pass.toString(),
    }, nest: () {
      builder.element('Option', attributes: {'type': 'Map'}, nest: () {
        for (final entry in layer.properties.entries) {
          builder.element('Option', attributes: {
            'name': entry.key,
            'value': entry.value,
            'type': 'QString',
          });
        }
      });
    });
  }
}
