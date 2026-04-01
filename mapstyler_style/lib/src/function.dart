/// GeoStyler function — JSON: {"name": "property", "args": ["size"]}
sealed class GeoStylerFunction {
  const GeoStylerFunction();

  String get name;

  factory GeoStylerFunction.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return switch (name) {
      'property' => PropertyGet._fromJson(json),
      _ => throw FormatException('Unknown GeoStyler function: $name'),
    };
  }

  Map<String, dynamic> toJson();
}

final class PropertyGet extends GeoStylerFunction {
  final String propertyName;
  const PropertyGet(this.propertyName);

  @override
  String get name => 'property';

  factory PropertyGet._fromJson(Map<String, dynamic> json) {
    final args = json['args'] as List;
    return PropertyGet(args[0] as String);
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': 'property',
        'args': [propertyName],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyGet && propertyName == other.propertyName;

  @override
  int get hashCode => propertyName.hashCode;
}
