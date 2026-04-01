import '../model/qml_document.dart';

/// Result of parsing QML input.
sealed class ReadQmlResult {
  const ReadQmlResult();
}

final class ReadQmlSuccess extends ReadQmlResult {
  const ReadQmlSuccess(
    this.document, {
    this.warnings = const <String>[],
  });

  final QmlDocument document;
  final List<String> warnings;
}

final class ReadQmlFailure extends ReadQmlResult {
  const ReadQmlFailure(
    this.message, {
    this.cause,
  });

  final String message;
  final Object? cause;
}
