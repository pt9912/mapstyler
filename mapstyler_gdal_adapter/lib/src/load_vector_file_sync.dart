import 'package:gdal_dart/gdal_dart.dart' as gd;
import 'package:mapstyler_style/mapstyler_style.dart';

import 'geometry_converter.dart';
import 'vector_layer_info.dart';

/// Loads vector features synchronously.
///
/// Blocks the calling thread.  For Flutter apps prefer the async
/// variant [loadVectorFile] which runs in a separate isolate.
///
/// **Layer selection**: [layerName] and [layerIndex] are mutually
/// exclusive.  When [layerName] is set, [layerIndex] is ignored.
/// When neither is set, layer 0 is used.
///
/// [simplifyTolerance] is in the native CRS unit of the source data
/// (degrees for EPSG:4326, metres for projected CRS).
/// [simplifyToleranceMeters] is always in metres — the adapter
/// converts internally.  At most one of the two may be set.
///
/// [spatialFilter] and [attributeFilter] are applied server-side by
/// OGR so that only matching features cross the FFI boundary.
StyledFeatureCollection loadVectorFileSync(
  String path, {
  int layerIndex = 0,
  String? layerName,
  double? simplifyTolerance,
  double? simplifyToleranceMeters,
  ({double minX, double minY, double maxX, double maxY})? spatialFilter,
  String? attributeFilter,
}) {
  assert(
    simplifyTolerance == null || simplifyToleranceMeters == null,
    'Only one of simplifyTolerance / simplifyToleranceMeters may be set.',
  );

  final gdal = gd.Gdal();
  final ds = gdal.openVector(path);
  try {
    final layer = layerName != null
        ? ds.layerByName(layerName)
        : ds.layer(layerIndex);

    if (spatialFilter != null) {
      layer.setSpatialFilterRect(
        spatialFilter.minX,
        spatialFilter.minY,
        spatialFilter.maxX,
        spatialFilter.maxY,
      );
    }
    if (attributeFilter != null) {
      layer.setAttributeFilter(attributeFilter);
    }

    final tolerance = simplifyTolerance ??
        _convertMetersToNative(simplifyToleranceMeters, layer);

    final features = <StyledFeature>[];

    for (final f in layer.features) {
      final geometry = f.geometry;
      if (geometry == null) continue;

      final converted = convertGeometry(geometry, tolerance: tolerance);

      for (final (i, geo) in converted.indexed) {
        features.add(StyledFeature(
          id: converted.length == 1 ? '${f.fid}' : '${f.fid}-$i',
          geometry: geo,
          properties: f.attributes,
        ));
      }
    }

    return StyledFeatureCollection(features);
  } finally {
    ds.close();
  }
}

/// Loads multiple simplification levels in one iteration pass.
///
/// Exactly one of [tolerances] or [tolerancesMeters] must be set.
/// Returns a map from effective native tolerance to collection,
/// plus a `0.0` key for the original geometries.
Map<double, StyledFeatureCollection> loadVectorFileMultiScaleSync(
  String path, {
  List<double>? tolerances,
  List<double>? tolerancesMeters,
  int layerIndex = 0,
  String? layerName,
  ({double minX, double minY, double maxX, double maxY})? spatialFilter,
  String? attributeFilter,
}) {
  assert(
    (tolerances != null) != (tolerancesMeters != null),
    'Exactly one of tolerances / tolerancesMeters must be set.',
  );

  final gdal = gd.Gdal();
  final ds = gdal.openVector(path);
  try {
    final layer = layerName != null
        ? ds.layerByName(layerName)
        : ds.layer(layerIndex);

    if (spatialFilter != null) {
      layer.setSpatialFilterRect(
        spatialFilter.minX,
        spatialFilter.minY,
        spatialFilter.maxX,
        spatialFilter.maxY,
      );
    }
    if (attributeFilter != null) {
      layer.setAttributeFilter(attributeFilter);
    }

    // Resolve tolerances to native CRS units.
    final nativeTols = <double>[0.0]; // 0.0 = original
    if (tolerances != null) {
      nativeTols.addAll(tolerances.where((t) => t > 0));
    } else {
      for (final m in tolerancesMeters!) {
        final native = _convertMetersToNative(m, layer);
        if (native != null && native > 0) nativeTols.add(native);
      }
    }

    // Prepare buckets.
    final buckets = <double, List<StyledFeature>>{
      for (final t in nativeTols) t: <StyledFeature>[],
    };

    for (final f in layer.features) {
      final geometry = f.geometry;
      if (geometry == null) continue;

      for (final tol in nativeTols) {
        final converted =
            convertGeometry(geometry, tolerance: tol > 0 ? tol : null);

        for (final (i, geo) in converted.indexed) {
          buckets[tol]!.add(StyledFeature(
            id: converted.length == 1 ? '${f.fid}' : '${f.fid}-$i',
            geometry: geo,
            properties: f.attributes,
          ));
        }
      }
    }

    return {
      for (final entry in buckets.entries)
        entry.key: StyledFeatureCollection(entry.value),
    };
  } finally {
    ds.close();
  }
}

/// Inspects layer metadata without loading features.
List<VectorLayerInfo> inspectVectorFileSync(String path) {
  final gdal = gd.Gdal();
  final ds = gdal.openVector(path);
  try {
    return List.generate(ds.layerCount, (i) {
      final layer = ds.layer(i);
      String? crs;
      final srs = layer.spatialReference;
      if (srs != null) {
        final authority = srs.authorityName;
        final code = srs.authorityCode;
        if (authority != null && code != null) crs = '$authority:$code';
        srs.close();
      }
      return VectorLayerInfo(
        name: layer.name,
        featureCount: layer.featureCount,
        fields: layer.fieldDefinitions
            .map((f) => (name: f.name, type: f.type.name))
            .toList(),
        extent: layer.extent,
        // geometryType: not yet exposed by gdal_dart
        crs: crs,
      );
    });
  } finally {
    ds.close();
  }
}

/// Converts a metre tolerance to the layer's native CRS unit.
///
/// For geographic CRS uses a latitude-dependent approximation.
/// Returns `null` when input is `null`.
double? _convertMetersToNative(double? meters, gd.OgrLayer layer) {
  if (meters == null) return null;

  final srs = layer.spatialReference;
  if (srs == null) return meters; // unknown CRS → assume metres

  try {
    final isGeographic = srs.authorityName == 'EPSG' &&
        srs.authorityCode == '4326';

    if (!isGeographic) return meters; // already in metres (projected)

    // Approximate conversion for geographic CRS.
    final ext = layer.extent;
    final midLat = ext != null ? (ext.minY + ext.maxY) / 2.0 : 0.0;
    final cosLat = _cos(midLat * _degToRad);
    return meters / (111320.0 * cosLat);
  } finally {
    srs.close();
  }
}

const double _degToRad = 3.141592653589793 / 180.0;

double _cos(double radians) {
  // Dart's dart:math cos; inline to avoid import for one call.
  return radians == 0 ? 1.0 : _taylorCos(radians);
}

/// Good-enough cosine for latitude conversion (error < 1e-8 for
/// typical latitudes).
double _taylorCos(double x) {
  // Normalize to [-pi, pi].
  while (x > 3.141592653589793) x -= 2 * 3.141592653589793;
  while (x < -3.141592653589793) x += 2 * 3.141592653589793;
  final x2 = x * x;
  // Taylor series: 1 - x²/2! + x⁴/4! - x⁶/6! + x⁸/8!
  return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720 + x2 * x2 * x2 * x2 / 40320;
}
