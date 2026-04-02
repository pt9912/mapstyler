import 'package:mapbox4dart/mapbox4dart.dart' as mb;
import 'package:mapstyler_style/mapstyler_style.dart';

import 'read/layer_to_rule_mapper.dart' as read;
import 'write/symbolizer_mapper.dart' as write;

/// Converts between Mapbox GL Style JSON and mapstyler [Style].
///
/// Internally uses `mapbox4dart` for JSON parsing — that dependency
/// is not exposed in the public API.
///
/// ```dart
/// final adapter = MapboxStyleAdapter();
///
/// // Read Mapbox JSON → mapstyler Style
/// final result = await adapter.readStyle(mapboxJson);
///
/// // Write Style → Mapbox JSON
/// final writeResult = await adapter.writeStyle(style);
/// if (writeResult case WriteStyleSuccess(:final output)) {
///   print(output); // Mapbox GL Style JSON string
/// }
/// ```
class MapboxStyleAdapter {
  const MapboxStyleAdapter();

  /// Human-readable name for this adapter.
  String get title => 'Mapbox GL';

  /// Parses a Mapbox GL Style JSON string and converts it to a
  /// mapstyler [Style].
  Future<ReadStyleResult> readStyle(String input) async {
    final codec = const mb.MapboxStyleCodec();
    final parseResult = codec.readString(input);
    return switch (parseResult) {
      mb.ReadMapboxSuccess(:final output, :final warnings) => () {
          final result = read.convertMapboxStyle(output);
          if (result case ReadStyleSuccess(:final output, warnings: final w)) {
            return ReadStyleSuccess(
              output: output,
              warnings: [...warnings, ...w],
            );
          }
          return result;
        }(),
      mb.ReadMapboxFailure(:final errors) =>
        ReadStyleFailure(errors: errors),
    };
  }

  /// Converts a mapstyler [Style] to a Mapbox GL Style JSON string.
  Future<WriteStyleResult<String>> writeStyle(Style style) async {
    final result = write.convertStyle(style);
    return switch (result) {
      WriteStyleSuccess(:final output, :final warnings) => () {
          final codec = const mb.MapboxStyleCodec();
          final writeResult = codec.writeString(output);
          return switch (writeResult) {
            mb.WriteMapboxSuccess(:final output) =>
              WriteStyleSuccess<String>(output: output, warnings: warnings),
            mb.WriteMapboxFailure(:final errors) =>
              WriteStyleFailure<String>(errors: errors),
          };
        }(),
      WriteStyleFailure(:final errors) =>
        WriteStyleFailure<String>(errors: errors),
    };
  }
}
