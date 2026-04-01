/// StyleParser implementation for SLD via flutter_map_sld.
import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:mapstyler_style/mapstyler_style.dart';

import 'mapstyler_to_sld.dart' as write;
import 'sld_to_mapstyler.dart' as read;

/// Converts between [sld.SldDocument] and mapstyler [Style].
///
/// **Read:** Accepts an [sld.SldDocument] (produced by
/// `SldDocument.parseXmlString()`) and converts it to a [Style].
///
/// **Write:** Converts a [Style] to an [sld.SldDocument] (model objects,
/// not XML — flutter_map_sld does not provide XML serialization).
///
/// ```dart
/// final parser = SldStyleParser();
///
/// // Read SLD
/// final parseResult = SldDocument.parseXmlString(sldXml);
/// final result = await parser.readStyle(parseResult.document!);
///
/// // Write back
/// final writeResult = await parser.writeStyle(style);
/// ```
class SldStyleParser implements StyleParser<sld.SldDocument> {
  const SldStyleParser();

  @override
  String get title => 'SLD';

  @override
  Future<ReadStyleResult> readStyle(sld.SldDocument input) async =>
      read.convertDocument(input);

  @override
  Future<WriteStyleResult<sld.SldDocument>> writeStyle(Style style) async =>
      write.convertStyle(style);
}
