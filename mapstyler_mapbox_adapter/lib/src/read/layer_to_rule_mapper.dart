import 'package:mapbox4dart/mapbox4dart.dart' as mb;
import 'package:mapstyler_style/mapstyler_style.dart' as ms;

import 'expression_mapper.dart' as expr;
import 'filter_mapper.dart' as filter;
import 'zoom_mapper.dart' as zoom;

/// Converts a [mb.MapboxStyle] to a [ms.ReadStyleResult].
ms.ReadStyleResult convertMapboxStyle(mb.MapboxStyle mbStyle) {
  final warnings = <String>[];
  final rules = <ms.Rule>[];

  for (final layer in mbStyle.layers) {
    final symbolizers = _convertLayer(layer, warnings);
    if (symbolizers.isEmpty) continue;

    rules.add(ms.Rule(
      name: layer.id,
      filter: filter.convertFilter(layer.filter, warnings),
      scaleDenominator: zoom.zoomToScaleDenominator(
        minzoom: layer.minzoom,
        maxzoom: layer.maxzoom,
      ),
      symbolizers: symbolizers,
    ));
  }

  return ms.ReadStyleSuccess(
    output: ms.Style(name: mbStyle.name, rules: rules),
    warnings: warnings,
  );
}

List<ms.Symbolizer> _convertLayer(mb.MapboxLayer layer, List<String> w) {
  return switch (layer.type) {
    mb.MapboxLayerType.fill => [_convertFill(layer, w)],
    mb.MapboxLayerType.line => [_convertLine(layer, w)],
    mb.MapboxLayerType.circle => [_convertCircle(layer, w)],
    mb.MapboxLayerType.symbol => _convertSymbol(layer, w),
    mb.MapboxLayerType.raster => [_convertRaster(layer, w)],
    mb.MapboxLayerType.background => () {
        w.add('Layer "${layer.id}": background not supported');
        return <ms.Symbolizer>[];
      }(),
    _ => () {
        w.add('Layer "${layer.id}": unsupported type ${layer.rawType}');
        return <ms.Symbolizer>[];
      }(),
  };
}

// ---------------------------------------------------------------------------
// Fill
// ---------------------------------------------------------------------------

ms.FillSymbolizer _convertFill(mb.MapboxLayer l, List<String> w) {
  final p = l.paint;
  return ms.FillSymbolizer(
    color: _strExpr(p['fill-color'], w),
    opacity: _dblExpr(p['fill-opacity'], w),
    fillOpacity: _dblExpr(p['fill-opacity'], w),
    outlineColor: _strExpr(p['fill-outline-color'], w),
  );
}

// ---------------------------------------------------------------------------
// Line
// ---------------------------------------------------------------------------

ms.LineSymbolizer _convertLine(mb.MapboxLayer l, List<String> w) {
  final p = l.paint;
  final lo = l.layout;
  return ms.LineSymbolizer(
    color: _strExpr(p['line-color'], w),
    width: _dblExpr(p['line-width'], w),
    opacity: _dblExpr(p['line-opacity'], w),
    dasharray: _dasharray(p['line-dasharray']),
    cap: lo['line-cap'] as String?,
    join: lo['line-join'] as String?,
  );
}

// ---------------------------------------------------------------------------
// Circle → MarkSymbolizer
// ---------------------------------------------------------------------------

ms.MarkSymbolizer _convertCircle(mb.MapboxLayer l, List<String> w) {
  final p = l.paint;
  return ms.MarkSymbolizer(
    wellKnownName: 'circle',
    radius: _dblExpr(p['circle-radius'], w),
    color: _strExpr(p['circle-color'], w),
    opacity: _dblExpr(p['circle-opacity'], w),
    strokeColor: _strExpr(p['circle-stroke-color'], w),
    strokeWidth: _dblExpr(p['circle-stroke-width'], w),
  );
}

// ---------------------------------------------------------------------------
// Symbol → TextSymbolizer + IconSymbolizer
// ---------------------------------------------------------------------------

List<ms.Symbolizer> _convertSymbol(mb.MapboxLayer l, List<String> w) {
  final p = l.paint;
  final lo = l.layout;
  final result = <ms.Symbolizer>[];

  // Text
  if (lo.containsKey('text-field')) {
    result.add(ms.TextSymbolizer(
      label: expr.convertValue<String>(
              lo['text-field'], (v) => '$v', w) ??
          const ms.LiteralExpression(''),
      color: _strExpr(p['text-color'], w),
      size: _dblExpr(lo['text-size'], w),
      font: lo['text-font'] is List
          ? (lo['text-font'] as List).firstOrNull as String?
          : lo['text-font'] as String?,
      opacity: _dblExpr(p['text-opacity'], w),
      rotate: _dblExpr(lo['text-rotate'], w),
      haloColor: _strExpr(p['text-halo-color'], w),
      haloWidth: _dblExpr(p['text-halo-width'], w),
      placement: lo['symbol-placement'] as String?,
    ));
  }

  // Icon
  if (lo.containsKey('icon-image')) {
    result.add(ms.IconSymbolizer(
      image: expr.convertValue<String>(
              lo['icon-image'], (v) => '$v', w) ??
          const ms.LiteralExpression(''),
      size: _dblExpr(lo['icon-size'], w),
      opacity: _dblExpr(p['icon-opacity'], w),
      rotate: _dblExpr(lo['icon-rotate'], w),
    ));
  }

  return result;
}

// ---------------------------------------------------------------------------
// Raster
// ---------------------------------------------------------------------------

ms.RasterSymbolizer _convertRaster(mb.MapboxLayer l, List<String> w) {
  final p = l.paint;
  return ms.RasterSymbolizer(
    opacity: _dblExpr(p['raster-opacity'], w),
    hueRotate: _dblExpr(p['raster-hue-rotate'], w),
    brightnessMin: _dblExpr(p['raster-brightness-min'], w),
    brightnessMax: _dblExpr(p['raster-brightness-max'], w),
    saturation: _dblExpr(p['raster-saturation'], w),
    contrast: _dblExpr(p['raster-contrast'], w),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ms.Expression<String>? _strExpr(Object? value, List<String> w) =>
    expr.convertValue<String>(value, (v) => '$v', w);

ms.Expression<double>? _dblExpr(Object? value, List<String> w) =>
    expr.convertValue<double>(value, (v) => (v as num).toDouble(), w);

List<double>? _dasharray(Object? value) {
  if (value is! List) return null;
  return value.whereType<num>().map((n) => n.toDouble()).toList();
}
