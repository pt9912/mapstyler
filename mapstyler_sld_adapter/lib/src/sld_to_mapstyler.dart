/// Converts flutter_map_sld types to mapstyler_style types (Read direction).
///
/// SLD XML → flutter_map_sld (parser) → **this adapter** → mapstyler_style.
import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:gml4dart/gml4dart.dart' as gml;
import 'package:mapstyler_style/mapstyler_style.dart' as ms;

import 'color_util.dart';

// ---------------------------------------------------------------------------
// Document → Style
// ---------------------------------------------------------------------------

/// Converts an [sld.SldDocument] to a [ms.ReadStyleResult].
///
/// Flattens the SLD hierarchy (Layer → UserStyle → FeatureTypeStyle → Rule)
/// into a flat list of mapstyler rules. The style name is taken from the
/// first layer or style name found.
ms.ReadStyleResult convertDocument(sld.SldDocument doc) {
  final warnings = <String>[];
  final rules = <ms.Rule>[];

  String? styleName;
  for (final layer in doc.layers) {
    styleName ??= layer.name;
    for (final style in layer.styles) {
      styleName ??= style.name;
      for (final fts in style.featureTypeStyles) {
        for (final rule in fts.rules) {
          rules.add(_convertRule(rule, warnings));
        }
      }
    }
  }

  return ms.ReadStyleSuccess(
    output: ms.Style(name: styleName, rules: rules),
    warnings: warnings,
  );
}

// ---------------------------------------------------------------------------
// Rule
// ---------------------------------------------------------------------------

ms.Rule _convertRule(sld.Rule rule, List<String> warnings) {
  final symbolizers = <ms.Symbolizer>[];

  final ps = rule.pointSymbolizer;
  if (ps != null) {
    final sym = _convertPointSymbolizer(ps, warnings);
    if (sym != null) symbolizers.add(sym);
  }

  final ls = rule.lineSymbolizer;
  if (ls != null) {
    symbolizers.add(_convertLineSymbolizer(ls));
  }

  final pgs = rule.polygonSymbolizer;
  if (pgs != null) {
    symbolizers.add(_convertPolygonSymbolizer(pgs, warnings));
  }

  final ts = rule.textSymbolizer;
  if (ts != null) {
    final sym = _convertTextSymbolizer(ts, warnings);
    if (sym != null) symbolizers.add(sym);
  }

  final rs = rule.rasterSymbolizer;
  if (rs != null) {
    symbolizers.add(_convertRasterSymbolizer(rs, warnings));
  }

  ms.ScaleDenominator? scale;
  if (rule.minScaleDenominator != null || rule.maxScaleDenominator != null) {
    scale = ms.ScaleDenominator(
      min: rule.minScaleDenominator,
      max: rule.maxScaleDenominator,
    );
  }

  return ms.Rule(
    name: rule.name,
    filter: rule.filter != null ? _convertFilter(rule.filter!, warnings) : null,
    symbolizers: symbolizers,
    scaleDenominator: scale,
  );
}

// ---------------------------------------------------------------------------
// Symbolizers
// ---------------------------------------------------------------------------

ms.Symbolizer? _convertPointSymbolizer(
    sld.PointSymbolizer ps, List<String> warnings) {
  final graphic = ps.graphic;
  if (graphic == null) return null;

  if (graphic.externalGraphic != null) {
    return _convertExternalGraphic(graphic);
  }

  return _convertMarkSymbolizer(graphic, warnings);
}

