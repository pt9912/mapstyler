import 'qml_symbol.dart';

/// Rule in a QGIS renderer.
class QmlRule {
  const QmlRule({
    this.name,
    this.filter,
    this.scaleMinDenominator,
    this.scaleMaxDenominator,
    this.symbols = const <QmlSymbol>[],
    this.properties = const <String, String>{},
  });

  final String? name;
  final String? filter;
  final double? scaleMinDenominator;
  final double? scaleMaxDenominator;
  final List<QmlSymbol> symbols;
  final Map<String, String> properties;
}
