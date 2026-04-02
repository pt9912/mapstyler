import '../model/mapbox_layer.dart';
import '../model/mapbox_source.dart';
import '../model/mapbox_style.dart';
import 'read_result.dart';

/// Reads a decoded JSON map into a [MapboxStyle].
ReadMapboxResult readMapboxJson(Map<String, Object?> json) {
  final warnings = <String>[];

  // version must be exactly 8
  final version = json['version'];
  if (version is! int || version != 8) {
    return ReadMapboxFailure(
      errors: ['Expected "version": 8, got ${json['version']}'],
    );
  }

  // layers must be a list
  final rawLayers = json['layers'];
  if (rawLayers is! List) {
    return const ReadMapboxFailure(errors: ['Missing or invalid "layers"']);
  }

  // Parse sources
  final sources = <String, MapboxSource>{};
  final rawSources = json['sources'];
  if (rawSources is Map) {
    for (final entry in rawSources.entries) {
      final key = entry.key as String;
      if (entry.value is Map) {
        sources[key] =
            MapboxSource.fromJson(Map<String, Object?>.from(entry.value as Map));
      } else {
        warnings.add('Source "$key": expected Map, got ${entry.value.runtimeType}');
      }
    }
  }

  // Parse layers
  final layers = <MapboxLayer>[];
  for (var i = 0; i < rawLayers.length; i++) {
    final raw = rawLayers[i];
    if (raw is Map) {
      layers.add(MapboxLayer.fromJson(Map<String, Object?>.from(raw)));
    } else {
      warnings.add('Layer at index $i: expected Map, got ${raw.runtimeType}');
    }
  }

  // Parse center
  List<double>? center;
  final rawCenter = json['center'];
  if (rawCenter is List && rawCenter.length >= 2) {
    center = rawCenter.whereType<num>().map((n) => n.toDouble()).toList();
    if (center.length < 2) center = null;
  }

  // Collect extra fields
  const knownRootKeys = {
    'version', 'name', 'metadata', 'sources', 'sprite', 'glyphs',
    'layers', 'center', 'zoom', 'bearing', 'pitch',
  };
  final extra = <String, Object?>{};
  for (final key in json.keys) {
    if (!knownRootKeys.contains(key)) extra[key] = json[key];
  }

  return ReadMapboxSuccess(
    output: MapboxStyle(
      version: 8,
      name: json['name'] as String?,
      metadata: json['metadata'] is Map
          ? Map<String, Object?>.from(json['metadata'] as Map)
          : const {},
      sources: sources,
      sprite: json['sprite'] as String?,
      glyphs: json['glyphs'] as String?,
      layers: layers,
      center: center,
      zoom: _asDouble(json['zoom']),
      bearing: _asDouble(json['bearing']),
      pitch: _asDouble(json['pitch']),
      extra: Map.unmodifiable(extra),
    ),
    warnings: warnings,
  );
}

double? _asDouble(Object? value) => value is num ? value.toDouble() : null;
