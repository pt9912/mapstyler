/// Pure Dart codec and object model for Mapbox GL Style JSON (v8).
///
/// Provides typed access to Mapbox GL Style documents including layers,
/// sources, and metadata. Reads and writes Mapbox GL JSON with full
/// roundtrip preservation of unknown fields.
///
/// ```dart
/// import 'package:mapbox4dart/mapbox4dart.dart';
///
/// const codec = MapboxStyleCodec();
/// final result = codec.readString(mapboxJson);
/// if (result case ReadMapboxSuccess(:final output)) {
///   for (final layer in output.layers) {
///     print('${layer.id}: ${layer.type}');
///   }
/// }
/// ```
library mapbox4dart;

export 'src/codec/mapbox_style_codec.dart';
export 'src/color_util.dart' show normalizeColor;
export 'src/model/mapbox_layer.dart';
export 'src/model/mapbox_source.dart';
export 'src/model/mapbox_style.dart';
export 'src/model/mapbox_types.dart';
export 'src/read/read_result.dart';
export 'src/write/write_result.dart';
