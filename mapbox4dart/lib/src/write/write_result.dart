/// Result of writing Mapbox GL Style JSON.
sealed class WriteMapboxResult {
  const WriteMapboxResult();
}

/// Successful write with the JSON [output] and any [warnings].
final class WriteMapboxSuccess extends WriteMapboxResult {
  final String output;
  final List<String> warnings;
  const WriteMapboxSuccess({required this.output, this.warnings = const []});
}

/// Failed write with [errors] describing what went wrong.
final class WriteMapboxFailure extends WriteMapboxResult {
  final List<String> errors;
  const WriteMapboxFailure({required this.errors});
}
