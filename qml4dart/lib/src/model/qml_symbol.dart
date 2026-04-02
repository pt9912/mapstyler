import 'qml_symbol_layer.dart';
import 'qml_types.dart';

/// A QML symbol composed of one or more [QmlSymbolLayer]s.
///
/// Corresponds to a `<symbol>` element. Multiple layers are stacked to
/// create composite rendering effects (e.g. a fill with a separate outline
/// layer, or a marker with a halo ring behind it).
///
/// QML: `<symbol type="fill" name="0" alpha="1" clip_to_extent="1">`
class QmlSymbol {
  const QmlSymbol({
    required this.type,
    this.name,
    this.alpha = 1.0,
    this.clipToExtent = true,
    this.forceRhr = false,
    this.layers = const <QmlSymbolLayer>[],
  });

  /// The geometry type this symbol renders (marker, line, fill).
  final QmlSymbolType type;

  /// The symbol key used to reference this symbol from categories, ranges,
  /// or rules. Matches the `name` attribute in QML (e.g. `"0"`, `"1"`).
  final String? name;

  /// Overall symbol opacity (0.0–1.0). Applied on top of individual
  /// layer-level color alpha values.
  final double alpha;

  /// Whether to clip symbol rendering to the map extent.
  final bool clipToExtent;

  /// Whether to force right-hand rule for polygon orientation.
  final bool forceRhr;

  /// The ordered list of symbol layers that make up this symbol.
  /// Layers are rendered bottom-to-top.
  final List<QmlSymbolLayer> layers;
}
