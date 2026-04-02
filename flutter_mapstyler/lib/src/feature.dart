import 'package:mapstyler_style/mapstyler_style.dart';

import 'rtree.dart';

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

/// R-Tree-Index-Cache. Liegt extern via [Expando], damit
/// [StyledFeatureCollection] weiterhin `const`-konstruierbar bleibt.
final Expando<RTree> _spatialIndexCache =
    Expando<RTree>('flutter_mapstyler.spatialIndex');

/// Explicit feature collection passed into [StyleRenderer.renderStyle].
///
/// Baut beim ersten Zugriff auf [spatialIndex] einen R-Tree auf, der
/// danach fuer [getFeaturesInExtent] O(log n)-Abfragen ermoeglicht.
final class StyledFeatureCollection {
  /// Creates a collection from an ordered list of features.
  const StyledFeatureCollection(this.features);

  /// Features to render in input order.
  final List<StyledFeature> features;

  /// Lazy R-Tree-Index ueber alle Feature-Geometrien.
  ///
  /// Der Index wird beim ersten Zugriff gebaut (Bulk-Loading) und danach
  /// gecacht. Bei Aenderungen an [features] muss eine neue Collection
  /// erstellt werden.
  RTree get spatialIndex =>
      _spatialIndexCache[this] ??=
          RTree.bulk(features.map((f) => f.geometry).toList());

  /// Liefert alle Features deren BBox den gegebenen [extent] schneidet.
  ///
  /// Nutzt den R-Tree fuer O(log n)-Abfragen statt O(n)-Scan.
  List<StyledFeature> getFeaturesInExtent(EnvelopeGeometry extent) {
    final indices = spatialIndex.search(extent);
    return indices.map((i) => features[i]).toList(growable: false);
  }
}
