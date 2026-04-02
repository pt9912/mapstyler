import 'mapbox_types.dart';

/// A single layer in a Mapbox GL Style.
///
/// Paint and layout properties are kept as raw maps — no fachliche
/// interpretation happens in `mapbox4dart`.
final class MapboxLayer {
  final String id;
  final MapboxLayerType type;

  /// The raw `type` string from JSON, preserved for unknown types.
  final String rawType;

  final String? source;
  final String? sourceLayer;
  final List<Object?>? filter;
  final Map<String, Object?> paint;
  final Map<String, Object?> layout;
  final double? minzoom;
  final double? maxzoom;
  final Map<String, Object?> metadata;

  /// Unknown layer fields, preserved for roundtrip.
  final Map<String, Object?> extra;

  const MapboxLayer({
    required this.id,
    required this.type,
    required this.rawType,
    this.source,
    this.sourceLayer,
    this.filter,
    this.paint = const {},
    this.layout = const {},
    this.minzoom,
    this.maxzoom,
    this.metadata = const {},
    this.extra = const {},
  });

  static const _knownKeys = {
    'id', 'type', 'source', 'source-layer', 'filter',
    'paint', 'layout', 'minzoom', 'maxzoom', 'metadata',
  };

  factory MapboxLayer.fromJson(Map<String, Object?> json) {
    final rawType = json['type'] as String? ?? 'unknown';
    final extra = <String, Object?>{};
    for (final key in json.keys) {
      if (!_knownKeys.contains(key)) extra[key] = json[key];
    }
    return MapboxLayer(
      id: json['id'] as String? ?? '',
      type: MapboxLayerType.fromString(rawType),
      rawType: rawType,
      source: json['source'] as String?,
      sourceLayer: json['source-layer'] as String?,
      filter: json['filter'] as List<Object?>?,
      paint: _asMap(json['paint']),
      layout: _asMap(json['layout']),
      minzoom: _asDouble(json['minzoom']),
      maxzoom: _asDouble(json['maxzoom']),
      metadata: _asMap(json['metadata']),
      extra: Map.unmodifiable(extra),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': rawType,
        if (source != null) 'source': source,
        if (sourceLayer != null) 'source-layer': sourceLayer,
        if (filter != null) 'filter': filter,
        if (layout.isNotEmpty) 'layout': layout,
        if (paint.isNotEmpty) 'paint': paint,
        if (minzoom != null) 'minzoom': minzoom,
        if (maxzoom != null) 'maxzoom': maxzoom,
        if (metadata.isNotEmpty) 'metadata': metadata,
        ...extra,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapboxLayer &&
          id == other.id &&
          type == other.type &&
          rawType == other.rawType &&
          source == other.source &&
          sourceLayer == other.sourceLayer &&
          minzoom == other.minzoom &&
          maxzoom == other.maxzoom;

  @override
  int get hashCode =>
      Object.hash(id, type, rawType, source, sourceLayer, minzoom, maxzoom);
}

Map<String, Object?> _asMap(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const {};

double? _asDouble(Object? value) =>
    value is num ? value.toDouble() : null;
