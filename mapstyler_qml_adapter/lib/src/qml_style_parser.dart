import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:qml4dart/qml4dart.dart';

import 'qml_to_mapstyler.dart' as read;
import 'mapstyler_to_qml.dart' as write;

/// [StyleParser] implementation for QGIS QML via [qml4dart].
///
/// ```dart
/// final codec = Qml4DartCodec();
/// final parser = QmlStyleParser();
///
/// // QML → mapstyler_style
/// final parseResult = codec.parseString(qmlXml);
/// if (parseResult case ReadQmlSuccess(:final document)) {
///   final result = await parser.readStyle(document);
/// }
///
/// // mapstyler_style → QML
/// final writeResult = await parser.writeStyle(style);
/// if (writeResult case WriteStyleSuccess(:final output)) {
///   final qmlResult = codec.encodeString(output);
/// }
/// ```
class QmlStyleParser implements StyleParser<QmlDocument> {
  const QmlStyleParser();

  @override
  String get title => 'QML';

  @override
  Future<ReadStyleResult> readStyle(QmlDocument input) async =>
      read.convertDocument(input);

  @override
  Future<WriteStyleResult<QmlDocument>> writeStyle(Style style) async =>
      write.convertStyle(style);
}
