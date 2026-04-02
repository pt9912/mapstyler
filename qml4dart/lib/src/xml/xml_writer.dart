import 'package:xml/xml.dart';

import '../model/qml_document.dart';
import '../write/write_renderer.dart';
import '../write/write_result.dart';

/// Top-level XML writer that encodes a [QmlDocument] into a QML XML string.
///
/// Builds the `<qgis>` root element with version and scale attributes,
/// then delegates renderer writing to [WriteRenderer].
class QmlXmlWriter {
  const QmlXmlWriter();

  static const _rendererWriter = WriteRenderer();

  /// Encodes [document] and returns a [WriteQmlResult].
  WriteQmlResult write(QmlDocument document) {
    try {
      final warnings = <String>[];
      final builder = XmlBuilder();

      final attrs = <String, String>{};
      if (document.version != null) attrs['version'] = document.version!;
      attrs['hasScaleBasedVisibilityFlag'] =
          document.hasScaleBasedVisibility ? '1' : '0';
      if (document.maxScale != null) {
        attrs['maxScale'] = document.maxScale.toString();
      }
      if (document.minScale != null) {
        attrs['minScale'] = document.minScale.toString();
      }

      builder.element('qgis', attributes: attrs, nest: () {
        _rendererWriter.writeRenderer(builder, document.renderer);
      });

      final xml = builder.buildDocument().toXmlString(pretty: true);

      return WriteQmlSuccess(xml, warnings: warnings);
    } catch (e) {
      return WriteQmlFailure('Failed to encode QML: $e', cause: e);
    }
  }
}
