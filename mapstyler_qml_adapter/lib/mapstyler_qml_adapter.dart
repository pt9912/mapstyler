/// QML adapter for the mapstyler ecosystem.
///
/// Converts QGIS QML XML into mapstyler_style types and back. The
/// underlying QML parser (`qml4dart`) is an implementation detail and
/// not exposed.
///
/// ```dart
/// import 'package:mapstyler_sld_adapter/mapstyler_qml_adapter.dart';
/// import 'package:mapstyler_style/mapstyler_style.dart';
///
/// final parser = QmlStyleParser();
/// final result = await parser.readStyle(qmlXml);
/// ```
library mapstyler_qml_adapter;

export 'src/color_util.dart';
export 'src/qml_style_parser.dart';
