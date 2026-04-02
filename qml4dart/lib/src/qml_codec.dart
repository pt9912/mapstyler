import 'model/qml_document.dart';
import 'read/read_result.dart';
import 'write/write_result.dart';

/// Abstract interface for reading and writing QGIS QML layer style files.
///
/// Implementations convert between QML XML and the typed [QmlDocument]
/// object model. See [Qml4DartCodec] for the concrete implementation.
abstract class QmlCodec {
  const QmlCodec();

  /// Parses a QML XML [xml] string into a [QmlDocument].
  ///
  /// Returns [ReadQmlSuccess] with the parsed document and any warnings,
  /// or [ReadQmlFailure] if parsing fails.
  ReadQmlResult parseString(String xml);

  /// Reads a QML file at [path] and parses it into a [QmlDocument].
  ///
  /// Returns [ReadQmlFailure] if the file cannot be read or parsed.
  Future<ReadQmlResult> parseFile(String path);

  /// Encodes a [QmlDocument] into a QML XML string.
  ///
  /// Returns [WriteQmlSuccess] with the XML and any warnings,
  /// or [WriteQmlFailure] if encoding fails.
  WriteQmlResult encodeString(QmlDocument document);

  /// Encodes a [QmlDocument] and writes it to a file at [path].
  ///
  /// Returns [WriteQmlFailure] if encoding or writing fails.
  Future<WriteQmlResult> encodeFile(String path, QmlDocument document);
}
