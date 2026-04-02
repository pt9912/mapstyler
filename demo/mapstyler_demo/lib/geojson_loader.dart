import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

/// Konvertiert eine GeoJSON-FeatureCollection zu [StyledFeatureCollection].
///
/// Multi-Geometrien (MultiPoint, MultiLineString, MultiPolygon) werden
/// in Einzel-Features aufgesplittet, da das mapstyler_style-Modell
/// nur einfache Geometrien kennt.
StyledFeatureCollection geojsonToFeatures(Map<String, Object?> geojson) {
  final type = geojson['type'] as String?;
  if (type != 'FeatureCollection') {
    throw FormatException('Erwartet FeatureCollection, erhalten: $type');
  }

  final rawFeatures = geojson['features'] as List;
  final features = <StyledFeature>[];

  for (final raw in rawFeatures) {
    final f = raw as Map<String, Object?>;
    final id = f['id'];
    final props = Map<String, Object?>.from(f['properties'] as Map? ?? {});
    final geo = f['geometry'] as Map<String, Object?>?;
    if (geo == null) continue;

    final geometries = _parseGeometry(geo);
    for (var i = 0; i < geometries.length; i++) {
      features.add(StyledFeature(
        id: geometries.length == 1 ? id : '$id-$i',
        geometry: geometries[i],
        properties: props,
      ));
    }
  }

  return StyledFeatureCollection(features);
}

// ---------------------------------------------------------------------------

List<Geometry> _parseGeometry(Map<String, Object?> geo) {
  final type = geo['type'] as String;
  final coords = geo['coordinates'];

  return switch (type) {
    'Point' => [_point(coords as List)],
    'LineString' => [_lineString(coords as List)],
    'Polygon' => [_polygon(coords as List)],
    'MultiPoint' =>
      (coords as List).map((c) => _point(c as List)).toList(),
    'MultiLineString' =>
      (coords as List).map((c) => _lineString(c as List)).toList(),
    'MultiPolygon' =>
      (coords as List).map((c) => _polygon(c as List)).toList(),
    _ => <Geometry>[],
  };
}

(double, double) _coord(List c) =>
    ((c[0] as num).toDouble(), (c[1] as num).toDouble());

PointGeometry _point(List coords) {
  final c = _coord(coords);
  return PointGeometry(c.$1, c.$2);
}

LineStringGeometry _lineString(List coords) =>
    LineStringGeometry([for (final c in coords) _coord(c as List)]);

PolygonGeometry _polygon(List coords) => PolygonGeometry([
      for (final ring in coords)
        [for (final c in ring as List) _coord(c as List)],
    ]);
