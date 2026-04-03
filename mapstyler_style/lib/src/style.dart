import 'dart:convert';

import 'rule.dart';
import 'sentinel.dart';

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
  ///
  /// The list is unmodifiable.  Use [copyWith] to create a modified copy.
  final List<Rule> rules;

  /// Creates a style.
  ///
  /// [rules] is defensively copied into an unmodifiable list.
  Style({this.name, List<Rule> rules = const []})
      : rules = List.unmodifiable(rules);

  /// Internal constructor that skips the [List.unmodifiable] copy.
  ///
  /// Use only when [rules] is already unmodifiable (e.g. from [copyWith]).
  Style._internal({this.name, required this.rules});

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

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields accept an explicit `null` to clear the value.
  /// Omitted fields retain their current value.
  ///
  /// Expected types: [name] → `String?`, [rules] → `List<Rule>?`.
  Style copyWith({
    Object? name = absent,
    List<Rule>? rules,
  }) =>
      rules != null
          ? Style(
              name: name is Absent ? this.name : name as String?,
              rules: rules,
            )
          : Style._internal(
              name: name is Absent ? this.name : name as String?,
              rules: this.rules,
            );

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
