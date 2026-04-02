/// Pure Dart codec and object model for Mapbox GL Style JSON (v8).
///
/// Provides typed access to Mapbox GL Style documents including layers,
/// sources, expressions, and filters. Reads and writes Mapbox GL JSON
/// using `dart:convert`.
///
/// ```dart
/// import 'package:mapbox4dart/mapbox4dart.dart';
///
/// const codec = Mapbox4DartCodec();
/// final result = codec.parseString(mapboxJson);
/// if (result case ReadMapboxSuccess(:final style)) {
///   for (final layer in style.layers) {
///     print('${layer.id}: ${layer.type}');
///   }
/// }
/// ```
library mapbox4dart;
