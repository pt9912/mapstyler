import 'filter.dart';
import 'symbolizer.dart';

class ScaleDenominator {
  final double? min;
  final double? max;

  const ScaleDenominator({this.min, this.max});

  factory ScaleDenominator.fromJson(Map<String, dynamic> json) =>
      ScaleDenominator(
        min: (json['min'] as num?)?.toDouble(),
        max: (json['max'] as num?)?.toDouble(),
      );

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

class Rule {
  final String? name;
  final Filter? filter;
  final List<Symbolizer> symbolizers;
  final ScaleDenominator? scaleDenominator;

  const Rule({
    this.name,
    this.filter,
    this.symbolizers = const [],
    this.scaleDenominator,
  });

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
