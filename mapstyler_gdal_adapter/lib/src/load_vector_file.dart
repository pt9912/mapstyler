import 'dart:isolate';

import 'load_result.dart';
import 'load_vector_file_sync.dart';
import 'vector_layer_info.dart';

/// Loads vector features asynchronously in a separate isolate.
///
/// See [loadVectorFileSync] for parameter documentation.
Future<LoadVectorResult> loadVectorFile(
  String path, {
  int layerIndex = 0,
  String? layerName,
  double? simplifyTolerance,
  double? simplifyToleranceMeters,
  ({double minX, double minY, double maxX, double maxY})? spatialFilter,
  String? attributeFilter,
}) {
  return Isolate.run(() => loadVectorFileSync(
        path,
        layerIndex: layerIndex,
        layerName: layerName,
        simplifyTolerance: simplifyTolerance,
        simplifyToleranceMeters: simplifyToleranceMeters,
        spatialFilter: spatialFilter,
        attributeFilter: attributeFilter,
      ));
}

/// Loads multiple pre-computed simplification levels asynchronously.
///
/// Exactly one of [tolerances] or [tolerancesMeters] must be set.
/// Returns a map from effective native tolerance to collection,
/// plus a `0.0` key for the original geometries.
Future<LoadVectorMultiScaleResult> loadVectorFileMultiScale(
  String path, {
  List<double>? tolerances,
  List<double>? tolerancesMeters,
  int layerIndex = 0,
  String? layerName,
  ({double minX, double minY, double maxX, double maxY})? spatialFilter,
  String? attributeFilter,
}) {
  return Isolate.run(() => loadVectorFileMultiScaleSync(
        path,
        tolerances: tolerances,
        tolerancesMeters: tolerancesMeters,
        layerIndex: layerIndex,
        layerName: layerName,
        spatialFilter: spatialFilter,
        attributeFilter: attributeFilter,
      ));
}

/// Inspects layer metadata asynchronously in a separate isolate.
Future<List<VectorLayerInfo>> inspectVectorFile(String path) {
  return Isolate.run(() => inspectVectorFileSync(path));
}
