import '../model/mapbox_style.dart';

/// Serializes a [MapboxStyle] to a JSON-compatible map.
Map<String, Object?> writeMapboxJson(MapboxStyle style) {
  final json = <String, Object?>{
    'version': style.version,
  };

  if (style.name != null) json['name'] = style.name;
  if (style.metadata.isNotEmpty) json['metadata'] = style.metadata;

  // Sources
  json['sources'] = {
    for (final entry in style.sources.entries) entry.key: entry.value.toJson(),
  };

  if (style.sprite != null) json['sprite'] = style.sprite;
  if (style.glyphs != null) json['glyphs'] = style.glyphs;
  if (style.center != null) json['center'] = style.center;
  if (style.zoom != null) json['zoom'] = style.zoom;
  if (style.bearing != null) json['bearing'] = style.bearing;
  if (style.pitch != null) json['pitch'] = style.pitch;

  // Layers
  json['layers'] = [
    for (final layer in style.layers) layer.toJson(),
  ];

  // Extra fields (roundtrip preservation)
  json.addAll(style.extra);

  return json;
}
