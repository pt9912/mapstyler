import 'mapbox_layer.dart';
import 'mapbox_source.dart';

/// Root model for a Mapbox GL Style document (version 8).
final class MapboxStyle {
  final int version;
  final String? name;
  final Map<String, Object?> metadata;
  final Map<String, MapboxSource> sources;
  final String? sprite;
  final String? glyphs;
  final List<MapboxLayer> layers;
  final List<double>? center;
  final double? zoom;
  final double? bearing;
  final double? pitch;

  /// Unknown root fields, preserved for roundtrip.
  final Map<String, Object?> extra;

  const MapboxStyle({
    required this.version,
    this.name,
    this.metadata = const {},
    this.sources = const {},
    this.sprite,
    this.glyphs,
    this.layers = const [],
    this.center,
    this.zoom,
    this.bearing,
    this.pitch,
    this.extra = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapboxStyle &&
          version == other.version &&
          name == other.name &&
          sprite == other.sprite &&
          glyphs == other.glyphs &&
          zoom == other.zoom &&
          bearing == other.bearing &&
          pitch == other.pitch &&
          layers.length == other.layers.length;

  @override
  int get hashCode =>
      Object.hash(version, name, sprite, glyphs, zoom, bearing, pitch);
}
