/// A range entry in a `graduatedSymbol` renderer.
///
/// Maps a numeric interval ([lower] .. [upper]) to a symbol.
///
/// QML: `<range lower="0" upper="1000" symbol="0" label="0–1000"
///        render="true"/>`
class QmlRange {
  const QmlRange({
    required this.lower,
    required this.upper,
    required this.symbolKey,
    this.label,
    this.render = true,
  });

  /// Inclusive lower bound of the interval.
  final double lower;

  /// Exclusive upper bound of the interval.
  final double upper;

  /// Key referencing a symbol in the renderer's [QmlRenderer.symbols] map.
  final String symbolKey;

  /// Human-readable display label shown in the QGIS legend.
  final String? label;

  /// Whether this range is rendered. When `false`, the entry is preserved
  /// in the QML but not drawn.
  final bool render;
}
