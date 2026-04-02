/// Result of encoding a [QmlDocument] into QML XML.
///
/// Use pattern matching to handle both cases:
/// ```dart
/// switch (result) {
///   case WriteQmlSuccess(:final xml):
///     // use xml string
///   case WriteQmlFailure(:final message):
///     // handle error
/// }
/// ```
sealed class WriteQmlResult {
  const WriteQmlResult();
}

/// Successful encode result containing the [xml] string and any non-fatal
/// [warnings].
final class WriteQmlSuccess extends WriteQmlResult {
  const WriteQmlSuccess(
    this.xml, {
    this.warnings = const <String>[],
  });

  /// The generated QML XML string.
  final String xml;

  /// Non-fatal issues encountered during encoding.
  final List<String> warnings;
}

/// Failed encode result containing an error [message] and optional [cause].
final class WriteQmlFailure extends WriteQmlResult {
  const WriteQmlFailure(
    this.message, {
    this.cause,
  });

  /// Human-readable description of the failure.
  final String message;

  /// The underlying exception, if any.
  final Object? cause;
}
