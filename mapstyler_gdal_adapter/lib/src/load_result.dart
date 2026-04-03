import 'package:mapstyler_style/mapstyler_style.dart';

/// Result of a vector file load operation.
///
/// Contains the loaded [features] and any [warnings] about data that
/// could not be fully converted (e.g. unsupported geometry types).
class LoadVectorResult {
  const LoadVectorResult({
    required this.features,
    this.warnings = const [],
  });

  /// The loaded and optionally simplified features.
  final StyledFeatureCollection features;

  /// Non-fatal warnings collected during loading.
  ///
  /// Typical warnings:
  /// - `'Feature $fid: unsupported geometry type GeometryCollection, skipped'`
  /// - `'Feature $fid: null geometry, skipped'`
  final List<String> warnings;
}
