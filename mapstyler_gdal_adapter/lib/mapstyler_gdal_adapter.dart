/// GDAL/OGR-based geodata adapter for the mapstyler ecosystem.
///
/// Loads vector features from Shapefiles, GeoJSON, GeoPackage and
/// 100+ other OGR-supported formats into [StyledFeatureCollection].
/// Optionally simplifies geometries during iteration using
/// [simplifyLine] / [simplifyRing] from `mapstyler_style`.
///
/// ```dart
/// import 'package:mapstyler_gdal_adapter/mapstyler_gdal_adapter.dart';
///
/// final features = await loadVectorFile('places.geojson');
/// ```
library mapstyler_gdal_adapter;

export 'src/geometry_converter.dart' show convertGeometry, ConvertedGeometry;
export 'src/load_result.dart';
export 'src/load_vector_file.dart';
export 'src/load_vector_file_sync.dart';
export 'src/vector_layer_info.dart';