ms.MarkSymbolizer _convertMarkSymbolizer(
    sld.Graphic graphic, List<String> warnings) {
  final mark = graphic.mark;
  final wellKnownName = mark?.wellKnownName ?? 'circle';

  // SLD size = diameter, GeoStyler radius = half.
  ms.Expression<double>? radius;
  if (graphic.size != null) {
    radius = ms.LiteralExpression(graphic.size! / 2);
  }

  ms.Expression<String>? color;
  ms.Expression<double>? fillOpacity;
  if (mark?.fill != null) {
    final fill = mark!.fill!;
    if (fill.colorArgb != null) {
      color = ms.LiteralExpression(argbToHex(fill.colorArgb!));
      final alphaOpacity = argbToOpacity(fill.colorArgb!);
      if (alphaOpacity != null) {
        fillOpacity = ms.LiteralExpression(alphaOpacity);
      }
    }
    if (fill.opacity != null) {
      fillOpacity = ms.LiteralExpression(fill.opacity!);
    }
  }

  ms.Expression<String>? strokeColor;
  ms.Expression<double>? strokeWidth;
  if (mark?.stroke != null) {
    final stroke = mark!.stroke!;
    if (stroke.colorArgb != null) {
      strokeColor = ms.LiteralExpression(argbToHex(stroke.colorArgb!));
    }
    if (stroke.width != null) {
      strokeWidth = ms.LiteralExpression(stroke.width!);
    }
    if (stroke.opacity != null) {
      // BUG-5 fix: emit warning — MarkSymbolizer has no strokeOpacity field.
      warnings.add(
          'Mark stroke opacity (${stroke.opacity}) dropped — '
          'MarkSymbolizer has no strokeOpacity field');
    }
  }

  return ms.MarkSymbolizer(
    wellKnownName: wellKnownName,
    radius: radius,
    color: color,
    opacity: graphic.opacity != null
        ? ms.LiteralExpression(graphic.opacity!)
        : fillOpacity,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    rotate: graphic.rotation != null
        ? ms.LiteralExpression(graphic.rotation!)
        : null,
  );
}

ms.IconSymbolizer _convertExternalGraphic(sld.Graphic graphic) {
  final eg = graphic.externalGraphic!;
  return ms.IconSymbolizer(
    image: ms.LiteralExpression(eg.onlineResource),
    format: eg.format,
    size: graphic.size != null ? ms.LiteralExpression(graphic.size!) : null,
    opacity: graphic.opacity != null
        ? ms.LiteralExpression(graphic.opacity!)
        : null,
    rotate: graphic.rotation != null
        ? ms.LiteralExpression(graphic.rotation!)
        : null,
  );
}

ms.LineSymbolizer _convertLineSymbolizer(sld.LineSymbolizer ls) {
  final stroke = ls.stroke;
  return ms.LineSymbolizer(
    color: stroke?.colorArgb != null
        ? ms.LiteralExpression(argbToHex(stroke!.colorArgb!))
        : null,
    width:
        stroke?.width != null ? ms.LiteralExpression(stroke!.width!) : null,
    opacity: stroke?.opacity != null
        ? ms.LiteralExpression(stroke!.opacity!)
        : null,
    dasharray: stroke?.dashArray,
    cap: stroke?.lineCap,
    join: _convertLineJoin(stroke?.lineJoin),
  );
}

ms.FillSymbolizer _convertPolygonSymbolizer(
    sld.PolygonSymbolizer ps, List<String> warnings) {
  final fill = ps.fill;
  final stroke = ps.stroke;

  ms.Expression<String>? color;
  ms.Expression<double>? fillOpacity;
  if (fill != null) {
    if (fill.colorArgb != null) {
      color = ms.LiteralExpression(argbToHex(fill.colorArgb!));
    }
    if (fill.opacity != null) {
      fillOpacity = ms.LiteralExpression(fill.opacity!);
    }
  }

  // MISS-1 fix: warn about outline properties not mappable in FillSymbolizer.
  if (stroke != null) {
    if (stroke.dashArray != null) {
      warnings.add('Polygon outline dashArray dropped — '
          'FillSymbolizer has no outlineDasharray field');
    }
    if (stroke.opacity != null) {
      warnings.add('Polygon outline opacity dropped — '
          'FillSymbolizer has no outlineOpacity field');
    }
    if (stroke.lineCap != null) {
      warnings.add('Polygon outline lineCap dropped — '
          'FillSymbolizer has no outlineCap field');
    }
    if (stroke.lineJoin != null) {
      warnings.add('Polygon outline lineJoin dropped — '
          'FillSymbolizer has no outlineJoin field');
    }
  }

  return ms.FillSymbolizer(
    color: color,
    fillOpacity: fillOpacity,
    outlineColor: stroke?.colorArgb != null
        ? ms.LiteralExpression(argbToHex(stroke!.colorArgb!))
        : null,
    outlineWidth: stroke?.width != null
        ? ms.LiteralExpression(stroke!.width!)
        : null,
  );
}

