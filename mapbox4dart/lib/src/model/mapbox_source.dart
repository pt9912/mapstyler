import 'mapbox_types.dart';

/// A data source in a Mapbox GL Style.
///
/// Source-specific fields (url, tiles, data, etc.) are kept in
/// [properties] without further typing.
final class MapboxSource {
  final MapboxSourceType type;

  /// The raw `type` string from JSON, preserved for unknown types.
  final String rawType;

  /// All source properties except `type`.
  final Map<String, Object?> properties;

  const MapboxSource({
    required this.type,
    required this.rawType,
    this.properties = const {},
  });

  factory MapboxSource.fromJson(Map<String, Object?> json) {
    final rawType = json['type'] as String? ?? 'unknown';
    final props = Map<String, Object?>.of(json)..remove('type');
    return MapboxSource(
      type: MapboxSourceType.fromString(rawType),
      rawType: rawType,
      properties: Map.unmodifiable(props),
    );
  }

  Map<String, Object?> toJson() => {
        'type': rawType,
        ...properties,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapboxSource &&
          type == other.type &&
          rawType == other.rawType &&
          _mapEquals(properties, other.properties);

  @override
  int get hashCode => Object.hash(type, rawType, Object.hashAll(properties.keys));
}

bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}
