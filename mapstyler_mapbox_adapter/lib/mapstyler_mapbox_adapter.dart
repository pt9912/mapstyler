/// Mapbox GL Style adapter for the mapstyler ecosystem.
///
/// Converts Mapbox GL Style JSON into mapstyler_style types and back.
/// The underlying Mapbox parser (`mapbox4dart`) is an implementation
/// detail and not exposed.
///
/// ```dart
/// import 'package:mapstyler_mapbox_adapter/mapstyler_mapbox_adapter.dart';
/// import 'package:mapstyler_style/mapstyler_style.dart';
///
/// final adapter = MapboxStyleAdapter();
/// final result = await adapter.readStyle(mapboxJson);
/// ```
library mapstyler_mapbox_adapter;

export 'src/mapbox_style_adapter.dart';
