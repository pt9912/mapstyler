import 'qml_symbol_layer.dart';

/// Symbol made up of one or more QML symbol layers.
class QmlSymbol {
  const QmlSymbol({
    this.name,
    this.alpha,
    this.clipToExtent,
    this.properties = const <String, String>{},
    this.layers = const <QmlSymbolLayer>[],
  });

  final String? name;
  final double? alpha;
  final bool? clipToExtent;
  final Map<String, String> properties;
  final List<QmlSymbolLayer> layers;
}
