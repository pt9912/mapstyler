import 'expression.dart';
import 'geometry.dart';

// -- Enums --

enum ComparisonOperator {
  eq('=='),
  neq('!='),
  lt('<'),
  gt('>'),
  lte('<='),
  gte('>=');

  final String jsonValue;
  const ComparisonOperator(this.jsonValue);

  static ComparisonOperator fromJson(String value) =>
      ComparisonOperator.values.firstWhere(
        (e) => e.jsonValue == value,
        orElse: () => throw FormatException('Unknown operator: $value'),
      );
}

enum CombinationOperator {
  and('&&'),
  or('||');

  final String jsonValue;
  const CombinationOperator(this.jsonValue);

  static CombinationOperator fromJson(String value) =>
      CombinationOperator.values.firstWhere(
        (e) => e.jsonValue == value,
        orElse: () => throw FormatException('Unknown operator: $value'),
      );
}

enum SpatialOperator {
  bbox,
  intersects,
  within,
  contains,
  touches,
  crosses,
  overlaps,
  disjoint,
}

enum DistanceOperator {
  dWithin,
  beyond,
}

// -- Filter hierarchy --

/// GeoStyler filter — array-based JSON: ["==", "landuse", "residential"]
sealed class Filter {
  const Filter();

  factory Filter.fromJson(List<dynamic> json) {
    final op = json[0] as String;
    return switch (op) {
      '!' => NegationFilter._fromJson(json),
      '&&' || '||' => CombinationFilter._fromJson(json),
      _ => ComparisonFilter._fromJson(json),
    };
  }

  List<dynamic> toJson();
}

final class ComparisonFilter extends Filter {
  final ComparisonOperator operator;
  final Expression<String> property;
  final Expression<Object> value;

  const ComparisonFilter({
    required this.operator,
    required this.property,
    required this.value,
  });

  factory ComparisonFilter._fromJson(List<dynamic> json) {
    final op = ComparisonOperator.fromJson(json[0] as String);
    final property = Expression.fromJson<String>(json[1], (v) => v as String);
    final value = Expression.fromJson<Object>(json[2], (v) => v as Object);
    return ComparisonFilter(operator: op, property: property, value: value);
  }

  @override
  List<dynamic> toJson() => [
        operator.jsonValue,
        property.toJson(),
        value.toJson(),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonFilter &&
          this.operator == other.operator &&
          property == other.property &&
          value == other.value;

  @override
  int get hashCode => Object.hash(operator, property, value);
}

final class CombinationFilter extends Filter {
  final CombinationOperator operator;
  final List<Filter> filters;

  const CombinationFilter({
    required this.operator,
    required this.filters,
  });

  factory CombinationFilter._fromJson(List<dynamic> json) {
    final op = CombinationOperator.fromJson(json[0] as String);
    final filters = [
      for (var i = 1; i < json.length; i++)
        Filter.fromJson(json[i] as List<dynamic>),
    ];
    return CombinationFilter(operator: op, filters: filters);
  }

  @override
  List<dynamic> toJson() => [
        operator.jsonValue,
        ...filters.map((f) => f.toJson()),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombinationFilter &&
          this.operator == other.operator &&
          _listEquals(filters, other.filters);

  @override
  int get hashCode => Object.hash(operator, Object.hashAll(filters));
}

final class NegationFilter extends Filter {
  final Filter filter;
  const NegationFilter({required this.filter});

  factory NegationFilter._fromJson(List<dynamic> json) =>
      NegationFilter(filter: Filter.fromJson(json[1] as List<dynamic>));

  @override
  List<dynamic> toJson() => ['!', filter.toJson()];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NegationFilter && filter == other.filter;

  @override
  int get hashCode => filter.hashCode;
}

/// Spatial filter — mapstyler extension (not in GeoStyler TS).
/// OGC Filter Encoding 2.0 compliant.
final class SpatialFilter extends Filter {
  final SpatialOperator operator;
  final String? propertyName;
  final Geometry geometry;

  const SpatialFilter({
    required this.operator,
    this.propertyName,
    required this.geometry,
  });

  @override
  List<dynamic> toJson() => [
        operator.name,
        if (propertyName != null) propertyName!,
        geometry.toJson(),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialFilter &&
          this.operator == other.operator &&
          propertyName == other.propertyName &&
          geometry == other.geometry;

  @override
  int get hashCode => Object.hash(operator, propertyName, geometry);
}

/// Distance filter — mapstyler extension (not in GeoStyler TS).
/// OGC Filter Encoding 2.0: DWithin, Beyond.
final class DistanceFilter extends Filter {
  final DistanceOperator operator;
  final String? propertyName;
  final Geometry geometry;
  final double distance;
  final String units;

  const DistanceFilter({
    required this.operator,
    this.propertyName,
    required this.geometry,
    required this.distance,
    this.units = '',
  });

  @override
  List<dynamic> toJson() => [
        operator.name,
        if (propertyName != null) propertyName!,
        geometry.toJson(),
        distance,
        units,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistanceFilter &&
          this.operator == other.operator &&
          propertyName == other.propertyName &&
          geometry == other.geometry &&
          distance == other.distance &&
          units == other.units;

  @override
  int get hashCode =>
      Object.hash(operator, propertyName, geometry, distance, units);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
