## 0.1.0

- MapboxStyleCodec with readString, readJsonObject, writeString, writeJsonObject.
- Typed object model: MapboxStyle, MapboxLayer, MapboxSource.
- Enums: MapboxLayerType (10 types + unknown), MapboxSourceType (6 types + unknown).
- Unknown field preservation via extra maps on root and layer level.
- Forward-compatible unknown type handling with rawType.
- Color normalization: hex, rgb, rgba, hsl, hsla, 140+ CSS named colors.
- Version 8 validation on read.
