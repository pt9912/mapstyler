import 'package:mapbox4dart/mapbox4dart.dart' as mb;
import 'package:mapstyler_style/mapstyler_style.dart' as ms;

import '../read/zoom_mapper.dart' as zoom;

/// Converts a mapstyler [ms.Style] to a [mb.MapboxStyle] wrapped in
/// a [ms.WriteStyleResult].
ms.WriteStyleResult<mb.MapboxStyle> convertStyle(ms.Style style) {
  final warnings = <String>[];
  final layers = <mb.MapboxLayer>[];
  var layerIndex = 0;

  for (final rule in style.rules) {
    final zoomRange = zoom.scaleDenominatorToZoom(rule.scaleDenominator);
    final filterExpr = _filterToMapbox(rule.filter, warnings);

    for (final sym in rule.symbolizers) {
      final layer = _convertSymbolizer(
        sym,
        id: '${rule.name ?? 'layer'}_$layerIndex',
        filter: filterExpr,
        minzoom: zoomRange.minzoom,
        maxzoom: zoomRange.maxzoom,
        warnings: warnings,
      );
      if (layer != null) {
        layers.add(layer);
        layerIndex++;
      }
    }
  }

  return ms.WriteStyleSuccess(
    output: mb.MapboxStyle(
      version: 8,
      name: style.name,
      layers: layers,
    ),
    warnings: warnings,
  );
}

mb.MapboxLayer? _convertSymbolizer(
  ms.Symbolizer sym, {
  required String id,
  required List<Object?>? filter,
  required double? minzoom,
  required double? maxzoom,
  required List<String> warnings,
}) {
  return switch (sym) {
    ms.FillSymbolizer() => _fillToLayer(sym, id, filter, minzoom, maxzoom),
    ms.LineSymbolizer() => _lineToLayer(sym, id, filter, minzoom, maxzoom),
    ms.MarkSymbolizer() => _markToLayer(sym, id, filter, minzoom, maxzoom, warnings),
    ms.IconSymbolizer() => _iconToLayer(sym, id, filter, minzoom, maxzoom),
    ms.TextSymbolizer() => _textToLayer(sym, id, filter, minzoom, maxzoom),
    ms.RasterSymbolizer() => _rasterToLayer(sym, id, filter, minzoom, maxzoom),
  };
}

// ---------------------------------------------------------------------------
// Fill
// ---------------------------------------------------------------------------

mb.MapboxLayer _fillToLayer(ms.FillSymbolizer s, String id,
    List<Object?>? filter, double? minzoom, double? maxzoom) {
  return mb.MapboxLayer(
    id: id,
    type: mb.MapboxLayerType.fill,
    rawType: 'fill',
    filter: filter,
    minzoom: minzoom,
    maxzoom: maxzoom,
    paint: {
      if (_str(s.color) != null) 'fill-color': _str(s.color),
      if (_dbl(s.opacity) != null) 'fill-opacity': _dbl(s.opacity),
      if (_str(s.outlineColor) != null) 'fill-outline-color': _str(s.outlineColor),
    },
  );
}

// ---------------------------------------------------------------------------
// Line
// ---------------------------------------------------------------------------

mb.MapboxLayer _lineToLayer(ms.LineSymbolizer s, String id,
    List<Object?>? filter, double? minzoom, double? maxzoom) {
  return mb.MapboxLayer(
    id: id,
    type: mb.MapboxLayerType.line,
    rawType: 'line',
    filter: filter,
    minzoom: minzoom,
    maxzoom: maxzoom,
    paint: {
      if (_str(s.color) != null) 'line-color': _str(s.color),
      if (_dbl(s.width) != null) 'line-width': _dbl(s.width),
      if (_dbl(s.opacity) != null) 'line-opacity': _dbl(s.opacity),
      if (s.dasharray != null) 'line-dasharray': s.dasharray,
    },
    layout: {
      if (s.cap != null) 'line-cap': s.cap,
      if (s.join != null) 'line-join': s.join,
    },
  );
}

// ---------------------------------------------------------------------------
// Mark → Circle
// ---------------------------------------------------------------------------

mb.MapboxLayer? _markToLayer(ms.MarkSymbolizer s, String id,
    List<Object?>? filter, double? minzoom, double? maxzoom,
    List<String> warnings) {
  if (s.wellKnownName != 'circle') {
    warnings.add('MarkSymbolizer "${s.wellKnownName}" not writable as Mapbox circle');
    return null;
  }
  return mb.MapboxLayer(
    id: id,
    type: mb.MapboxLayerType.circle,
    rawType: 'circle',
    filter: filter,
    minzoom: minzoom,
    maxzoom: maxzoom,
    paint: {
      if (_dbl(s.radius) != null) 'circle-radius': _dbl(s.radius),
      if (_str(s.color) != null) 'circle-color': _str(s.color),
      if (_dbl(s.opacity) != null) 'circle-opacity': _dbl(s.opacity),
      if (_str(s.strokeColor) != null) 'circle-stroke-color': _str(s.strokeColor),
      if (_dbl(s.strokeWidth) != null) 'circle-stroke-width': _dbl(s.strokeWidth),
    },
  );
}

// ---------------------------------------------------------------------------
// Icon → Symbol
// ---------------------------------------------------------------------------

mb.MapboxLayer _iconToLayer(ms.IconSymbolizer s, String id,
    List<Object?>? filter, double? minzoom, double? maxzoom) {
  return mb.MapboxLayer(
    id: id,
    type: mb.MapboxLayerType.symbol,
    rawType: 'symbol',
    filter: filter,
    minzoom: minzoom,
    maxzoom: maxzoom,
    layout: {
      if (_str(s.image) != null) 'icon-image': _str(s.image),
      if (_dbl(s.size) != null) 'icon-size': _dbl(s.size),
      if (_dbl(s.rotate) != null) 'icon-rotate': _dbl(s.rotate),
    },
    paint: {
      if (_dbl(s.opacity) != null) 'icon-opacity': _dbl(s.opacity),
    },
  );
}

