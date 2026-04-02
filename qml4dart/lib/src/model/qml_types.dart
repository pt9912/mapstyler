/// High-level renderer kinds supported by QGIS QML.
enum QmlRendererType {
  singleSymbol,
  categorizedSymbol,
  graduatedSymbol,
  ruleRenderer,
  unknown;

  /// Parse the `type` attribute of a `<renderer-v2>` element.
  static QmlRendererType fromString(String value) => switch (value) {
        'singleSymbol' => singleSymbol,
        'categorizedSymbol' => categorizedSymbol,
        'graduatedSymbol' => graduatedSymbol,
        'RuleRenderer' => ruleRenderer,
        _ => unknown,
      };

  /// Serialize back to the QML XML attribute value.
  String toQmlString() => switch (this) {
        singleSymbol => 'singleSymbol',
        categorizedSymbol => 'categorizedSymbol',
        graduatedSymbol => 'graduatedSymbol',
        ruleRenderer => 'RuleRenderer',
        unknown => 'singleSymbol',
      };
}

/// Symbol geometry type (`type` attribute on `<symbol>`).
enum QmlSymbolType {
  marker,
  line,
  fill,
  unknown;

  static QmlSymbolType fromString(String value) => switch (value) {
        'marker' => marker,
        'line' => line,
        'fill' => fill,
        _ => unknown,
      };

  String toQmlString() => switch (this) {
        marker => 'marker',
        line => 'line',
        fill => 'fill',
        unknown => 'marker',
      };
}

/// High-level symbol layer kinds (`class` attribute on `<layer>`).
enum QmlSymbolLayerType {
  simpleMarker,
  svgMarker,
  simpleLine,
  simpleFill,
  rasterFill,
  unknown;

  /// Parse the `class` attribute of a `<layer>` element.
  static QmlSymbolLayerType fromClassName(String className) =>
      switch (className) {
        'SimpleMarker' => simpleMarker,
        'SvgMarker' => svgMarker,
        'SimpleLine' => simpleLine,
        'SimpleFill' => simpleFill,
        'RasterFill' => rasterFill,
        _ => unknown,
      };

  /// Serialize back to the QML `class` attribute value.
  String toClassName() => switch (this) {
        simpleMarker => 'SimpleMarker',
        svgMarker => 'SvgMarker',
        simpleLine => 'SimpleLine',
        simpleFill => 'SimpleFill',
        rasterFill => 'RasterFill',
        unknown => 'Unknown',
      };
}
