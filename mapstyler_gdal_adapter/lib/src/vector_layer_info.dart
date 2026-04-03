/// Metadata about a single layer in a vector dataset.
///
/// Returned by [inspectVectorFile] / [inspectVectorFileSync] without
/// loading any feature data.
class VectorLayerInfo {
  const VectorLayerInfo({
    required this.name,
    required this.featureCount,
    this.fields = const [],
    this.extent,
  });

  /// Layer name as reported by OGR.
  final String name;

  /// Number of features (-1 if unknown without scanning).
  final int featureCount;

  /// Field definitions: name and OGR type as string.
  final List<({String name, String type})> fields;

  /// Spatial extent, or `null` if unavailable.
  final ({double minX, double minY, double maxX, double maxY})? extent;
}
