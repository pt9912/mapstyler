import 'package:mapstyler_style/mapstyler_style.dart';

import 'rtree.dart';

// Re-export so that existing consumers keep working with
// `import 'package:flutter_mapstyler/flutter_mapstyler.dart'`.
export 'package:mapstyler_style/mapstyler_style.dart'
    show StyledFeature, StyledFeatureCollection;

/// Callback when a feature is tapped on the map.
typedef FeatureTapCallback = void Function(StyledFeature feature);

/// Callback when a feature is long-pressed on the map.
typedef FeatureLongPressCallback = void Function(StyledFeature feature);

/// R-Tree-Index-Cache. Liegt extern via [Expando], damit
/// [StyledFeatureCollection] weiterhin `const`-konstruierbar bleibt.
final Expando<RTree> _spatialIndexCache =
    Expando<RTree>('flutter_mapstyler.spatialIndex');

/// Spatial-index extensions on [StyledFeatureCollection].
///
/// The R-Tree is built lazily on first access and cached via [Expando].
extension StyledFeatureCollectionSpatial on StyledFeatureCollection {
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