// ---------------------------------------------------------------------------
// Text → Symbol
// ---------------------------------------------------------------------------

mb.MapboxLayer _textToLayer(ms.TextSymbolizer s, String id,
    List<Object?>? filter, double? minzoom, double? maxzoom) {
  return mb.MapboxLayer(
    id: id,
    type: mb.MapboxLayerType.symbol,
    rawType: 'symbol',
    filter: filter,
    minzoom: minzoom,
    maxzoom: maxzoom,
    layout: {
      'text-field': _exprToMapbox(s.label),
      if (_dbl(s.size) != null) 'text-size': _dbl(s.size),
      if (s.font != null) 'text-font': [s.font],
      if (_dbl(s.rotate) != null) 'text-rotate': _dbl(s.rotate),
      if (s.placement != null) 'symbol-placement': s.placement,
    },
    paint: {
      if (_str(s.color) != null) 'text-color': _str(s.color),
      if (_dbl(s.opacity) != null) 'text-opacity': _dbl(s.opacity),
      if (_str(s.haloColor) != null) 'text-halo-color': _str(s.haloColor),
      if (_dbl(s.haloWidth) != null) 'text-halo-width': _dbl(s.haloWidth),
    },
  );
}

// ---------------------------------------------------------------------------
// Raster
// ---------------------------------------------------------------------------

mb.MapboxLayer _rasterToLayer(ms.RasterSymbolizer s, String id,
    List<Object?>? filter, double? minzoom, double? maxzoom) {
  return mb.MapboxLayer(
    id: id,
    type: mb.MapboxLayerType.raster,
    rawType: 'raster',
    filter: filter,
    minzoom: minzoom,
    maxzoom: maxzoom,
    paint: {
      if (_dbl(s.opacity) != null) 'raster-opacity': _dbl(s.opacity),
      if (_dbl(s.hueRotate) != null) 'raster-hue-rotate': _dbl(s.hueRotate),
      if (_dbl(s.brightnessMin) != null) 'raster-brightness-min': _dbl(s.brightnessMin),
      if (_dbl(s.brightnessMax) != null) 'raster-brightness-max': _dbl(s.brightnessMax),
      if (_dbl(s.saturation) != null) 'raster-saturation': _dbl(s.saturation),
      if (_dbl(s.contrast) != null) 'raster-contrast': _dbl(s.contrast),
    },
  );
}

// ---------------------------------------------------------------------------
// Expression helpers
// ---------------------------------------------------------------------------

Object? _str(ms.Expression<String>? e) => _exprToMapbox(e);
Object? _dbl(ms.Expression<double>? e) => _exprToMapbox(e);

Object? _exprToMapbox<T>(ms.Expression<T>? e) => switch (e) {
      null => null,
      ms.LiteralExpression(:final value) => value,
      ms.FunctionExpression(:final function) => _funcToMapbox(function),
    };

Object _funcToMapbox(ms.GeoStylerFunction func) => switch (func) {
      ms.PropertyGet(:final propertyName) => ['get', propertyName],
      ms.ArgsFunction(:final name, :final args) =>
        [_mapFuncName(name), ...args.map(_exprToMapbox)],
      ms.InterpolateFunction(:final mode, :final input, :final stops) => [
          'interpolate',
          mode,
          _exprToMapbox(input),
          for (final s in stops) ...[_exprToMapbox(s.stop), _exprToMapbox(s.value)],
        ],
      ms.StepFunction(:final input, :final defaultValue, :final stops) => [
          'step',
          _exprToMapbox(input),
          _exprToMapbox(defaultValue),
          for (final s in stops) ...[_exprToMapbox(s.boundary), _exprToMapbox(s.value)],
        ],
      ms.CaseFunction(:final cases, :final fallback) => [
          'case',
          for (final c in cases) ...[_exprToMapbox(c.condition), _exprToMapbox(c.value)],
          _exprToMapbox(fallback),
        ],
    };

String _mapFuncName(String name) => switch (name) {
      'strConcat' => 'concat',
      'toString' => 'to-string',
      'zoom' => 'zoom',
      _ => name,
    };

// ---------------------------------------------------------------------------
// Filter → Mapbox
// ---------------------------------------------------------------------------

List<Object?>? _filterToMapbox(ms.Filter? filter, List<String> warnings) {
  if (filter == null) return null;
  return switch (filter) {
    ms.ComparisonFilter(:final operator, :final property, :final value) => [
        _compOp(operator),
        _exprToMapbox(property),
        _exprToMapbox(value),
      ],
    ms.CombinationFilter(:final operator, :final filters) => [
        operator == ms.CombinationOperator.and ? 'all' : 'any',
        ...filters.map((f) => _filterToMapbox(f, warnings)),
      ],
    ms.NegationFilter(:final filter) => [
        '!',
        _filterToMapbox(filter, warnings),
      ],
    ms.SpatialFilter() => () {
        warnings.add('SpatialFilter not supported in Mapbox output');
        return null;
      }(),
    ms.DistanceFilter() => () {
        warnings.add('DistanceFilter not supported in Mapbox output');
        return null;
      }(),
  };
}

String _compOp(ms.ComparisonOperator op) => switch (op) {
      ms.ComparisonOperator.eq => '==',
      ms.ComparisonOperator.neq => '!=',
      ms.ComparisonOperator.lt => '<',
      ms.ComparisonOperator.gt => '>',
      ms.ComparisonOperator.lte => '<=',
      ms.ComparisonOperator.gte => '>=',
    };
