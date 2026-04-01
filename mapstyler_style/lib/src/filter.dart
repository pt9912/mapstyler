import 'expression.dart';
import 'geometry.dart';

// ---------------------------------------------------------------------------
// Operator enums
// ---------------------------------------------------------------------------

/// Comparison operators for [ComparisonFilter].
enum ComparisonOperator {
  /// Equal: `==`
  eq('=='),

  /// Not equal: `!=`
  neq('!='),

  /// Less than: `<`
  lt('<'),

  /// Greater than: `>`
  gt('>'),

  /// Less than or equal: `<=`
  lte('<='),

  /// Greater than or equal: `>=`
  gte('>=');

  /// The JSON string representation of this operator.
  final String jsonValue;
  const ComparisonOperator(this.jsonValue);

  /// Parses a [ComparisonOperator] from its JSON string.
  ///
  /// Throws [FormatException] if [value] is not a known operator.
  static ComparisonOperator fromJson(String value) =>
      ComparisonOperator.values.firstWhere(
        (e) => e.jsonValue == value,
        orElse: () => throw FormatException('Unknown operator: $value'),
      );
}

/// Logical combination operators for [CombinationFilter].
enum CombinationOperator {
  /// Logical AND: `&&`
  and('&&'),

  /// Logical OR: `||`
  or('||');

  /// The JSON string representation of this operator.
  final String jsonValue;
  const CombinationOperator(this.jsonValue);

  /// Parses a [CombinationOperator] from its JSON string.
  ///
  /// Throws [FormatException] if [value] is not a known operator.
  static CombinationOperator fromJson(String value) =>
      CombinationOperator.values.firstWhere(
        (e) => e.jsonValue == value,
        orElse: () => throw FormatException('Unknown operator: $value'),
      );
}

/// Spatial relation operators for [SpatialFilter].
///
/// OGC Filter Encoding 2.0 compliant. **mapstyler extension** — not
/// present in the GeoStyler TypeScript original.
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

/// Distance-based operators for [DistanceFilter].
///
/// **mapstyler extension** — not present in the GeoStyler TypeScript
/// original.
enum DistanceOperator {
  /// Features within a given distance.
  dWithin,

  /// Features beyond a given distance.
  beyond,
}

// ---------------------------------------------------------------------------
// Filter hierarchy
// ---------------------------------------------------------------------------

/// A filter that selects features based on their properties or geometry.
///
/// Uses GeoStyler's array-based JSON format:
/// ```json
/// ["==", "landuse", "residential"]
/// ["&&", ["==", "type", "road"], [">", "width", 5]]
/// ```
///
/// Subclasses:
/// - [ComparisonFilter] — property value comparisons (`==`, `!=`, `<`, etc.)
/// - [CombinationFilter] — logical AND/OR of sub-filters.
/// - [NegationFilter] — logical NOT.
/// - [SpatialFilter] — geometry-based filtering (mapstyler extension).
/// - [DistanceFilter] — distance-based filtering (mapstyler extension).
sealed class Filter {
  const Filter();

  /// Deserializes a filter from its array-based JSON representation.
  ///
  /// Dispatches on the operator string at index 0.
  factory Filter.fromJson(List<dynamic> json) {
    final op = json[0] as String;
    return switch (op) {
      '!' => NegationFilter._fromJson(json),
      '&&' || '||' => CombinationFilter._fromJson(json),
      'bbox' ||
      'intersects' ||
      'within' ||
      'contains' ||
      'touches' ||
      'crosses' ||
      'overlaps' ||
      'disjoint' =>
        SpatialFilter._fromJson(json),
      'dWithin' || 'beyond' => DistanceFilter._fromJson(json),
      _ => ComparisonFilter._fromJson(json),
    };
  }

  /// Serializes this filter to its array-based JSON representation.
  List<dynamic> toJson();
}

// ---------------------------------------------------------------------------
// ComparisonFilter
// ---------------------------------------------------------------------------

/// Compares a feature property against a value.
///
/// JSON: `["==", "fieldName", "value"]`
final class ComparisonFilter extends Filter {
  /// The comparison operator.
  final ComparisonOperator operator;

  /// The property name expression (typically a literal string).
  final Expression<String> property;

  /// The value to compare against.
  final Expression<Object> value;