ms.TextSymbolizer? _convertTextSymbolizer(
    sld.TextSymbolizer ts, List<String> warnings) {
  ms.Expression<String>? label;
  if (ts.label != null) {
    label = _convertLabelExpression(ts.label!);
  }
  if (label == null) {
    warnings.add('TextSymbolizer has no label expression');
    return null;
  }

  ms.Expression<String>? color;
  if (ts.fill?.colorArgb != null) {
    color = ms.LiteralExpression(argbToHex(ts.fill!.colorArgb!));
  }

  ms.Expression<String>? haloColor;
  ms.Expression<double>? haloWidth;
  if (ts.halo != null) {
    if (ts.halo!.fill?.colorArgb != null) {
      haloColor = ms.LiteralExpression(argbToHex(ts.halo!.fill!.colorArgb!));
    }
    if (ts.halo!.radius != null) {
      haloWidth = ms.LiteralExpression(ts.halo!.radius!);
    }
  }

  ms.Expression<double>? size;
  if (ts.font?.size != null) {
    size = ms.LiteralExpression(ts.font!.size!);
  }

  // MISS-2 fix: warn about fields not present in TextSymbolizer.
  if (ts.font?.style != null) {
    warnings.add('Font style "${ts.font!.style}" dropped — '
        'TextSymbolizer has no fontStyle field');
  }
  if (ts.font?.weight != null) {
    warnings.add('Font weight "${ts.font!.weight}" dropped — '
        'TextSymbolizer has no fontWeight field');
  }

  ms.Expression<double>? rotate;
  String? placement;
  if (ts.labelPlacement != null) {
    final lp = ts.labelPlacement!;
    if (lp.pointPlacement != null) {
      placement = 'point';
      if (lp.pointPlacement!.rotation != null) {
        rotate = ms.LiteralExpression(lp.pointPlacement!.rotation!);
      }
      if (lp.pointPlacement!.anchorPointX != null ||
          lp.pointPlacement!.anchorPointY != null) {
        warnings.add('PointPlacement anchor dropped — '
            'TextSymbolizer has no anchor field');
      }
      if (lp.pointPlacement!.displacementX != null ||
          lp.pointPlacement!.displacementY != null) {
        warnings.add('PointPlacement displacement dropped — '
            'TextSymbolizer has no offset field');
      }
    } else if (lp.linePlacement != null) {
      placement = 'line';
      if (lp.linePlacement!.perpendicularOffset != null) {
        warnings.add('LinePlacement perpendicularOffset dropped — '
            'TextSymbolizer has no perpendicularOffset field');
      }
    }
  }

  return ms.TextSymbolizer(
    label: label,
    color: color,
    size: size,
    font: ts.font?.family,
    haloColor: haloColor,
    haloWidth: haloWidth,
    rotate: rotate,
    placement: placement,
  );
}

ms.RasterSymbolizer _convertRasterSymbolizer(
    sld.RasterSymbolizer rs, List<String> warnings) {
  if (rs.shadedRelief != null) {
    warnings.add('ShadedRelief is not supported in GeoStyler');
  }
  if (rs.vendorOptions.isNotEmpty) {
    warnings.add(
        'VendorOptions are not supported in GeoStyler (${rs.vendorOptions.length} ignored)');
  }

  return ms.RasterSymbolizer(
    opacity: rs.opacity != null ? ms.LiteralExpression(rs.opacity!) : null,
    colorMap: rs.colorMap != null ? _convertColorMap(rs.colorMap!) : null,
    channelSelection: rs.channelSelection != null
        ? _convertChannelSelection(rs.channelSelection!)
        : null,
    contrastEnhancement: rs.contrastEnhancement != null
        ? _convertContrastEnhancement(rs.contrastEnhancement!)
        : null,
  );
}

