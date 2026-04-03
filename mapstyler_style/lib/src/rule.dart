import 'filter.dart';
import 'sentinel.dart';
import 'symbolizer.dart';

/// A zoom-level range that controls when a [Rule] is active.
///
/// When set on a rule, the rule's symbolizers are only applied if the
/// current map scale denominator falls within `[min, max]`.
///
/// JSON: `{"min": 0, "max": 50000}`
class ScaleDenominator {
  /// Minimum scale denominator (inclusive). `null` means no lower bound.
  final double? min;

  /// Maximum scale denominator (inclusive). `null` means no upper bound.
  final double? max;

  const ScaleDenominator({this.min, this.max});

  /// Deserializes from a JSON map.
  factory ScaleDenominator.fromJson(Map<String, dynamic> json) =>
      ScaleDenominator(
        min: (json['min'] as num?)?.toDouble(),
        max: (json['max'] as num?)?.toDouble(),
      );

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields accept an explicit `null` to clear the value.
  /// Omitted fields retain their current value.
  ///
  /// Expected types: [min] → `double?`, [max] → `double?`.
  ScaleDenominator copyWith({
    Object? min = absent,
    Object? max = absent,
  }) =>
      ScaleDenominator(
        min: min is Absent ? this.min : min as double?,
        max: max is Absent ? this.max : max as double?,
      );

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => {
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaleDenominator && min == other.min && max == other.max;

  @override
  int get hashCode => Object.hash(min, max);
}

/// A styling rule that maps features to symbolizers.
///
/// A rule consists of:
/// - An optional [filter] that selects matching features.
/// - One or more [symbolizers] that define the visual appearance.
/// - An optional [scaleDenominator] for zoom-level control.
///
/// When no filter is set, the rule applies to all features.
class Rule {
  /// An optional human-readable name for this rule.
  final String? name;

  /// An optional filter that selects which features this rule applies to.
  final Filter? filter;

  /// The symbolizers that define how matched features are rendered.
  ///
  /// The list is unmodifiable.  Use [copyWith] to create a modified copy.
  final List<Symbolizer> symbolizers;

  /// An optional scale range that controls when this rule is active.
  final ScaleDenominator? scaleDenominator;

  /// Creates a rule.
  ///
  /// [symbolizers] is defensively copied into an unmodifiable list.
  Rule({
    this.name,
    this.filter,
    List<Symbolizer> symbolizers = const [],
    this.scaleDenominator,
  }) : symbolizers = List.unmodifiable(symbolizers);

  /// Internal constructor that skips the [List.unmodifiable] copy.
  Rule._internal({
    this.name,
    this.filter,
    required this.symbolizers,
    this.scaleDenominator,
  });

  /// Deserializes a [Rule] from a JSON map.
  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
        name: json['name'] as String?,
        filter: json['filter'] != null
            ? Filter.fromJson(json['filter'] as List<dynamic>)
            : null,
        symbolizers: (json['symbolizers'] as List<dynamic>? ?? [])
            .map((e) => Symbolizer.fromJson(e as Map<String, dynamic>))
            .toList(),
        scaleDenominator: json['scaleDenominator'] != null
            ? ScaleDenominator.fromJson(
                json['scaleDenominator'] as Map<String, dynamic>)
            : null,
      );

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields accept an explicit `null` to clear the value.
  /// Omitted fields retain their current value.
  ///
  /// Expected types: [name] → `String?`, [filter] → `Filter?`,
  /// [symbolizers] → `List<Symbolizer>?`,
  /// [scaleDenominator] → `ScaleDenominator?`.
  Rule copyWith({
    Object? name = absent,
    Object? filter = absent,
    List<Symbolizer>? symbolizers,
    Object? scaleDenominator = absent,
  }) {
    final resolvedName = name is Absent ? this.name : name as String?;
    final resolvedFilter = filter is Absent ? this.filter : filter as Filter?;
    final resolvedScale = scaleDenominator is Absent
        ? this.scaleDenominator
        : scaleDenominator as ScaleDenominator?;

    if (symbolizers != null) {
      return Rule(
        name: resolvedName,
        filter: resolvedFilter,
        symbolizers: symbolizers,
        scaleDenominator: resolvedScale,
      );
    }
    return Rule._internal(
      name: resolvedName,
      filter: resolvedFilter,
      symbolizers: this.symbolizers,
      scaleDenominator: resolvedScale,
    );
  }

  /// Serializes this rule to a JSON map.
  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (filter != null) 'filter': filter!.toJson(),
        'symbolizers': symbolizers.map((s) => s.toJson()).toList(),
        if (scaleDenominator != null)
          'scaleDenominator': scaleDenominator!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rule &&
          name == other.name &&
          filter == other.filter &&
          _listEquals(symbolizers, other.symbolizers) &&
          scaleDenominator == other.scaleDenominator;

  @override
  int get hashCode =>
      Object.hash(name, filter, Object.hashAll(symbolizers), scaleDenominator);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
