import 'package:mapstyler_style/mapstyler_style.dart';

/// Minimal feature model for styled map data.
///
/// A feature combines a [Geometry] with an optional [id] and arbitrary
/// [properties].  It is intentionally pure Dart with no Flutter dependency
/// so that data-loading packages can produce features without pulling in
/// a rendering framework.
///
/// **Equality**: This class does not override `==` / `hashCode`.
/// Features are compared by identity, not by value.  A deep comparison
/// of [properties] would be expensive and is rarely needed — identity
/// via [id] is the intended comparison path.
final class StyledFeature {
  /// Creates a feature with geometry and arbitrary properties.
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

/// An ordered collection of [StyledFeature]s.
///
/// This base class lives in `mapstyler_style` and has no Flutter dependency.
/// `flutter_mapstyler` extends it with a spatial R-Tree index for
/// viewport-based queries.
///
/// Unlike [Style.rules] and [Rule.symbolizers], [features] is **not**
/// wrapped with `List.unmodifiable`.  The `const` constructor is
/// preserved because collections are typically built once by a loader
/// and not mutated afterwards.  Callers should treat the list as
/// immutable.
final class StyledFeatureCollection {
  /// Creates a collection from an ordered list of features.
  const StyledFeatureCollection(this.features);

  /// Features in input order.
  final List<StyledFeature> features;
}
