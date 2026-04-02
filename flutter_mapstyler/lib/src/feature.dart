import 'package:mapstyler_style/mapstyler_style.dart';

/// Callback when a feature is tapped on the map.
typedef FeatureTapCallback = void Function(StyledFeature feature);

/// Callback when a feature is long-pressed on the map.
typedef FeatureLongPressCallback = void Function(StyledFeature feature);

/// Minimal feature model consumed by [StyleRenderer].
///
/// The type intentionally depends only on the [Geometry] model from
/// `mapstyler_style`. Parsing GeoJSON or other source formats is expected to
/// happen outside this package.
final class StyledFeature {
  /// Creates a renderable feature with geometry and arbitrary properties.
  const StyledFeature({
    this.id,
    required this.geometry,
    this.properties = const <String, Object?>{},
  });

  /// Stable identifier used for callbacks and per-feature expression caching.
  final Object? id;

  /// Geometry rendered by the symbolizers that match this feature.
  final Geometry geometry;

  /// Arbitrary property bag used by filters and expressions.
  final Map<String, Object?> properties;
}

/// Explicit feature collection passed into [StyleRenderer.renderStyle].
final class StyledFeatureCollection {
  /// Creates a collection from an ordered list of features.
  const StyledFeatureCollection(this.features);

  /// Features to render in input order.
  final List<StyledFeature> features;
}
