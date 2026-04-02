import 'package:xml/xml.dart';

import '../model/qml_symbol.dart';
import '../model/qml_symbol_layer.dart';
import '../model/qml_types.dart';
import '../xml/xml_helpers.dart';

/// Reads `<symbols>` and `<symbol>` elements from QML XML.
class ReadSymbol {
  const ReadSymbol();

  /// Parse a `<symbols>` block into a name-keyed map.
  Map<String, QmlSymbol> readSymbols(
    XmlElement symbolsElement,
    List<String> warnings,
  ) {
    final result = <String, QmlSymbol>{};
    for (final el in symbolsElement.findElements('symbol')) {
      final name = el.getAttribute('name');
      if (name == null) {
        warnings.add('Symbol without name attribute, skipping');
        continue;
      }
      result[name] = readSymbol(el, warnings);
    }
    return result;
  }

  /// Parse a single `<symbol>` element.
  QmlSymbol readSymbol(XmlElement element, List<String> warnings) {
    final typeStr = element.getAttribute('type') ?? '';
    final type = QmlSymbolType.fromString(typeStr);
    if (type == QmlSymbolType.unknown) {
      warnings.add('Unknown symbol type: $typeStr');
    }

    final layers = <QmlSymbolLayer>[];
    for (final layerEl in element.findElements('layer')) {
      layers.add(_readSymbolLayer(layerEl, warnings));
    }

    return QmlSymbol(
      type: type,
      name: element.getAttribute('name'),
      alpha: XmlHelpers.parseDouble(element.getAttribute('alpha')) ?? 1.0,
      clipToExtent: XmlHelpers.parseBool(
        element.getAttribute('clip_to_extent'),
        defaultValue: true,
      ),
      forceRhr: XmlHelpers.parseBool(element.getAttribute('force_rhr')),
      layers: layers,
    );
  }

  QmlSymbolLayer _readSymbolLayer(
    XmlElement element,
    List<String> warnings,
  ) {
    final className = element.getAttribute('class') ?? 'Unknown';
    final type = QmlSymbolLayerType.fromClassName(className);

    if (type == QmlSymbolLayerType.unknown) {
      warnings.add('Unknown symbol layer class: $className');
    }

    return QmlSymbolLayer(
      type: type,
      className: className,
      enabled: XmlHelpers.parseBool(
        element.getAttribute('enabled'),
        defaultValue: true,
      ),
      locked: XmlHelpers.parseBool(element.getAttribute('locked')),
      pass: XmlHelpers.parseInt(element.getAttribute('pass')) ?? 0,
      properties: XmlHelpers.extractProperties(element),
    );
  }
}
