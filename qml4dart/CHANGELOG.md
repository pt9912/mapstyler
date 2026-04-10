## 0.1.0

- Objektmodell: QmlDocument, QmlRenderer, QmlSymbol, QmlSymbolLayer, QmlRule, QmlCategory, QmlRange
- Reader: singleSymbol, categorizedSymbol, graduatedSymbol, RuleRenderer (inkl. verschachtelte Regeln)
- Writer: alle Renderer-Typen, erzeugt QGIS-importierbares XML im neuen Option-Format
- Symbol-Layer: SimpleMarker, SimpleLine, SimpleFill, SvgMarker, RasterFill
- Unterstützung beider QML-Property-Formate (alt: `<prop k v>`, neu: `<Option type="Map">`)
- Scale Visibility auf Dokument- und Regel-Ebene
- Codec-API: parseString, parseFile, encodeString, encodeFile mit Result-Typen
- 31 Tests, 11 QML-Fixtures, 96.6 % Line Coverage
