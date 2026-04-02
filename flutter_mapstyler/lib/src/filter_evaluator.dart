import 'package:mapstyler_style/mapstyler_style.dart';

import 'expression_evaluator.dart';
import 'geometry_ops.dart';

/// Prepared evaluator for a [Filter].
typedef CompiledFilterEvaluator = bool Function(
  Map<String, Object?> properties, {
  Geometry? geometry,
});

/// Evaluates a mapstyler [Filter] against feature properties.
///
/// Returns `true` if the feature matches the filter.
/// [geometry] is used for spatial and distance filters and may be omitted for
/// pure property-based filters.
bool evaluateFilter(
  Filter? filter,
  Map<String, Object?> properties, {
  Geometry? geometry,
}) {
  return compileFilterEvaluator(filter)(properties, geometry: geometry);
}

/// Compiles a [Filter] into a reusable evaluator closure.
CompiledFilterEvaluator compileFilterEvaluator(Filter? filter) {
  if (filter == null) {
    return (_, {geometry}) => true;
  }

  return switch (filter) {
    ComparisonFilter() => _compileComparison(filter),
    CombinationFilter() => _compileCombination(filter),
    NegationFilter(:final filter) => _compileNegation(filter),
    SpatialFilter() => _compileSpatial(filter),
    DistanceFilter() => _compileDistance(filter),
  };
}

CompiledFilterEvaluator _compileComparison(ComparisonFilter filter) {
  final compiledProperty = compileExpressionEvaluator(filter.property);
  final compiledValue = compileExpressionEvaluator(filter.value);

  return (properties, {geometry}) {
    final propName = compiledProperty(properties);
    if (propName == null) return false;

    final propValue = properties[propName];
    final filterValue = compiledValue(properties);

    return switch (filter.operator) {
      ComparisonOperator.eq => _equals(propValue, filterValue),
      ComparisonOperator.neq => !_equals(propValue, filterValue),
      ComparisonOperator.lt => _compare(propValue, filterValue) < 0,
      ComparisonOperator.gt => _compare(propValue, filterValue) > 0,
      ComparisonOperator.lte => _compare(propValue, filterValue) <= 0,
      ComparisonOperator.gte => _compare(propValue, filterValue) >= 0,
    };
  };
}

CompiledFilterEvaluator _compileCombination(CombinationFilter filter) {
  final compiledFilters =
      filter.filters.map(compileFilterEvaluator).toList(growable: false);

  return switch (filter.operator) {
    CombinationOperator.and => (properties, {geometry}) =>
        compiledFilters.every(
          (compiled) => compiled(properties, geometry: geometry),
        ),
    CombinationOperator.or => (properties, {geometry}) =>
        compiledFilters.any(
          (compiled) => compiled(properties, geometry: geometry),
        ),
  };
}

CompiledFilterEvaluator _compileNegation(Filter filter) {
  final compiled = compileFilterEvaluator(filter);
  return (properties, {geometry}) => !compiled(properties, geometry: geometry);
}

CompiledFilterEvaluator _compileSpatial(SpatialFilter filter) {
  return (properties, {geometry}) {
    if (geometry == null) return false;
    return switch (filter.operator) {
      SpatialOperator.bbox =>
        intersectsGeometry(geometry, geometryAsPolygon(filter.geometry)),
      SpatialOperator.intersects => intersectsGeometry(geometry, filter.geometry),
      SpatialOperator.within => withinGeometry(geometry, filter.geometry),
      SpatialOperator.contains => containsGeometry(geometry, filter.geometry),
      SpatialOperator.touches => touchesGeometry(geometry, filter.geometry),
      SpatialOperator.crosses => crossesGeometry(geometry, filter.geometry),
      SpatialOperator.overlaps => overlapsGeometry(geometry, filter.geometry),
      SpatialOperator.disjoint => disjointGeometry(geometry, filter.geometry),
    };
  };
}

CompiledFilterEvaluator _compileDistance(DistanceFilter filter) {
  return (properties, {geometry}) {
    if (geometry == null) return false;
    final distance = distanceBetweenGeometries(geometry, filter.geometry);
    return switch (filter.operator) {
      DistanceOperator.dWithin => distance <= filter.distance,
      DistanceOperator.beyond => distance > filter.distance,
    };
  };
}

bool _equals(Object? a, Object? b) {
  if (a == b) return true;
  final numA = _tryNum(a);
  final numB = _tryNum(b);
  if (numA != null && numB != null) return numA == numB;
  return '$a' == '$b';
}

int _compare(Object? a, Object? b) {
  final numA = _tryNum(a);
  final numB = _tryNum(b);
  if (numA != null && numB != null) return numA.compareTo(numB);
  return '$a'.compareTo('$b');
}

num? _tryNum(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
