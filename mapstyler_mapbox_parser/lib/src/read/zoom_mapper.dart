import 'dart:math' as math;

import 'package:mapstyler_style/mapstyler_style.dart' as ms;

/// Web Mercator constant: scaleDenominator at zoom 0.
const _scaleAtZoom0 = 559082264.028;
const _ln2 = 0.6931471805599453;

/// Converts Mapbox `minzoom`/`maxzoom` to a mapstyler [ms.ScaleDenominator].
///
/// - `minzoom` (furthest out) → `ScaleDenominator.max` (largest value)
/// - `maxzoom` (closest in) → `ScaleDenominator.min` (smallest value)
ms.ScaleDenominator? zoomToScaleDenominator({
  double? minzoom,
  double? maxzoom,
}) {
  if (minzoom == null && maxzoom == null) return null;
  return ms.ScaleDenominator(
    min: maxzoom != null ? _zoomToScale(maxzoom) : null,
    max: minzoom != null ? _zoomToScale(minzoom) : null,
  );
}

/// Converts a mapstyler [ms.ScaleDenominator] back to Mapbox zoom levels.
({double? minzoom, double? maxzoom}) scaleDenominatorToZoom(
    ms.ScaleDenominator? sd) {
  if (sd == null) return (minzoom: null, maxzoom: null);
  return (
    minzoom: sd.max != null ? _scaleToZoom(sd.max!) : null,
    maxzoom: sd.min != null ? _scaleToZoom(sd.min!) : null,
  );
}

double _zoomToScale(double zoom) => _scaleAtZoom0 / math.pow(2, zoom);

double _scaleToZoom(double scale) {
  if (scale <= 0) return 0;
  return math.log(_scaleAtZoom0 / scale) / _ln2;
}
