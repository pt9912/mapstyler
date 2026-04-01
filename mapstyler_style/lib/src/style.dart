import 'dart:convert';

import 'rule.dart';

/// A named collection of styling rules.
///
/// This is the top-level type of the GeoStyler JSON format. A style
/// contains an ordered list of [Rule]s that are evaluated against
/// features to determine their visual appearance.
///
/// ```dart
/// final style = Style.fromJson({
///   'name': 'Land use',
///   'rules': [
///     {
///       'name': 'Residential',
///       'filter': ['==', 'landuse', 'residential'],
///       'symbolizers': [
///         {'kind': 'Fill', 'color': '#ffcc00', 'opacity': 0.5},
///       ],
///     },
///   ],
/// });
/// ```
class Style {
  /// An optional human-readable name for this style.
  final String? name;

  /// The styling rules, evaluated in order.
  final List<Rule> rules;

  const Style({this.name, this.rules = const []});

  /// Deserializes a [Style] from a JSON map.
  factory Style.fromJson(Map<String, dynamic> json) => Style(
        name: json['name'] as String?,
        rules: (json['rules'] as List<dynamic>? ?? [])
            .map((e) => Rule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Deserializes a [Style] from a JSON string.
  factory Style.fromJsonString(String jsonString) =>
      Style.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  /// Serializes this style to a JSON map.
  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  /// Serializes this style to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Style &&
          name == other.name &&
          _listEquals(rules, other.rules);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(rules));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
