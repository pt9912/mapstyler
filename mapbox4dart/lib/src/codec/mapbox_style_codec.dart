import 'dart:convert';

import '../model/mapbox_style.dart';
import '../read/mapbox_reader.dart' as reader;
import '../read/read_result.dart';
import '../write/mapbox_writer.dart' as writer;
import '../write/write_result.dart';

/// Reads and writes Mapbox GL Style JSON v8.
final class MapboxStyleCodec {
  const MapboxStyleCodec();

  /// Parses a Mapbox GL Style JSON string.
  ReadMapboxResult readString(String input) {
    final Object? decoded;
    try {
      decoded = jsonDecode(input);
    } catch (e) {
      return ReadMapboxFailure(errors: ['Invalid JSON: $e']);
    }
    if (decoded is! Map<String, Object?>) {
      return const ReadMapboxFailure(errors: ['Expected a JSON object']);
    }
    return reader.readMapboxJson(decoded);
  }

  /// Parses a pre-decoded JSON map.
  ReadMapboxResult readJsonObject(Map<String, Object?> input) =>
      reader.readMapboxJson(input);

  /// Encodes a [MapboxStyle] to a JSON string.
  WriteMapboxResult writeString(MapboxStyle style) {
    try {
      final json = writer.writeMapboxJson(style);
      final encoded = const JsonEncoder.withIndent('  ').convert(json);
      return WriteMapboxSuccess(output: encoded);
    } catch (e) {
      return WriteMapboxFailure(errors: ['Failed to encode: $e']);
    }
  }

  /// Encodes a [MapboxStyle] to a JSON-compatible map.
  Map<String, Object?> writeJsonObject(MapboxStyle style) =>
      writer.writeMapboxJson(style);
}
