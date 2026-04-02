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
/// final result = await adapter.readStyle(mapboxJson);
/// ```
class MapboxStyleAdapter {
  const MapboxStyleAdapter({
    this.codec = const mb.MapboxStyleCodec(),
  });

  final mb.MapboxStyleCodec codec;

  String get title => 'Mapbox GL';

  /// Parses Mapbox GL Style JSON and converts to a mapstyler [Style].
  Future<ReadStyleResult> readStyle(String input) async {
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

  /// Converts a mapstyler [Style] to Mapbox GL Style JSON.
  Future<WriteStyleResult<String>> writeStyle(Style style) async {
    final result = write.convertStyle(style);
    return switch (result) {
      WriteStyleSuccess(:final output, :final warnings) => () {
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
