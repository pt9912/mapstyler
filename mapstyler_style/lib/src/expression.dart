import 'function.dart';

/// GeoStyler expression — a value that is either a literal or computed
/// by a [GeoStylerFunction].
///
/// In JSON, expressions use a dual format:
/// - Raw values (String, num, bool) are deserialized as [LiteralExpression].
/// - Maps with a `name` key are deserialized as [FunctionExpression].
///
/// ```dart
/// // Literal:
/// final color = Expression.fromJson<String>('#ff0000', (v) => v as String);
///
/// // Function:
/// final color = Expression.fromJson<String>(
///   {'name': 'property', 'args': ['color']},
///   (v) => v as String,
/// );
/// ```
sealed class Expression<T> {
  const Expression();

  /// Deserializes an expression from its JSON representation.
  ///
  /// [fromJsonT] converts the raw JSON value to type [T] for literals.
  static Expression<T> fromJson<T>(
    Object? json,
    T Function(Object?) fromJsonT,
  ) {
    if (json is Map<String, dynamic> && json.containsKey('name')) {
      return FunctionExpression<T>(GeoStylerFunction.fromJson(json));
    }
    return LiteralExpression<T>(fromJsonT(json));
  }

  /// Serializes this expression to its JSON representation.
  Object? toJson();
}

/// A concrete, fixed value.
///
/// JSON: the raw value itself (e.g. `"#ff0000"`, `12.0`, `true`).
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

/// A dynamically computed value backed by a [GeoStylerFunction].
///
/// JSON: `{"name": "functionName", "args": [...]}`.
final class FunctionExpression<T> extends Expression<T> {
  /// The function that computes this expression's value.
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
