import 'package:flutter_mapstyler/flutter_mapstyler.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

import 'geojson_loader.dart';
import 'shapefile_loader.dart';

/// Datenquellen fuer die Demo-Features.
enum FeatureSource {
  hardcoded('Hardcoded'),
  geojson('GeoJSON'),
  shapefile('Shapefile');

  const FeatureSource(this.label);
  final String label;
}

/// Laedt Features je nach gewaehlter Datenquelle.
StyledFeatureCollection loadFeatures(FeatureSource source) {
  return switch (source) {
    FeatureSource.hardcoded => _hardcodedFeatures(),
    FeatureSource.geojson => geojsonToFeatures(sampleGeojson),
    FeatureSource.shapefile => _loadShapefile(),
  };
}

StyledFeatureCollection _loadShapefile() {
  // Shapefile programmatisch aus denselben Geometrien erzeugen
  // (demonstriert SHP/DBF-Writer + Reader Roundtrip)
  const geometries = <Geometry>[
    PolygonGeometry([
      [
        (13.3930, 52.5198),
        (13.3994, 52.5198),
        (13.3994, 52.5248),
        (13.3930, 52.5248),
        (13.3930, 52.5198),
      ],
    ]),
    PolygonGeometry([
      [
        (13.3998, 52.5177),
        (13.4062, 52.5177),
        (13.4062, 52.5225),
        (13.3998, 52.5225),
        (13.3998, 52.5177),
      ],
    ]),
    PolygonGeometry([
      [
        (13.4070, 52.5195),
        (13.4138, 52.5195),
        (13.4138, 52.5246),
        (13.4070, 52.5246),
        (13.4070, 52.5195),
      ],
    ]),
  ];

  const fields = [
    (name: 'name', length: 30),
    (name: 'landuse', length: 20),
  ];

  const records = [
    {'name': 'Canal Basin', 'landuse': 'water'},
    {'name': 'Residential Quarter', 'landuse': 'residential'},
    {'name': 'Market Blocks', 'landuse': 'commercial'},
  ];

  final shpBytes = buildShpBytes(geometries);
  final dbfBytes = buildDbfBytes(fields, records);
  return shapefileToFeatures(shpBytes: shpBytes, dbfBytes: dbfBytes);
}

StyledFeatureCollection _hardcodedFeatures() {
  return const StyledFeatureCollection([
    StyledFeature(
      id: 'water-1',
      geometry: PolygonGeometry([
        [
          (13.3930, 52.5198),
          (13.3994, 52.5198),
          (13.3994, 52.5248),
          (13.3930, 52.5248),
          (13.3930, 52.5198),
        ],
      ]),
      properties: {'class': 'ocean', 'name': 'Canal Basin'},
    ),
    StyledFeature(
      id: 'residential-1',
      geometry: PolygonGeometry([
        [
          (13.3998, 52.5177),
          (13.4062, 52.5177),
          (13.4062, 52.5225),
          (13.3998, 52.5225),
          (13.3998, 52.5177),
        ],
      ]),
      properties: {'landuse': 'residential', 'name': 'Residential Quarter'},
    ),
    StyledFeature(
      id: 'commercial-1',
      geometry: PolygonGeometry([
        [
          (13.4070, 52.5195),
          (13.4138, 52.5195),
          (13.4138, 52.5246),
          (13.4070, 52.5246),
          (13.4070, 52.5195),
        ],
      ]),
      properties: {'landuse': 'commercial', 'name': 'Market Blocks'},
    ),
    StyledFeature(
      id: 'park-1',
      geometry: PolygonGeometry([
        [
          (13.3945, 52.5252),
          (13.4018, 52.5252),
          (13.4018, 52.5294),
          (13.3945, 52.5294),
          (13.3945, 52.5252),
        ],
      ]),
      properties: {'kind': 'park', 'name': 'Pocket Park'},
    ),
    StyledFeature(
      id: 'road-1',
      geometry: LineStringGeometry([
        (13.3920, 52.5165),
        (13.3985, 52.5190),
        (13.4058, 52.5215),
        (13.4128, 52.5258),
        (13.4180, 52.5290),
      ]),
      properties: {
        'class': 'motorway',
        'kind': 'route',
        'name': 'Ring Route',
      },
    ),
    StyledFeature(
      id: 'poi-1',
      geometry: PointGeometry(13.4046, 52.5231),
      properties: {'class': 'cafe', 'kind': 'poi', 'name': 'Central Cafe'},
    ),
  ]);
}

// ---------------------------------------------------------------------------
// Beispiel-GeoJSON (RFC 7946)
// ---------------------------------------------------------------------------

const sampleGeojson = <String, Object?>{
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'id': 'water-1',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [13.3930, 52.5198],
            [13.3994, 52.5198],
            [13.3994, 52.5248],
            [13.3930, 52.5248],
            [13.3930, 52.5198],
          ],
        ],
      },
      'properties': {'class': 'ocean', 'name': 'Canal Basin'},
    },
    {
      'type': 'Feature',
      'id': 'residential-1',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [13.3998, 52.5177],
            [13.4062, 52.5177],
            [13.4062, 52.5225],
            [13.3998, 52.5225],
            [13.3998, 52.5177],
          ],
        ],
      },
      'properties': {'landuse': 'residential', 'name': 'Residential Quarter'},
    },
    {
      'type': 'Feature',
      'id': 'commercial-1',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [13.4070, 52.5195],
            [13.4138, 52.5195],
            [13.4138, 52.5246],
            [13.4070, 52.5246],
            [13.4070, 52.5195],
          ],
        ],
      },
      'properties': {'landuse': 'commercial', 'name': 'Market Blocks'},
    },
    {
      'type': 'Feature',
      'id': 'park-1',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [13.3945, 52.5252],
            [13.4018, 52.5252],
            [13.4018, 52.5294],
            [13.3945, 52.5294],
            [13.3945, 52.5252],
          ],
        ],
      },
      'properties': {'kind': 'park', 'name': 'Pocket Park'},
    },
    {
      'type': 'Feature',
      'id': 'road-1',
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [13.3920, 52.5165],
          [13.3985, 52.5190],
          [13.4058, 52.5215],
          [13.4128, 52.5258],
          [13.4180, 52.5290],
        ],
      },
      'properties': {
        'class': 'motorway',
        'kind': 'route',
        'name': 'Ring Route',
      },
    },
    {
      'type': 'Feature',
      'id': 'poi-1',
      'geometry': {
        'type': 'Point',
        'coordinates': [13.4046, 52.5231],
      },
      'properties': {'class': 'cafe', 'kind': 'poi', 'name': 'Central Cafe'},
    },
  ],
};
