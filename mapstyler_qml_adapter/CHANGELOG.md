## 0.2.0

- QmlStyleParser implementing `StyleParser<QmlDocument>` for read/write.
- QML → mapstyler: singleSymbol, categorizedSymbol, graduatedSymbol, RuleRenderer (incl. nested rules).
- mapstyler → QML: automatic renderer type selection (singleSymbol vs RuleRenderer).
- Symbol layers: SimpleFill, SimpleLine, SimpleMarker, SvgMarker, RasterFill.
- Filter conversion: comparison and combination operators in both directions.
- Scale visibility on document and rule level.
- Color utilities: `qgisColorToHex`, `qgisColorToOpacity`, `hexToQgisColor`.
- Multi-layer symbols producing multiple symbolizers per rule.

## 0.1.0

- Initial package skeleton.
