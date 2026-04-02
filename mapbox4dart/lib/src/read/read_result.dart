import '../model/mapbox_style.dart';

/// Result of reading Mapbox GL Style JSON.
sealed class ReadMapboxResult {
  const ReadMapboxResult();
}

/// Successful read with the parsed [output] and any [warnings].
final class ReadMapboxSuccess extends ReadMapboxResult {
  final MapboxStyle output;
  final List<String> warnings;
  const ReadMapboxSuccess({required this.output, this.warnings = const []});
}

/// Failed read with [errors] describing what went wrong.
final class ReadMapboxFailure extends ReadMapboxResult {
  final List<String> errors;
  const ReadMapboxFailure({required this.errors});
}
