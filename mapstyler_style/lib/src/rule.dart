import 'filter.dart';
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
  final List<Symbolizer> symbolizers;

  /// An optional scale range that controls when this rule is active.
  final ScaleDenominator? scaleDenominator;

  const Rule({
    this.name,
    this.filter,
    this.symbolizers = const [],
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
