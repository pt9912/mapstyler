## 0.1.1

- Fixed lints reported by pub.dev static analysis.

## 0.1.0

- SldStyleParser implementing `StyleParser<SldDocument>` for read/write.
- SLD → mapstyler: flattens Layer/UserStyle/FeatureTypeStyle/Rule hierarchy.
- mapstyler → SLD: wraps rules in single Layer/UserStyle/FeatureTypeStyle.
- Symbolizers: PointSymbolizer (Mark, ExternalGraphic), LineSymbolizer, PolygonSymbolizer, TextSymbolizer, RasterSymbolizer.
- OGC Filters: comparison, combination, negation, spatial, distance.
- Geometry mapping: Point, LineString, Polygon, Envelope ↔ gml4dart.
- Color utilities: `argbToHex`, `argbToOpacity`, `hexToArgb`.
