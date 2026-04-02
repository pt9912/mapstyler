/// Source types supported by Mapbox GL Style v8.
enum MapboxSourceType {
  vector,
  raster,
  rasterDem,
  geojson,
  image,
  video,
  unknown;

  static MapboxSourceType fromString(String value) => switch (value) {
        'vector' => vector,
        'raster' => raster,
        'raster-dem' => rasterDem,
        'geojson' => geojson,
        'image' => image,
        'video' => video,
        _ => unknown,
      };

  String toJsonString() => switch (this) {
        vector => 'vector',
        raster => 'raster',
        rasterDem => 'raster-dem',
        geojson => 'geojson',
        image => 'image',
        video => 'video',
        unknown => 'unknown',
      };
}

/// Layer types supported by Mapbox GL Style v8.
enum MapboxLayerType {
  background,
  fill,
  line,
  circle,
  symbol,
  raster,
  fillExtrusion,
  hillshade,
  heatmap,
  sky,
  unknown;

  static MapboxLayerType fromString(String value) => switch (value) {
        'background' => background,
        'fill' => fill,
        'line' => line,
        'circle' => circle,
        'symbol' => symbol,
        'raster' => raster,
        'fill-extrusion' => fillExtrusion,
        'hillshade' => hillshade,
        'heatmap' => heatmap,
        'sky' => sky,
        _ => unknown,
      };

  String toJsonString() => switch (this) {
        background => 'background',
        fill => 'fill',
        line => 'line',
        circle => 'circle',
        symbol => 'symbol',
        raster => 'raster',
        fillExtrusion => 'fill-extrusion',
        hillshade => 'hillshade',
        heatmap => 'heatmap',
        sky => 'sky',
        unknown => 'unknown',
      };
}
