# mapstyler_gdal_adapter

GDAL/OGR-based vector data adapter for the [mapstyler](https://github.com/pt9912/mapstyler) ecosystem.

Loads Shapefiles, GeoJSON, GeoPackage and other OGR-supported vector formats into `StyledFeatureCollection` from `mapstyler_style`.

## Features

- **Vector loading** — sync and isolate-based async APIs.
- **Layer selection** — choose by layer index or layer name.
- **Feature filtering** — OGR spatial and attribute filters before data crosses the FFI boundary.
- **Geometry conversion** — Point, LineString, Polygon, MultiPoint, MultiLineString and MultiPolygon.
- **Simplification** — native-unit and meter-based tolerance using `mapstyler_style` geometry simplification.
- **Multi-scale loading** — produce several simplification levels in one pass.
- **Layer inspection** — names, feature counts, fields, extents, geometry type and CRS.
- **Warnings** — unsupported or empty geometries are reported without aborting the load.

Pure Dart API with a native GDAL runtime dependency through `gdal_dart`.

## Usage

```dart
import 'package:mapstyler_gdal_adapter/mapstyler_gdal_adapter.dart';

final result = await loadVectorFile(
  'data/places.geojson',
  simplifyToleranceMeters: 5,
  spatialFilter: (
    minX: 7.0,
    minY: 46.0,
    maxX: 8.0,
    maxY: 47.0,
  ),
);

print('Features: ${result.features.features.length}');
for (final warning in result.warnings) {
  print('Warning: $warning');
}
```

## Native Dependency

This package uses `gdal_dart` and requires GDAL/OGR native libraries at runtime.

## License

MIT — see [LICENSE](LICENSE).