  const ComparisonFilter({
    required this.operator,
    required this.property,
    required this.value,
  });

  factory ComparisonFilter._fromJson(List<dynamic> json) {
    final op = ComparisonOperator.fromJson(json[0] as String);
    final property =
        Expression.fromJson<String>(json[1], (v) => v as String);
    final value =
        Expression.fromJson<Object>(json[2], (v) => v as Object);
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

// ---------------------------------------------------------------------------
// CombinationFilter
// ---------------------------------------------------------------------------

/// Combines multiple sub-filters with a logical operator.
///
/// JSON: `["&&", <filter1>, <filter2>, ...]`
final class CombinationFilter extends Filter {
  /// The logical operator ([CombinationOperator.and] or
  /// [CombinationOperator.or]).
  final CombinationOperator operator;

  /// The sub-filters to combine.
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

// ---------------------------------------------------------------------------
// NegationFilter
// ---------------------------------------------------------------------------

/// Negates a sub-filter (logical NOT).
///
/// JSON: `["!", <filter>]`
final class NegationFilter extends Filter {
  /// The filter to negate.
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

// ---------------------------------------------------------------------------
// SpatialFilter
// ---------------------------------------------------------------------------

/// Filters features by spatial relationship to a geometry.
///
/// **mapstyler extension** — OGC Filter Encoding 2.0 compliant,
/// not present in the GeoStyler TypeScript original.
///
/// JSON: `["intersects", <geometry>]` or
/// `["intersects", "propertyName", <geometry>]`
final class SpatialFilter extends Filter {
  /// The spatial relationship to test.
  final SpatialOperator operator;

  /// Optional geometry property name. When `null`, the feature's
  /// default geometry is used.
  final String? propertyName;

  /// The reference geometry to test against.
  final Geometry geometry;

  const SpatialFilter({
    required this.operator,
    this.propertyName,
    required this.geometry,
  });

  factory SpatialFilter._fromJson(List<dynamic> json) {
    final op = SpatialOperator.values.firstWhere(
      (e) => e.name == json[0],
      orElse: () =>
          throw FormatException('Unknown spatial operator: ${json[0]}'),
    );
    // json[1] is either a propertyName (String) or geometry (Map).
    if (json[1] is String) {
      return SpatialFilter(
        operator: op,
        propertyName: json[1] as String,
        geometry: Geometry.fromJson(json[2] as Map<String, dynamic>),
      );
    }
    return SpatialFilter(
      operator: op,
      geometry: Geometry.fromJson(json[1] as Map<String, dynamic>),
    );
  }

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

// ---------------------------------------------------------------------------
// DistanceFilter
// ---------------------------------------------------------------------------

/// Filters features by distance to a reference geometry.
///
/// **mapstyler extension** — OGC Filter Encoding 2.0 compliant,
/// not present in the GeoStyler TypeScript original.
///
/// JSON: `["dWithin", <geometry>, 1000.0, "m"]` or
/// `["dWithin", "propertyName", <geometry>, 1000.0, "m"]`
final class DistanceFilter extends Filter {
  /// Whether to match features within or beyond the distance.
  final DistanceOperator operator;

  /// Optional geometry property name.
  final String? propertyName;

  /// The reference geometry to measure distance from.
  final Geometry geometry;

  /// The distance threshold.
  final double distance;

  /// The unit of measurement (e.g. `"m"`, `"km"`).
  final String units;

  const DistanceFilter({
    required this.operator,
    this.propertyName,
    required this.geometry,
    required this.distance,
    this.units = '',
  });

  factory DistanceFilter._fromJson(List<dynamic> json) {
    final op = DistanceOperator.values.firstWhere(
      (e) => e.name == json[0],
      orElse: () =>
          throw FormatException('Unknown distance operator: ${json[0]}'),
    );
    // json[1] is either a propertyName (String) or geometry (Map).
    if (json[1] is String) {
      return DistanceFilter(
        operator: op,
        propertyName: json[1] as String,
        geometry: Geometry.fromJson(json[2] as Map<String, dynamic>),
        distance: (json[3] as num).toDouble(),
        units: json[4] as String,
      );
    }
    return DistanceFilter(
      operator: op,
      geometry: Geometry.fromJson(json[1] as Map<String, dynamic>),
      distance: (json[2] as num).toDouble(),
      units: json[3] as String,
    );
  }

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
