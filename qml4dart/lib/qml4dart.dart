/// Pure Dart codec and object model for QGIS QML layer style files.
///
/// QML (`.qml`) is the native layer style format used by QGIS. This package
/// provides a typed Dart object model and a bidirectional codec for reading
/// and writing QML XML.
///
/// ```dart
/// import 'package:qml4dart/qml4dart.dart';
///
/// const codec = Qml4DartCodec();
///
/// // Parse QML XML.
/// final result = codec.parseString(qmlXml);
/// if (result case ReadQmlSuccess(:final document)) {
///   print(document.renderer.type);
/// }
///
/// // Encode back to XML.
/// final writeResult = codec.encodeString(document);
/// if (writeResult case WriteQmlSuccess(:final xml)) {
///   print(xml);
/// }
/// ```
///
/// **Supported features:**
/// - Renderers: singleSymbol, categorizedSymbol, graduatedSymbol,
///   RuleRenderer (incl. nested rules).
/// - Symbol layers: SimpleMarker, SvgMarker, SimpleLine, SimpleFill,
///   RasterFill.
/// - Property formats: `<Option type="Map">` (QGIS >= 3.26) and
///   legacy `<prop k v>`.
/// - Scale visibility at document and rule level.
library qml4dart;

export 'src/model/qml_category.dart';
export 'src/model/qml_document.dart';
export 'src/model/qml_range.dart';
export 'src/model/qml_renderer.dart';
export 'src/model/qml_rule.dart';
export 'src/model/qml_symbol.dart';
export 'src/model/qml_symbol_layer.dart';
export 'src/model/qml_types.dart';
export 'src/qml4dart_codec.dart';
export 'src/qml_codec.dart';
export 'src/read/read_result.dart';
export 'src/write/write_result.dart';
