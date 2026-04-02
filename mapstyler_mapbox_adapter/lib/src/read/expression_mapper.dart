import 'package:mapstyler_style/mapstyler_style.dart' as ms;

/// Converts a Mapbox property value (literal or expression) to a
/// mapstyler Expression.
ms.Expression<T>? convertValue<T>(
  Object? value,
  T Function(Object?) cast,
  List<String> warnings,
) {
  if (value == null) return null;

  // Literal: string, number, bool
  if (value is String || value is num || value is bool) {
    return ms.LiteralExpression<T>(cast(value));
  }

  // Expression: array
  if (value is List && value.isNotEmpty) {
    return _convertExpression<T>(value, cast, warnings);
  }

  return null;
}

/// Converts a Mapbox expression array to a mapstyler FunctionExpression.
ms.Expression<T>? _convertExpression<T>(
  List<Object?> expr,
  T Function(Object?) cast,
  List<String> warnings,
) {
  final op = expr[0] as String;

  return switch (op) {
    'get' => _convertGet<T>(expr),
    'literal' => expr.length > 1
        ? ms.LiteralExpression<T>(cast(expr[1]))
        : null,
    'interpolate' => _convertInterpolate<T>(expr, warnings),
    'step' => _convertStep<T>(expr, warnings),
    'case' => _convertCase<T>(expr, warnings),
    'match' => _convertMatch<T>(expr, warnings),
    'concat' => _convertArgsFunc<T>('strConcat', expr, warnings),
    'zoom' => ms.FunctionExpression<T>(
        const ms.ArgsFunction(name: 'zoom')),
    'to-string' => _convertArgsFunc<T>('toString', expr, warnings),
    _ => () {
        warnings.add('Unsupported expression: $op');
        return null;
      }(),
  };
}

ms.Expression<T> _convertGet<T>(List<Object?> expr) {
  final field = expr[1] as String;
  return ms.FunctionExpression<T>(ms.PropertyGet(field));
}

ms.Expression<T>? _convertInterpolate<T>(
    List<Object?> expr, List<String> warnings) {
  if (expr.length < 4) return null;
  final mode = expr[1] as List;
  final input = _convertObjectExpr(expr[2], warnings);
  if (input == null) return null;

  final stops = <ms.InterpolateParameter>[];
  for (var i = 3; i < expr.length - 1; i += 2) {
    stops.add(ms.InterpolateParameter(
      stop: ms.LiteralExpression<Object>(expr[i] as Object),
      value: ms.LiteralExpression<Object>(expr[i + 1] as Object),
    ));
  }

  return ms.FunctionExpression<T>(ms.InterpolateFunction(
    mode: mode.cast<Object>(),
    input: input,
    stops: stops,
  ));
}

ms.Expression<T>? _convertStep<T>(
    List<Object?> expr, List<String> warnings) {
  if (expr.length < 3) return null;
  final input = _convertObjectExpr(expr[1], warnings);
  if (input == null) return null;
  final defaultValue = ms.LiteralExpression<Object>(expr[2] as Object);

  final stops = <ms.StepParameter>[];
  for (var i = 3; i < expr.length - 1; i += 2) {
    stops.add(ms.StepParameter(
      boundary: ms.LiteralExpression<Object>(expr[i] as Object),
      value: ms.LiteralExpression<Object>(expr[i + 1] as Object),
    ));
  }

  return ms.FunctionExpression<T>(ms.StepFunction(
    input: input,
    defaultValue: defaultValue,
    stops: stops,
  ));
}

ms.Expression<T>? _convertCase<T>(
    List<Object?> expr, List<String> warnings) {
  if (expr.length < 2) return null;
  final cases = <ms.CaseParameter>[];
  for (var i = 1; i < expr.length - 2; i += 2) {
    final condition = _convertObjectExpr(expr[i], warnings);
    final value = ms.LiteralExpression<Object>(expr[i + 1] as Object);
    if (condition != null) {
      cases.add(ms.CaseParameter(condition: condition, value: value));
    }
  }
  final fallback = ms.LiteralExpression<Object>(expr.last as Object);
  return ms.FunctionExpression<T>(
      ms.CaseFunction(cases: cases, fallback: fallback));
}

ms.Expression<T>? _convertMatch<T>(
    List<Object?> expr, List<String> warnings) {
  // ["match", input, label1, output1, label2, output2, ..., fallback]
  if (expr.length < 4) return null;
  final input = _convertObjectExpr(expr[1], warnings);
  if (input == null) return null;

  final cases = <ms.CaseParameter>[];
  for (var i = 2; i < expr.length - 2; i += 2) {
    final label = expr[i];
    final output = ms.LiteralExpression<Object>(expr[i + 1] as Object);

    // Label can be a single value or array of values
    if (label is List) {
      for (final v in label) {
        cases.add(ms.CaseParameter(
          condition: ms.FunctionExpression<Object>(ms.ArgsFunction(
            name: 'equalTo',
            args: [input, ms.LiteralExpression<Object>(v as Object)],
          )),
          value: output,
        ));
      }
    } else {
      cases.add(ms.CaseParameter(
        condition: ms.FunctionExpression<Object>(ms.ArgsFunction(
          name: 'equalTo',
          args: [input, ms.LiteralExpression<Object>(label as Object)],
        )),
        value: output,
      ));
    }
  }

  final fallback = ms.LiteralExpression<Object>(expr.last as Object);
  return ms.FunctionExpression<T>(
      ms.CaseFunction(cases: cases, fallback: fallback));
}

ms.Expression<T>? _convertArgsFunc<T>(
    String name, List<Object?> expr, List<String> warnings) {
  final args = <ms.Expression<Object>>[];
  for (var i = 1; i < expr.length; i++) {
    final e = _convertObjectExpr(expr[i], warnings);
    if (e != null) args.add(e);
  }
  return ms.FunctionExpression<T>(ms.ArgsFunction(name: name, args: args));
}

ms.Expression<Object>? _convertObjectExpr(
    Object? value, List<String> warnings) {
  if (value == null) return null;
  if (value is String || value is num || value is bool) {
    return ms.LiteralExpression<Object>(value);
  }
  if (value is List && value.isNotEmpty) {
    return _convertExpression<Object>(
        value.cast<Object?>(), (v) => v as Object, warnings);
  }
  return null;
}