// ---------------------------------------------------------------------------
// Raster support types
// ---------------------------------------------------------------------------

ms.ColorMap _convertColorMap(sld.ColorMap cm) {
  final type = switch (cm.type) {
    sld.ColorMapType.ramp => 'ramp',
    sld.ColorMapType.intervals => 'intervals',
    sld.ColorMapType.exactValues => 'values',
  };
  return ms.ColorMap(
    type: type,
    colorMapEntries: cm.entries.map(_convertColorMapEntry).toList(),
  );
}

ms.ColorMapEntry _convertColorMapEntry(sld.ColorMapEntry entry) =>
    ms.ColorMapEntry(
      color: argbToHex(entry.colorArgb),
      quantity: entry.quantity,
      opacity: entry.opacity,
      label: entry.label,
    );

ms.ChannelSelection _convertChannelSelection(sld.ChannelSelection cs) =>
    ms.ChannelSelection(
      redChannel: cs.redChannel != null ? _convertChannel(cs.redChannel!) : null,
      greenChannel:
          cs.greenChannel != null ? _convertChannel(cs.greenChannel!) : null,
      blueChannel:
          cs.blueChannel != null ? _convertChannel(cs.blueChannel!) : null,
      grayChannel:
          cs.grayChannel != null ? _convertChannel(cs.grayChannel!) : null,
    );

ms.Channel _convertChannel(sld.SelectedChannel ch) => ms.Channel(
      sourceChannelName: ch.channelName,
      contrastEnhancement: ch.contrastEnhancement != null
          ? _convertContrastEnhancement(ch.contrastEnhancement!)
          : null,
    );

ms.ContrastEnhancement _convertContrastEnhancement(
        sld.ContrastEnhancement ce) =>
    ms.ContrastEnhancement(
      enhancementType: ce.method != null
          ? switch (ce.method!) {
              sld.ContrastMethod.normalize => 'normalize',
              sld.ContrastMethod.histogram => 'histogram',
              sld.ContrastMethod.none => 'none',
            }
          : null,
      gammaValue: ce.gammaValue,
    );

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

