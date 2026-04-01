import 'style.dart';

/// Interface for all mapstyler format parsers.
abstract class StyleParser<T> {
  String get title;

  Future<ReadStyleResult> readStyle(T input);
  Future<WriteStyleResult<T>> writeStyle(Style style);
}

sealed class ReadStyleResult {
  const ReadStyleResult();
}

class ReadStyleSuccess extends ReadStyleResult {
  final Style output;
  final List<String> warnings;

  const ReadStyleSuccess({required this.output, this.warnings = const []});
}

class ReadStyleFailure extends ReadStyleResult {
  final List<String> errors;

  const ReadStyleFailure({required this.errors});
}

sealed class WriteStyleResult<T> {
  const WriteStyleResult();
}

class WriteStyleSuccess<T> extends WriteStyleResult<T> {
  final T output;
  final List<String> warnings;

  const WriteStyleSuccess({required this.output, this.warnings = const []});
}

class WriteStyleFailure<T> extends WriteStyleResult<T> {
  final List<String> errors;

  const WriteStyleFailure({required this.errors});
}
