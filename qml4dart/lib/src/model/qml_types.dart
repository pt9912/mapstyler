/// High-level renderer kinds supported by QGIS QML.
///
/// Corresponds to the `type` attribute on the `<renderer-v2>` element.
enum QmlRendererType {
  /// One symbol applied to all features.
  singleSymbol,

  /// Features classified by a single field value into categories.
  categorizedSymbol,

  /// Features classified into numeric value ranges.
  graduatedSymbol,

  /// Features selected by user-defined filter expressions, optionally nested.
  ruleRenderer,

  /// Unrecognised renderer type. Preserved for forward compatibility.
  unknown;

  /// Parses the `type` attribute of a `<renderer-v2>` element.
  static QmlRendererType fromString(String value) => switch (value) {
        'singleSymbol' => singleSymbol,
        'categorizedSymbol' => categorizedSymbol,
        'graduatedSymbol' => graduatedSymbol,
        'RuleRenderer' => ruleRenderer,
        _ => unknown,
      };

  /// Serializes back to the QML XML attribute value.
  String toQmlString() => switch (this) {
        singleSymbol => 'singleSymbol',
        categorizedSymbol => 'categorizedSymbol',
        graduatedSymbol => 'graduatedSymbol',
        ruleRenderer => 'RuleRenderer',
        unknown => 'singleSymbol',
      };
}

/// Symbol geometry type (`type` attribute on `<symbol>`).
///
/// Determines the kind of geometry the symbol can render.
enum QmlSymbolType {
  /// Point symbols (SimpleMarker, SvgMarker, etc.).
  marker,

  /// Line/stroke symbols (SimpleLine, etc.).
  line,

  /// Polygon fill symbols (SimpleFill, RasterFill, etc.).
  fill,

  /// Unrecognised symbol type.
  unknown;

  /// Parses the `type` attribute of a `<symbol>` element.
  static QmlSymbolType fromString(String value) => switch (value) {
        'marker' => marker,
        'line' => line,
        'fill' => fill,
        _ => unknown,
      };

  /// Serializes back to the QML XML attribute value.
  String toQmlString() => switch (this) {
        marker => 'marker',
        line => 'line',
        fill => 'fill',
        unknown => 'marker',
      };
}

/// Symbol layer classes (`class` attribute on `<layer>`).
///
/// Each value corresponds to a QGIS C++ symbol layer class that defines
/// which properties are available (e.g. `color`, `outline_width`).
enum QmlSymbolLayerType {
  /// Circle, square, triangle, etc. — well-known point shapes.
  simpleMarker,

  /// Point marker rendered from an SVG image file.
  svgMarker,

  /// Stroke rendering with color, width, dash pattern.
  simpleLine,

  /// Polygon fill with optional outline.
  simpleFill,

  /// Polygon fill using a raster/image pattern.
  rasterFill,

  /// Unrecognised layer class. Preserved for forward compatibility.
  unknown;

  /// Parses the `class` attribute of a `<layer>` element.
  static QmlSymbolLayerType fromClassName(String className) =>
      switch (className) {
        'SimpleMarker' => simpleMarker,
        'SvgMarker' => svgMarker,
        'SimpleLine' => simpleLine,
        'SimpleFill' => simpleFill,
        'RasterFill' => rasterFill,
        _ => unknown,
      };

  /// Serializes back to the QML `class` attribute value.
  String toClassName() => switch (this) {
        simpleMarker => 'SimpleMarker',
        svgMarker => 'SvgMarker',
        simpleLine => 'SimpleLine',
        simpleFill => 'SimpleFill',
        rasterFill => 'RasterFill',
        unknown => 'Unknown',
      };
}