ms.Filter? _convertFilter(sld.Filter filter, List<String> warnings) =>
    switch (filter) {
      // Comparison filters
      sld.PropertyIsEqualTo() => _convertComparison(
          ms.ComparisonOperator.eq, filter.expression1, filter.expression2),
      sld.PropertyIsNotEqualTo() => _convertComparison(
          ms.ComparisonOperator.neq, filter.expression1, filter.expression2),
      sld.PropertyIsLessThan() => _convertComparison(
          ms.ComparisonOperator.lt, filter.expression1, filter.expression2),
      sld.PropertyIsGreaterThan() => _convertComparison(
          ms.ComparisonOperator.gt, filter.expression1, filter.expression2),
      sld.PropertyIsLessThanOrEqualTo() => _convertComparison(
          ms.ComparisonOperator.lte, filter.expression1, filter.expression2),
      sld.PropertyIsGreaterThanOrEqualTo() => _convertComparison(
          ms.ComparisonOperator.gte, filter.expression1, filter.expression2),

      // Between → AND(gte, lte) — known limitation, no <=x<= operator.
      sld.PropertyIsBetween() => _convertBetween(filter, warnings),

      // Like — mapped to == with normalized pattern + warning.
      sld.PropertyIsLike() => _convertLike(filter, warnings),

      // Null → == null
      sld.PropertyIsNull() => _convertIsNull(filter),

      // Logical filters
      sld.And() => ms.CombinationFilter(
          operator: ms.CombinationOperator.and,
          filters: filter.filters
              .map((f) => _convertFilter(f, warnings))
              .whereType<ms.Filter>()
              .toList(),
        ),
      sld.Or() => ms.CombinationFilter(
          operator: ms.CombinationOperator.or,
          filters: filter.filters
              .map((f) => _convertFilter(f, warnings))
              .whereType<ms.Filter>()
              .toList(),
        ),
      sld.Not() => ms.NegationFilter(
          filter: _convertFilter(filter.filter, warnings) ??
              const ms.ComparisonFilter(
                operator: ms.ComparisonOperator.eq,
                property: ms.LiteralExpression(''),
                value: ms.LiteralExpression(''),
              ),
        ),

      // Spatial filters
      sld.BBox() => _convertSpatialFilter(
          ms.SpatialOperator.bbox, filter, warnings),
      sld.Intersects() => _convertSpatialFilter(
          ms.SpatialOperator.intersects, filter, warnings),
      sld.Within() => _convertSpatialFilter(
          ms.SpatialOperator.within, filter, warnings),
      sld.Contains() => _convertSpatialFilter(
          ms.SpatialOperator.contains, filter, warnings),
      sld.Touches() => _convertSpatialFilter(
          ms.SpatialOperator.touches, filter, warnings),
      sld.Crosses() => _convertSpatialFilter(
          ms.SpatialOperator.crosses, filter, warnings),
      sld.SpatialOverlaps() => _convertSpatialFilter(
          ms.SpatialOperator.overlaps, filter, warnings),
      sld.Disjoint() => _convertSpatialFilter(
          ms.SpatialOperator.disjoint, filter, warnings),

      // Distance filters
      sld.DWithin() => _convertDistanceFilter(
          ms.DistanceOperator.dWithin, filter, warnings),
      sld.Beyond() => _convertDistanceFilter(
          ms.DistanceOperator.beyond, filter, warnings),
    };

ms.ComparisonFilter _convertComparison(
  ms.ComparisonOperator op,
  sld.Expression expr1,
  sld.Expression expr2,
) =>
    ms.ComparisonFilter(
      operator: op,
      property: _convertPropertyExpression(expr1),
      value: _convertValueExpression(expr2),
    );

/// BUG-3 fix: PropertyIsBetween → AND(gte, lte) with warning.
ms.CombinationFilter _convertBetween(
    sld.PropertyIsBetween filter, List<String> warnings) {
  warnings.add('PropertyIsBetween decomposed to AND(>=, <=) — '
      'no <=x<= operator in GeoStyler; round-trip will not '
      'reconstruct PropertyIsBetween');

  final property = _convertPropertyExpression(filter.expression);
  final lower = _convertValueExpression(filter.lowerBoundary);
  final upper = _convertValueExpression(filter.upperBoundary);

  return ms.CombinationFilter(
    operator: ms.CombinationOperator.and,
    filters: [
      ms.ComparisonFilter(
        operator: ms.ComparisonOperator.gte,
        property: property,
        value: lower,
      ),
      ms.ComparisonFilter(
        operator: ms.ComparisonOperator.lte,
        property: property,
        value: upper,
      ),
    ],
  );
}

/// BUG-1 fix: PropertyIsLike → ComparisonFilter(eq) with warning.
/// GeoStyler ComparisonOperator has no '*=' / like variant, so we use
/// '==' with the normalized pattern and emit a warning.
ms.ComparisonFilter _convertLike(
    sld.PropertyIsLike filter, List<String> warnings) {
  var pattern = filter.pattern;
  if (filter.wildCard != '*') {
    pattern = pattern.replaceAll(filter.wildCard, '*');
  }
  if (filter.singleChar != '?') {
    pattern = pattern.replaceAll(filter.singleChar, '?');
  }

  warnings.add('PropertyIsLike mapped to == with pattern "$pattern" — '
      'GeoStyler has no like/wildcard operator');

  return ms.ComparisonFilter(
    operator: ms.ComparisonOperator.eq,
    property: _convertPropertyExpression(filter.expression),
    value: ms.LiteralExpression<Object>(pattern),
  );
}

