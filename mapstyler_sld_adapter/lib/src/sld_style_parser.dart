import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:mapstyler_style/mapstyler_style.dart';

import 'sld_to_mapstyler.dart' as read;

/// Parses SLD XML into mapstyler [Style] objects.
///
/// Internally uses `flutter_map_sld` for XML parsing, but that dependency
/// is not exposed in the public API.
///
/// ```dart
/// final parser = SldStyleParser();
/// final result = await parser.readStyle(sldXml);
///
/// if (result case ReadStyleSuccess(:final output)) {
///   for (final rule in output.rules) {
///     print('${rule.name}: ${rule.symbolizers.length} symbolizers');
///   }
/// }
/// ```
class SldStyleParser {
  const SldStyleParser();

  /// Human-readable name for this parser.
  String get title => 'SLD';

  /// Parses an SLD XML string and converts it to a mapstyler [Style].
  Future<ReadStyleResult> readStyle(String sldXml) async {
    final parseResult = sld.SldDocument.parseXmlString(sldXml);
    if (parseResult.document == null) {
      final messages = parseResult.issues.map((i) => i.message).toList();
      return ReadStyleFailure(errors: messages);
    }
    return read.convertDocument(parseResult.document!);
  }
}
