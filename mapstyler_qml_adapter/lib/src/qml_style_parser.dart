import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:qml4dart/qml4dart.dart' as qml;

import 'qml_to_mapstyler.dart' as read;
import 'mapstyler_to_qml.dart' as write;

/// Parses QGIS QML XML into mapstyler [Style] objects and writes
/// mapstyler styles back to QML XML.
///
/// Internally uses `qml4dart` for XML parsing and serialization — that
/// dependency is not exposed in the public API.
///
/// ```dart
/// final parser = QmlStyleParser();
///
/// // Read QML XML → mapstyler Style
/// final result = await parser.readStyle(qmlXml);
///
/// // Write Style → QML XML
/// final writeResult = await parser.writeStyle(style);
/// if (writeResult case WriteStyleSuccess(:final output)) {
///   print(output); // QML XML string
/// }
/// ```
class QmlStyleParser {
  const QmlStyleParser();

  /// Human-readable name for this parser.
  String get title => 'QML';

  /// Parses a QML XML string and converts it to a mapstyler [Style].
  Future<ReadStyleResult> readStyle(String qmlXml) async {
    final parseResult = qml.Qml4DartCodec().parseString(qmlXml);
    return switch (parseResult) {
      qml.ReadQmlSuccess(:final document) => read.convertDocument(document),
      qml.ReadQmlFailure(:final message) =>
        ReadStyleFailure(errors: [message]),
    };
  }

  /// Converts a mapstyler [Style] to a QML XML string.
  Future<WriteStyleResult<String>> writeStyle(Style style) async {
    final convertResult = write.convertStyle(style);
    return switch (convertResult) {
      WriteStyleSuccess(:final output, :final warnings) => () {
          final xmlResult = qml.Qml4DartCodec().encodeString(output);
          return switch (xmlResult) {
            qml.WriteQmlSuccess(:final xml) =>
              WriteStyleSuccess<String>(output: xml, warnings: warnings),
            qml.WriteQmlFailure(:final message) =>
              WriteStyleFailure<String>(errors: [message]),
          };
        }(),
      WriteStyleFailure(:final errors) =>
        WriteStyleFailure<String>(errors: errors),
    };
  }
}
