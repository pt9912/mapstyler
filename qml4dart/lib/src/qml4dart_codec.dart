import 'dart:io';

import 'model/qml_document.dart';
import 'qml_codec.dart';
import 'read/read_result.dart';
import 'write/write_result.dart';
import 'xml/xml_reader.dart';
import 'xml/xml_writer.dart';

/// Concrete [QmlCodec] implementation backed by [QmlXmlReader] and
/// [QmlXmlWriter].
class Qml4DartCodec extends QmlCodec {
  const Qml4DartCodec();

  static const _reader = QmlXmlReader();
  static const _writer = QmlXmlWriter();

  @override
  ReadQmlResult parseString(String xml) => _reader.read(xml);

  @override
  Future<ReadQmlResult> parseFile(String path) async {
    try {
      final content = await File(path).readAsString();
      return _reader.read(content);
    } catch (e) {
      return ReadQmlFailure('Failed to read file: $path', cause: e);
    }
  }

  @override
  WriteQmlResult encodeString(QmlDocument document) => _writer.write(document);

  @override
  Future<WriteQmlResult> encodeFile(
    String path,
    QmlDocument document,
  ) async {
    final result = _writer.write(document);
    if (result is WriteQmlSuccess) {
      try {
        await File(path).writeAsString(result.xml);
      } catch (e) {
        return WriteQmlFailure('Failed to write file: $path', cause: e);
      }
    }
    return result;
  }
}
