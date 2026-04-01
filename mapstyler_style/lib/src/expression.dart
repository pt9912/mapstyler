import 'function.dart';

/// GeoStyler expression — dual-format JSON:
/// - Raw value (String, num, bool) → LiteralExpression
/// - Map with 'name' key → FunctionExpression
sealed class Expression<T> {
  const Expression();

  static Expression<T> fromJson<T>(
    Object? json,
    T Function(Object?) fromJsonT,
  ) {
    if (json is Map<String, dynamic> && json.containsKey('name')) {
      return FunctionExpression<T>(GeoStylerFunction.fromJson(json));
    }
    return LiteralExpression<T>(fromJsonT(json));
  }

  Object? toJson();
}

final class LiteralExpression<T> extends Expression<T> {
  final T value;
  const LiteralExpression(this.value);

  @override
  Object? toJson() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiteralExpression<T> && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class FunctionExpression<T> extends Expression<T> {
  final GeoStylerFunction function;
  const FunctionExpression(this.function);

  @override
  Object? toJson() => function.toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionExpression<T> && function == other.function;

  @override
  int get hashCode => function.hashCode;
}
