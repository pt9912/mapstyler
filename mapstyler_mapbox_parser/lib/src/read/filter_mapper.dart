import 'package:mapstyler_style/mapstyler_style.dart' as ms;

import 'expression_mapper.dart' as expr;

/// Converts a Mapbox filter (array-based) to a mapstyler [ms.Filter].
///
/// Supports both legacy (v1) and expression-based (v2) filters.
ms.Filter? convertFilter(List<Object?>? filter, List<String> warnings) {
  if (filter == null || filter.isEmpty) return null;

  final op = filter[0];
  if (op is! String) {
    warnings.add('Filter operator must be a string, got ${op.runtimeType}');
    return null;
  }

  return switch (op) {
    // Comparison
    '==' || '!=' || '<' || '>' || '<=' || '>=' =>
      _convertComparison(op, filter, warnings),

    // Logical
    'all' => _convertCombination(ms.CombinationOperator.and, filter, warnings),
    'any' => _convertCombination(ms.CombinationOperator.or, filter, warnings),
    'none' => _convertNone(filter, warnings),
    '!' => filter.length > 1
        ? _wrapNegation(
            convertFilter(filter[1] as List<Object?>?, warnings))
        : null,

    // Existence
    'has' => _convertHas(filter, warnings),
    '!has' => _convertNotHas(filter, warnings),

    // Membership
    'in' => _convertIn(filter, warnings),
    '!in' => _convertNotIn(filter, warnings),

    _ => () {
        warnings.add('Unsupported filter operator: $op');
        return null;
      }(),
  };
}

ms.Filter? _convertComparison(
    String op, List<Object?> filter, List<String> warnings) {
  if (filter.length < 3) return null;

  final msOp = switch (op) {
    '==' => ms.ComparisonOperator.eq,
    '!=' => ms.ComparisonOperator.neq,
    '<' => ms.ComparisonOperator.lt,
    '>' => ms.ComparisonOperator.gt,
    '<=' => ms.ComparisonOperator.lte,
    '>=' => ms.ComparisonOperator.gte,
    _ => ms.ComparisonOperator.eq,
  };

  // Detect v2 expression-based: ["==", ["get", "field"], value]
  // vs v1 legacy: ["==", "field", value]
  final left = filter[1];
  final right = filter[2];

  ms.Expression<String> property;
  ms.Expression<Object> value;

  if (left is List && left.isNotEmpty && left[0] == 'get') {
    property = ms.LiteralExpression(left[1] as String);
    value = _toObjectExpr(right, warnings);
  } else if (left is String) {
    property = ms.LiteralExpression(left);
    value = _toObjectExpr(right, warnings);
  } else {
    // Both sides are expressions — use expression mapper
    final lExpr = expr.convertValue<String>(left, (v) => '$v', warnings);
    final rExpr = expr.convertValue<Object>(right, (v) => v as Object, warnings);
    if (lExpr == null || rExpr == null) return null;
    property = lExpr;
    value = rExpr;
  }

  return ms.ComparisonFilter(operator: msOp, property: property, value: value);
}

ms.Filter? _convertCombination(
    ms.CombinationOperator op, List<Object?> filter, List<String> warnings) {
  final sub = <ms.Filter>[];
  for (var i = 1; i < filter.length; i++) {
    final f = convertFilter(filter[i] as List<Object?>?, warnings);
    if (f != null) sub.add(f);
  }
  if (sub.isEmpty) return null;
  if (sub.length == 1) return sub.first;
  return ms.CombinationFilter(operator: op, filters: sub);
}

ms.Filter? _convertNone(List<Object?> filter, List<String> warnings) {
  final any = _convertCombination(
      ms.CombinationOperator.or, filter, warnings);
  return _wrapNegation(any);
}

ms.Filter? _wrapNegation(ms.Filter? inner) {
  if (inner == null) return null;
  return ms.NegationFilter(filter: inner);
}

ms.Filter? _convertHas(List<Object?> filter, List<String> warnings) {
  if (filter.length < 2) return null;
  final prop = filter[1] as String;
  warnings.add('Filter "has" approximated as "!= \'\'"');
  return ms.ComparisonFilter(
    operator: ms.ComparisonOperator.neq,
    property: ms.LiteralExpression(prop),
    value: const ms.LiteralExpression<Object>(''),
  );
}

ms.Filter? _convertNotHas(List<Object?> filter, List<String> warnings) {
  if (filter.length < 2) return null;
  final prop = filter[1] as String;
  warnings.add('Filter "!has" approximated as "== \'\'"');
  return ms.ComparisonFilter(
    operator: ms.ComparisonOperator.eq,
    property: ms.LiteralExpression(prop),
    value: const ms.LiteralExpression<Object>(''),
  );
}

ms.Filter? _convertIn(List<Object?> filter, List<String> warnings) {
  if (filter.length < 3) return null;
  final prop = filter[1] as String;
  final values = filter.sublist(2);
  return ms.CombinationFilter(
    operator: ms.CombinationOperator.or,
    filters: [
      for (final v in values)
        ms.ComparisonFilter(
          operator: ms.ComparisonOperator.eq,
          property: ms.LiteralExpression(prop),
          value: ms.LiteralExpression<Object>(v as Object),
        ),
    ],
  );
}

ms.Filter? _convertNotIn(List<Object?> filter, List<String> warnings) {
  final inFilter = _convertIn(filter, warnings);
  return _wrapNegation(inFilter);
}

ms.Expression<Object> _toObjectExpr(Object? value, List<String> warnings) {
  if (value is List && value.isNotEmpty && value[0] == 'get') {
    return ms.FunctionExpression<Object>(
        ms.PropertyGet(value[1] as String));
  }
  return ms.LiteralExpression<Object>(value as Object);
}