/// BUG-2 fix: PropertyIsNull → NegationFilter(ComparisonFilter(neq, prop, prop)).
/// GeoStyler has no IsNull operator and LiteralExpression<Object> cannot hold
/// null (Object is non-nullable). We model "property IS NULL" as
/// NOT(property != property) — a property compared to itself is always true
/// when non-null, so negating != gives us IS NULL semantics in practice.
/// However, this is a known lossy mapping — the best we can do without
/// extending the type system.
ms.NegationFilter _convertIsNull(sld.PropertyIsNull filter) {
  final property = _convertPropertyExpression(filter.expression);
  // property != property is false when null (both sides null → false for !=)
  // NOT(false) = true → matches null features.
  return ms.NegationFilter(
    filter: ms.ComparisonFilter(
      operator: ms.ComparisonOperator.neq,
      property: property,
      value: ms.FunctionExpression<Object>(
        ms.PropertyGet(
          property is ms.LiteralExpression<String>
              ? property.value
              : '',
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Spatial / Distance filters
// ---------------------------------------------------------------------------

ms.SpatialFilter _convertSpatialFilter(
  ms.SpatialOperator op,
  sld.SpatialFilter filter, [
  List<String>? warnings,
]) =>
    ms.SpatialFilter(
      operator: op,
      propertyName: filter.propertyName,
      geometry: _convertGmlGeometry(filter.geometry, warnings),
    );

ms.DistanceFilter _convertDistanceFilter(
  ms.DistanceOperator op,
  sld.DistanceFilter filter, [
  List<String>? warnings,
]) =>
    ms.DistanceFilter(
      operator: op,
      propertyName: filter.propertyName,
      geometry: _convertGmlGeometry(filter.geometry, warnings),
      distance: filter.distance,
      units: filter.units,
    );

// ---------------------------------------------------------------------------
// Geometry conversion: gml4dart → mapstyler_style
// ---------------------------------------------------------------------------

/// Converts a GML geometry to the mapstyler minimal geometry model.
///
/// Multi-geometries are reduced to their first member with a warning
/// (EDGE-1). Unknown types fall back to `PointGeometry(0, 0)`.
ms.Geometry _convertGmlGeometry(gml.GmlGeometry geom,
    [List<String>? warnings]) {
  switch (geom) {
    case gml.GmlPoint(:final coordinate):
      return ms.PointGeometry(coordinate.x, coordinate.y);
    case gml.GmlEnvelope(:final lowerCorner, :final upperCorner):
      return ms.EnvelopeGeometry(
        minX: lowerCorner.x,
        minY: lowerCorner.y,
        maxX: upperCorner.x,
        maxY: upperCorner.y,
      );
    case gml.GmlBox(:final lowerCorner, :final upperCorner):
      return ms.EnvelopeGeometry(
        minX: lowerCorner.x,
        minY: lowerCorner.y,
        maxX: upperCorner.x,
        maxY: upperCorner.y,
      );
    case gml.GmlLineString(:final coordinates):
      return ms.LineStringGeometry(
        coordinates.map((c) => (c.x, c.y)).toList(),
      );
    case gml.GmlPolygon(:final exterior, :final interiors):
      return ms.PolygonGeometry([
        exterior.coordinates.map((c) => (c.x, c.y)).toList(),
        ...interiors
            .map((r) => r.coordinates.map((c) => (c.x, c.y)).toList()),
      ]);
    // Multi-geometries: use first member, emit warning (EDGE-1).
    case gml.GmlMultiPoint(:final points) when points.isNotEmpty:
      warnings?.add('MultiPoint reduced to first member');
      return ms.PointGeometry(
          points.first.coordinate.x, points.first.coordinate.y);
    case gml.GmlMultiLineString(:final lineStrings)
        when lineStrings.isNotEmpty:
      warnings?.add('MultiLineString reduced to first member');
      return ms.LineStringGeometry(
        lineStrings.first.coordinates.map((c) => (c.x, c.y)).toList(),
      );
    case gml.GmlMultiPolygon(:final polygons) when polygons.isNotEmpty:
      warnings?.add('MultiPolygon reduced to first member');
      return ms.PolygonGeometry([
        polygons.first.exterior.coordinates
            .map((c) => (c.x, c.y))
            .toList(),
        ...polygons.first.interiors
            .map((r) => r.coordinates.map((c) => (c.x, c.y)).toList()),
      ]);
    default:
      warnings?.add(
          'Unsupported geometry type ${geom.runtimeType} — '
          'falling back to PointGeometry(0, 0)');
      return const ms.PointGeometry(0, 0);
  }
}

// ---------------------------------------------------------------------------
// Expression conversion: flutter_map_sld → mapstyler_style
// ---------------------------------------------------------------------------

ms.Expression<String> _convertPropertyExpression(sld.Expression expr) =>
    switch (expr) {
      sld.PropertyName(:final name) =>
        ms.LiteralExpression<String>(name),
      sld.Literal(:final value) =>
        ms.LiteralExpression<String>(value.toString()),
      _ => ms.LiteralExpression<String>(expr.toString()),
    };

ms.Expression<Object> _convertValueExpression(sld.Expression expr) =>
    switch (expr) {
      // EDGE-3 fix: guard against null Literal values.
      sld.Literal(:final value) =>
        ms.LiteralExpression<Object>(value ?? ''),
      sld.PropertyName(:final name) =>
        ms.FunctionExpression<Object>(ms.PropertyGet(name)),
      sld.Concatenate(:final expressions) =>
        _convertConcatenate(expressions),
      sld.FormatNumber(:final numericValue, :final pattern) =>
        _convertFormatNumber(numericValue, pattern),
      sld.Categorize() => _convertCategorize(expr),
      sld.Interpolate() => _convertInterpolate(expr),
      sld.Recode() => _convertRecode(expr),
    };

/// Converts an SLD label expression to a mapstyler string expression.
ms.Expression<String> _convertLabelExpression(sld.Expression expr) =>
    switch (expr) {
      sld.PropertyName(:final name) =>
        ms.FunctionExpression<String>(ms.PropertyGet(name)),
      sld.Literal(:final value) =>
        ms.LiteralExpression<String>(value?.toString() ?? ''),
      sld.Concatenate(:final expressions) =>
        ms.FunctionExpression<String>(ms.ArgsFunction(
          name: 'strConcat',
          args: expressions.map(_convertExpressionToObject).toList(),
        )),
      sld.FormatNumber(:final numericValue, :final pattern) =>
        ms.FunctionExpression<String>(ms.ArgsFunction(
          name: 'numberFormat',
          args: [
            _convertExpressionToObject(numericValue),
            ms.LiteralExpression<Object>(pattern),
          ],
        )),
      _ => ms.LiteralExpression<String>(expr.toString()),
    };

ms.Expression<Object> _convertExpressionToObject(sld.Expression expr) =>
    switch (expr) {
      // EDGE-3 fix: guard against null Literal values.
      sld.Literal(:final value) =>
        ms.LiteralExpression<Object>(value ?? ''),
      sld.PropertyName(:final name) =>
        ms.FunctionExpression<Object>(ms.PropertyGet(name)),
      sld.Concatenate(:final expressions) =>
        ms.FunctionExpression<Object>(ms.ArgsFunction(
          name: 'strConcat',
          args: expressions.map(_convertExpressionToObject).toList(),
        )),
      sld.FormatNumber(:final numericValue, :final pattern) =>
        ms.FunctionExpression<Object>(ms.ArgsFunction(
          name: 'numberFormat',
          args: [
            _convertExpressionToObject(numericValue),
            ms.LiteralExpression<Object>(pattern),
          ],
        )),
      sld.Categorize() => _convertCategorize(expr),
      sld.Interpolate() => _convertInterpolate(expr),
      sld.Recode() => _convertRecode(expr),
    };

// ---------------------------------------------------------------------------
// Composite expression conversion
// ---------------------------------------------------------------------------

ms.FunctionExpression<Object> _convertConcatenate(
        List<sld.Expression> expressions) =>
    ms.FunctionExpression<Object>(ms.ArgsFunction(
      name: 'strConcat',
      args: expressions.map(_convertExpressionToObject).toList(),
    ));

ms.FunctionExpression<Object> _convertFormatNumber(
        sld.Expression numericValue, String pattern) =>
    ms.FunctionExpression<Object>(ms.ArgsFunction(
      name: 'numberFormat',
      args: [
        _convertExpressionToObject(numericValue),
        ms.LiteralExpression<Object>(pattern),
      ],
    ));

/// Categorize → StepFunction.
///
/// OGC Categorize: N thresholds, N+1 values.
/// GeoStyler step: input, defaultValue, boundary₁, value₁, ...
/// values[0] = defaultValue, then pairs (threshold[i], values[i+1]).
ms.FunctionExpression<Object> _convertCategorize(sld.Categorize cat) {
  // EDGE-2 fix: guard against empty values list.
  if (cat.values.isEmpty) {
    return ms.FunctionExpression<Object>(ms.StepFunction(
      input: _convertExpressionToObject(cat.lookupValue),
      defaultValue: const ms.LiteralExpression<Object>(''),
    ));
  }
  final input = _convertExpressionToObject(cat.lookupValue);
  final defaultValue = _convertExpressionToObject(cat.values.first);
  final stops = <ms.StepParameter>[];
  for (var i = 0; i < cat.thresholds.length && i + 1 < cat.values.length; i++) {
    stops.add(ms.StepParameter(
      boundary: _convertExpressionToObject(cat.thresholds[i]),
      value: _convertExpressionToObject(cat.values[i + 1]),
    ));
  }
  return ms.FunctionExpression<Object>(ms.StepFunction(
    input: input,
    defaultValue: defaultValue,
    stops: stops,
  ));
}

/// Interpolate → InterpolateFunction.
///
/// InterpolationPoint(data, value) → InterpolateParameter(stop, value).
ms.FunctionExpression<Object> _convertInterpolate(sld.Interpolate interp) {
  final mode = switch (interp.mode) {
    sld.InterpolateMode.linear => const ['linear'],
    sld.InterpolateMode.cubic => const ['cubic'],
  };
  return ms.FunctionExpression<Object>(ms.InterpolateFunction(
    mode: mode,
    input: _convertExpressionToObject(interp.lookupValue),
    stops: interp.dataPoints
        .map((dp) => ms.InterpolateParameter(
              stop: ms.LiteralExpression<Object>(dp.data),
              value: _convertExpressionToObject(dp.value),
            ))
        .toList(),
  ));
}

/// Recode → CaseFunction.
///
/// Each RecodeMapping(input, output) → CaseParameter with
/// equalTo(lookup, input) as condition.
ms.FunctionExpression<Object> _convertRecode(sld.Recode recode) {
  final lookupExpr = _convertExpressionToObject(recode.lookupValue);
  final cases = recode.mappings.map((m) {
    final inputExpr = _convertExpressionToObject(m.inputValue);
    return ms.CaseParameter(
      condition: ms.FunctionExpression<Object>(ms.ArgsFunction(
        name: 'equalTo',
        args: [lookupExpr, inputExpr],
      )),
      value: _convertExpressionToObject(m.outputValue),
    );
  }).toList();

  final fallback = recode.fallbackValue != null
      ? _convertExpressionToObject(recode.fallbackValue!)
      : const ms.LiteralExpression<Object>('');

  return ms.FunctionExpression<Object>(ms.CaseFunction(
    cases: cases,
    fallback: fallback,
  ));
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Converts SLD `mitre` to GeoStyler `miter`.
String? _convertLineJoin(String? join) {
  if (join == 'mitre') return 'miter';
  return join;
}
