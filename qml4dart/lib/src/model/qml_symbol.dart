import 'qml_symbol_layer.dart';
import 'qml_types.dart';

/// Symbol made up of one or more QML symbol layers.
class QmlSymbol {
  const QmlSymbol({
    required this.type,
    this.name,
    this.alpha = 1.0,
    this.clipToExtent = true,
    this.forceRhr = false,
    this.layers = const <QmlSymbolLayer>[],
  });

  final QmlSymbolType type;
  final String? name;
  final double alpha;
  final bool clipToExtent;
  final bool forceRhr;
  final List<QmlSymbolLayer> layers;
}
