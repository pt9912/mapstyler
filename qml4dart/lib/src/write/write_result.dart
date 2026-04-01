/// Result of encoding a [QmlDocument] into QML XML.
sealed class WriteQmlResult {
  const WriteQmlResult();
}

final class WriteQmlSuccess extends WriteQmlResult {
  const WriteQmlSuccess(
    this.xml, {
    this.warnings = const <String>[],
  });

  final String xml;
  final List<String> warnings;
}

final class WriteQmlFailure extends WriteQmlResult {
  const WriteQmlFailure(
    this.message, {
    this.cause,
  });

  final String message;
  final Object? cause;
}
