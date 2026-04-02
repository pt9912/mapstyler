import '../model/qml_document.dart';

/// Result of parsing QML XML input.
///
/// Use pattern matching to handle both cases:
/// ```dart
/// switch (result) {
///   case ReadQmlSuccess(:final document, :final warnings):
///     // use document
///   case ReadQmlFailure(:final message):
///     // handle error
/// }
/// ```
sealed class ReadQmlResult {
  const ReadQmlResult();
}

/// Successful parse result containing the [document] and any non-fatal
/// [warnings] (e.g. unknown renderer types, missing attributes).
final class ReadQmlSuccess extends ReadQmlResult {
  const ReadQmlSuccess(
    this.document, {
    this.warnings = const <String>[],
  });

  /// The parsed QML document.
  final QmlDocument document;

  /// Non-fatal issues encountered during parsing.
  final List<String> warnings;
}

/// Failed parse result containing an error [message] and optional [cause].
final class ReadQmlFailure extends ReadQmlResult {
  const ReadQmlFailure(
    this.message, {
    this.cause,
  });

  /// Human-readable description of the failure.
  final String message;

  /// The underlying exception, if any.
  final Object? cause;
}
