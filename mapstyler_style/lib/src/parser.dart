import 'style.dart';

/// Interface for format-specific style parsers.
///
/// Each parser converts between a source format [T] (e.g. Mapbox JSON,
/// SLD types) and mapstyler's [Style] – the common intermediate format.
///
/// Implementations:
/// - `mapstyler_mapbox_parser` — Mapbox GL Style JSON.
/// - `mapstyler_sld_adapter` — SLD via `flutter_map_sld`.
abstract class StyleParser<T> {
  /// A human-readable name for this parser (e.g. `"Mapbox GL"`).
  String get title;

  /// Parses the source format into a [Style].
  Future<ReadStyleResult> readStyle(T input);

  /// Converts a [Style] into the source format.
  Future<WriteStyleResult<T>> writeStyle(Style style);
}

/// The result of parsing a style with [StyleParser.readStyle].
sealed class ReadStyleResult {
  const ReadStyleResult();
}

/// A successful parse result containing the [output] style and optional
/// [warnings] about unsupported or degraded features.
class ReadStyleSuccess extends ReadStyleResult {
  /// The parsed style.
  final Style output;

  /// Non-fatal issues encountered during parsing.
  final List<String> warnings;

  const ReadStyleSuccess({required this.output, this.warnings = const []});
}

/// A failed parse result containing the [errors] that prevented parsing.
class ReadStyleFailure extends ReadStyleResult {
  /// The errors that caused the parse to fail.
  final List<String> errors;

  const ReadStyleFailure({required this.errors});
}

/// The result of writing a style with [StyleParser.writeStyle].
sealed class WriteStyleResult<T> {
  const WriteStyleResult();
}

/// A successful write result containing the serialized [output].
class WriteStyleSuccess<T> extends WriteStyleResult<T> {
  /// The serialized output in the target format.
  final T output;

  /// Non-fatal issues encountered during serialization.
  final List<String> warnings;

  const WriteStyleSuccess({required this.output, this.warnings = const []});
}

/// A failed write result containing the [errors] that prevented
/// serialization.
class WriteStyleFailure<T> extends WriteStyleResult<T> {
  /// The errors that caused the write to fail.
  final List<String> errors;

  const WriteStyleFailure({required this.errors});
}
