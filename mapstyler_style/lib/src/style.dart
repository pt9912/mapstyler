import 'dart:convert';

import 'rule.dart';

class Style {
  final String? name;
  final List<Rule> rules;

  const Style({this.name, this.rules = const []});

  factory Style.fromJson(Map<String, dynamic> json) => Style(
        name: json['name'] as String?,
        rules: (json['rules'] as List<dynamic>? ?? [])
            .map((e) => Rule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  factory Style.fromJsonString(String jsonString) =>
      Style.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'rules': rules.map((r) => r.toJson()).toList(),
      };

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
