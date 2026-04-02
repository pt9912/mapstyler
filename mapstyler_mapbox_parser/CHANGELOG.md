## 0.1.0

- MapboxStyleAdapter with readStyle(String) and writeStyle(Style).
- Read: fill, line, circle, symbol (text + icon splitting), raster layers.
- Write: all supported symbolizer types to Mapbox layers.
- Expression MVP: get, literal, interpolate, step, case, match, concat, zoom.
- Filter MVP: comparison, combination, negation, has/!has, in/!in (legacy v1 + expression v2).
- Zoom ↔ ScaleDenominator conversion via Web Mercator formula.
- Unsupported layers (background, fill-extrusion, etc.) produce warnings.
