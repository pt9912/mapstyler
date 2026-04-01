/// SLD adapter for the mapstyler ecosystem.
///
/// Maps between `flutter_map_sld` types and `mapstyler_style` types,
/// enabling SLD support without writing a new SLD parser.
///
/// ```dart
/// import 'package:flutter_map_sld/flutter_map_sld.dart';
/// import 'package:mapstyler_sld_adapter/mapstyler_sld_adapter.dart';
///
/// // Parse SLD XML via flutter_map_sld, then convert to mapstyler types.
/// final parseResult = SldDocument.parseXmlString(sldXml);
/// final parser = SldStyleParser();
/// final result = await parser.readStyle(parseResult.document!);
/// ```
library mapstyler_sld_adapter;

export 'src/color_util.dart';
export 'src/sld_style_parser.dart';
export 'src/sld_to_mapstyler.dart' show convertDocument;
export 'src/mapstyler_to_sld.dart' show convertStyle;
