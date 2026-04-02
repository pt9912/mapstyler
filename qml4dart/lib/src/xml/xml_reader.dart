import 'package:xml/xml.dart';

import '../model/qml_document.dart';
import '../read/read_renderer.dart';
import '../read/read_result.dart';
import '../xml/xml_helpers.dart';

/// Top-level XML reader: QML string → [QmlDocument].
class QmlXmlReader {
  const QmlXmlReader();

  static const _rendererReader = ReadRenderer();

  ReadQmlResult read(String xmlString) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xmlString);
    } on XmlException catch (e) {
      return ReadQmlFailure('XML parsing error: ${e.message}', cause: e);
    }

    try {
      final root = document.rootElement;

      if (root.name.local != 'qgis') {
        return ReadQmlFailure(
          'Expected root element <qgis>, got <${root.name.local}>',
        );
      }

      final warnings = <String>[];

      final rendererEl = root.findElements('renderer-v2').firstOrNull;
      if (rendererEl == null) {
        return const ReadQmlFailure('Missing <renderer-v2> element');
      }

      final renderer = _rendererReader.readRenderer(rendererEl, warnings);

      return ReadQmlSuccess(
        QmlDocument(
          version: root.getAttribute('version'),
          renderer: renderer,
          hasScaleBasedVisibility: XmlHelpers.parseBool(
            root.getAttribute('hasScaleBasedVisibilityFlag'),
          ),
          maxScale: XmlHelpers.parseDouble(root.getAttribute('maxScale')),
          minScale: XmlHelpers.parseDouble(root.getAttribute('minScale')),
        ),
        warnings: warnings,
      );
    } catch (e) {
      return ReadQmlFailure('Unexpected error: $e', cause: e);
    }
  }
}
