/// A range entry in a `graduatedSymbol` renderer.
class QmlRange {
  const QmlRange({
    required this.lower,
    required this.upper,
    required this.symbolKey,
    this.label,
    this.render = true,
  });

  final double lower;
  final double upper;

  /// Key referencing a symbol in the renderer's symbol map.
  final String symbolKey;

  /// Display label.
  final String? label;

  /// Whether this range is rendered.
  final bool render;
}
