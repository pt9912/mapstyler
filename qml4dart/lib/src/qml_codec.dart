import 'model/qml_document.dart';
import 'read/read_result.dart';
import 'write/write_result.dart';

/// Reads QGIS QML into a typed object model and encodes it back to XML.
abstract class QmlCodec {
  const QmlCodec();

  ReadQmlResult parseString(String xml);

  Future<ReadQmlResult> parseFile(String path);

  WriteQmlResult encodeString(QmlDocument document);

  Future<WriteQmlResult> encodeFile(String path, QmlDocument document);
}
