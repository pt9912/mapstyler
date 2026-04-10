import 'package:gdal_dart/gdal_dart.dart' as gd;
import 'package:mapstyler_style/mapstyler_style.dart';

/// Result of converting a single OGR geometry.
class ConvertedGeometry {
  /// Creates a converted geometry result.
  const ConvertedGeometry(this.geometries, {this.warning});

  /// Converted mapstyler geometries.
  ///
  /// Multi-geometries are represented as multiple entries.
  final List<Geometry> geometries;

  /// Non-fatal conversion warning, if the source geometry could not be
  /// represented exactly.
  final String? warning;
}

/// Converts a [gd.Geometry] into one or more mapstyler [Geometry] objects.
///
/// Multi-geometries are split into individual geometries.  When
/// [tolerance] is set, lines are simplified via [simplifyLine] and
/// polygon rings via [simplifyRing] during coordinate extraction.
///
/// Returns empty geometries plus a [ConvertedGeometry.warning] for
/// unsupported geometry types (e.g. [gd.GeometryCollection]).
ConvertedGeometry convertGeometry(gd.Geometry geometry, {double? tolerance}) {
  final result = switch (geometry) {
    gd.Point(:final x, :final y) => [PointGeometry(x, y)],
    gd.LineString(:final points) => [
      LineStringGeometry(_simplifyLineFromPoints(points, tolerance)),
    ],
    gd.Polygon(:final rings) => _convertPolygon(rings, tolerance),
    gd.MultiPoint(:final points) =>
      points.map((p) => PointGeometry(p.x, p.y)).toList(),
    gd.MultiLineString(:final lineStrings) =>
      lineStrings
          .map(
            (ls) => LineStringGeometry(
              _simplifyLineFromPoints(ls.points, tolerance),
            ),
          )
          .toList(),
    gd.MultiPolygon(:final polygons) =>
      polygons
          .expand((poly) => _convertPolygon(poly.rings, tolerance))
          .toList(),
    _ => <Geometry>[],
  };
  final warning =
      result.isEmpty
          ? 'unsupported geometry type ${geometry.runtimeType}, skipped'
          : null;
  return ConvertedGeometry(result, warning: warning);
}

/// Converts polygon rings with ring-specific simplification.
List<Geometry> _convertPolygon(List<gd.LineString> rings, double? tolerance) {
  if (rings.isEmpty) return [];
  final simplified = <List<(double, double)>>[];

  for (var i = 0; i < rings.length; i++) {
    final ring = _simplifyRingFromPoints(rings[i].points, tolerance);
    if (ring.length >= 4) {
      simplified.add(ring);
    } else if (i == 0) {
      // Exterior ring too small → return unsimplified polygon.
      return [
        PolygonGeometry(
          rings.map((r) => r.points.map((p) => (p.x, p.y)).toList()).toList(),
        ),
      ];
    }
    // Interior ring too small → silently discard.
  }
  return [PolygonGeometry(simplified)];
}

List<(double, double)> _simplifyLineFromPoints(
  List<gd.Point> points,
  double? tolerance,
) {
  final coords = points.map((p) => (p.x, p.y)).toList();
  return tolerance != null && tolerance > 0
      ? simplifyLine(coords, tolerance)
      : coords;
}

List<(double, double)> _simplifyRingFromPoints(
  List<gd.Point> points,
  double? tolerance,
) {
  final coords = points.map((p) => (p.x, p.y)).toList();
  return tolerance != null && tolerance > 0
      ? simplifyRing(coords, tolerance)
      : coords;
}
