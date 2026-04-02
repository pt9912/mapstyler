/// A category entry in a `categorizedSymbol` renderer.
class QmlCategory {
  const QmlCategory({
    required this.value,
    required this.symbolKey,
    this.label,
    this.render = true,
  });

  /// The field value to match.
  final String value;

  /// Key referencing a symbol in the renderer's symbol map.
  final String symbolKey;

  /// Display label.
  final String? label;

  /// Whether this category is rendered.
  final bool render;
}
