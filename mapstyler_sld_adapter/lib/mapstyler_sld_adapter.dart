/// SLD adapter for the mapstyler ecosystem.
///
/// Parses SLD XML into mapstyler_style types. The underlying SLD parser
/// (`flutter_map_sld`) is an implementation detail and not exposed.
///
/// ```dart
/// import 'package:mapstyler_sld_adapter/mapstyler_sld_adapter.dart';
/// import 'package:mapstyler_style/mapstyler_style.dart';
///
/// final parser = SldStyleParser();
/// final result = await parser.readStyle(sldXml);
/// ```
library mapstyler_sld_adapter;

export 'src/color_util.dart';
export 'src/sld_style_parser.dart';
