/// High-level renderer kinds supported by QGIS QML.
enum QmlRendererType {
  singleSymbol,
  categorizedSymbol,
  graduatedSymbol,
  ruleRenderer,
  unknown,
}

/// High-level symbol layer kinds.
enum QmlSymbolLayerType {
  simpleMarker,
  svgMarker,
  simpleLine,
  simpleFill,
  rasterFill,
  unknown,
}
