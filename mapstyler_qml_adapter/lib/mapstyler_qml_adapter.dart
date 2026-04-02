/// Adapter between qml4dart and mapstyler_style.
///
/// ```dart
/// import 'package:qml4dart/qml4dart.dart';
/// import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';
///
/// // Parse QML, then convert to mapstyler types.
/// final codec = Qml4DartCodec();
/// final parseResult = codec.parseString(qmlXml);
/// final parser = QmlStyleParser();
/// final result = await parser.readStyle(parseResult.document!);
/// ```
library mapstyler_qml_adapter;

export 'src/color_util.dart';
export 'src/qml_style_parser.dart';
export 'src/qml_to_mapstyler.dart' show convertDocument;
export 'src/mapstyler_to_qml.dart' show convertStyle;
