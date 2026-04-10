/// Converts mapstyler_style types to flutter_map_sld types (Write direction).
///
/// mapstyler_style → **this adapter** → flutter_map_sld types.
///
/// Note: This produces flutter_map_sld model objects, not SLD XML strings.
/// flutter_map_sld is primarily a parser and does not provide XML
/// serialization. The resulting objects can be used for runtime evaluation
/// (filter matching, symbolizer lookup).
library;

import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:gml4dart/gml4dart.dart' as gml;
import 'package:mapstyler_style/mapstyler_style.dart' as ms;

import 'color_util.dart';

// ---------------------------------------------------------------------------
// Style → SldDocument
// ---------------------------------------------------------------------------

/// Converts a [ms.Style] to an [sld.SldDocument].
///
/// Wraps all rules in a single Layer → UserStyle → FeatureTypeStyle.
/// Returns a [ms.WriteStyleResult] with the result or errors.
ms.WriteStyleResult<sld.SldDocument> convertStyle(ms.Style style) {
  final warnings = <String>[];
  final rules = <sld.Rule>[];

  for (final rule in style.rules) {
    rules.add(_convertRule(rule, warnings));
  }

  final doc = sld.SldDocument(
    version: '1.0.0',
    layers: [
      sld.SldLayer(
        name: style.name,
        styles: [
          sld.UserStyle(
            name: style.name,
            featureTypeStyles: [sld.FeatureTypeStyle(rules: rules)],
          ),
        ],
      ),
    ],
  );

  return ms.WriteStyleSuccess(output: doc, warnings: warnings);
}

// ---------------------------------------------------------------------------
// Rule
// ---------------------------------------------------------------------------

sld.Rule _convertRule(ms.Rule rule, List<String> warnings) {
  sld.PointSymbolizer? pointSym;
  sld.LineSymbolizer? lineSym;
  sld.PolygonSymbolizer? polygonSym;
  sld.TextSymbolizer? textSym;
  sld.RasterSymbolizer? rasterSym;

  for (final sym in rule.symbolizers) {
    switch (sym) {
      case ms.MarkSymbolizer():
        pointSym ??= _convertMarkSymbolizer(sym);
      case ms.IconSymbolizer():
        pointSym ??= _convertIconSymbolizer(sym);
      case ms.LineSymbolizer():
        lineSym ??= _convertLineSymbolizer(sym);
      case ms.FillSymbolizer():
        polygonSym ??= _convertFillSymbolizer(sym);
      case ms.TextSymbolizer():
        textSym ??= _convertTextSymbolizer(sym, warnings);
      case ms.RasterSymbolizer():
        rasterSym ??= _convertRasterSymbolizer(sym, warnings);
    }
  }

  return sld.Rule(
    name: rule.name,
    filter: rule.filter != null ? _convertFilter(rule.filter!, warnings) : null,
    minScaleDenominator: rule.scaleDenominator?.min,
    maxScaleDenominator: rule.scaleDenominator?.max,
    pointSymbolizer: pointSym,
    lineSymbolizer: lineSym,
    polygonSymbolizer: polygonSym,
    textSymbolizer: textSym,
    rasterSymbolizer: rasterSym,
  );
}

// ---------------------------------------------------------------------------
// Symbolizers
// ---------------------------------------------------------------------------

sld.PointSymbolizer _convertMarkSymbolizer(ms.MarkSymbolizer sym) {
  // GeoStyler radius → SLD size (diameter).
  final radius = _literalDouble(sym.radius);
  final size = radius != null ? radius * 2 : null;

  final color = _literalString(sym.color);
  final strokeColor = _literalString(sym.strokeColor);

  return sld.PointSymbolizer(
    graphic: sld.Graphic(
      mark: sld.Mark(
        wellKnownName: sym.wellKnownName,
        fill: color != null ? sld.Fill(colorArgb: hexToArgb(color)) : null,
        stroke:
            strokeColor != null
                ? sld.Stroke(
                  colorArgb: hexToArgb(strokeColor),
                  width: _literalDouble(sym.strokeWidth),
                )
                : null,
      ),
      size: size,
      rotation: _literalDouble(sym.rotate),
      opacity: _literalDouble(sym.opacity),
    ),
  );
}

sld.PointSymbolizer _convertIconSymbolizer(ms.IconSymbolizer sym) {
  final image = _literalString(sym.image);

  return sld.PointSymbolizer(
    graphic: sld.Graphic(
      externalGraphic:
          image != null
              ? sld.ExternalGraphic(onlineResource: image, format: sym.format)
              : null,
      size: _literalDouble(sym.size),
      rotation: _literalDouble(sym.rotate),
      opacity: _literalDouble(sym.opacity),
    ),
  );
}

sld.LineSymbolizer _convertLineSymbolizer(ms.LineSymbolizer sym) {
  final color = _literalString(sym.color);
  return sld.LineSymbolizer(
    stroke: sld.Stroke(
      colorArgb: color != null ? hexToArgb(color) : null,
      width: _literalDouble(sym.width),
      opacity: _literalDouble(sym.opacity),
      dashArray: sym.dasharray,
      lineCap: sym.cap,
      lineJoin: _convertLineJoinReverse(sym.join),
    ),
  );
}

// WRITE-3 fix: create Fill/Stroke even when color is null but opacity/width
// are present.
sld.PolygonSymbolizer _convertFillSymbolizer(ms.FillSymbolizer sym) {
  final color = _literalString(sym.color);
  final fillOpacity = _literalDouble(sym.fillOpacity);
  final outlineColor = _literalString(sym.outlineColor);
  final outlineWidth = _literalDouble(sym.outlineWidth);

  final hasFill = color != null || fillOpacity != null;
  final hasStroke = outlineColor != null || outlineWidth != null;

  return sld.PolygonSymbolizer(
    fill:
        hasFill
            ? sld.Fill(
              colorArgb: color != null ? hexToArgb(color) : null,
              opacity: fillOpacity,
            )
            : null,
    stroke:
        hasStroke
            ? sld.Stroke(
              colorArgb: outlineColor != null ? hexToArgb(outlineColor) : null,
              width: outlineWidth,
            )
            : null,
  );
}

sld.TextSymbolizer _convertTextSymbolizer(
  ms.TextSymbolizer sym,
  List<String> warnings,
) {
  sld.Expression? label;
  switch (sym.label) {
    case ms.LiteralExpression<String>(:final value):
      label = sld.Literal(value);
    case ms.FunctionExpression<String>(
      function: ms.PropertyGet(:final propertyName),
    ):
      label = sld.PropertyName(propertyName);
    case ms.FunctionExpression<String>(
      function: ms.ArgsFunction(name: 'strConcat', :final args),
    ):
      label = sld.Concatenate(
        expressions: args.map(_convertValueToSldExpression).toList(),
      );
    default:
      warnings.add('Unsupported label expression type');
  }

  final color = _literalString(sym.color);
  final haloColor = _literalString(sym.haloColor);
  final haloWidth = _literalDouble(sym.haloWidth);

  sld.LabelPlacement? placement;
  if (sym.placement == 'point') {
    placement = sld.LabelPlacement(
      pointPlacement: sld.PointPlacement(rotation: _literalDouble(sym.rotate)),
    );
  } else if (sym.placement == 'line') {
    placement = const sld.LabelPlacement(linePlacement: sld.LinePlacement());
  }

  // WRITE-2 fix: create Halo when either haloColor or haloWidth is set.
  final hasHalo = haloColor != null || haloWidth != null;

  return sld.TextSymbolizer(
    label: label,
    font: sld.Font(family: sym.font, size: _literalDouble(sym.size)),
    fill: color != null ? sld.Fill(colorArgb: hexToArgb(color)) : null,
    halo:
        hasHalo
            ? sld.Halo(
              fill:
                  haloColor != null
                      ? sld.Fill(colorArgb: hexToArgb(haloColor))
                      : null,
              radius: haloWidth,
            )
            : null,
    labelPlacement: placement,
  );
}

sld.RasterSymbolizer _convertRasterSymbolizer(
  ms.RasterSymbolizer sym,
  List<String> warnings,
) {
  // CSS-filter properties are not supported in SLD.
  if (sym.hueRotate != null ||
      sym.brightnessMin != null ||
      sym.brightnessMax != null ||
      sym.saturation != null ||
      sym.contrast != null) {
    warnings.add(
      'CSS-filter properties (hueRotate, brightness, saturation, contrast) '
      'are not supported in SLD',
    );
  }

  return sld.RasterSymbolizer(
    opacity: _literalDouble(sym.opacity),
    colorMap: sym.colorMap != null ? _convertColorMap(sym.colorMap!) : null,
    channelSelection:
        sym.channelSelection != null
            ? _convertChannelSelection(sym.channelSelection!)
            : null,
    contrastEnhancement:
        sym.contrastEnhancement != null
            ? _convertContrastEnhancement(sym.contrastEnhancement!)
            : null,
  );
}

// ---------------------------------------------------------------------------
// Raster support types
// ---------------------------------------------------------------------------

sld.ColorMap _convertColorMap(ms.ColorMap cm) {
  final type = switch (cm.type) {
    'ramp' => sld.ColorMapType.ramp,
    'intervals' => sld.ColorMapType.intervals,
    'values' => sld.ColorMapType.exactValues,
    _ => sld.ColorMapType.ramp,
  };
  return sld.ColorMap(
    type: type,
    entries: cm.colorMapEntries.map(_convertColorMapEntry).toList(),
  );
}

sld.ColorMapEntry _convertColorMapEntry(ms.ColorMapEntry entry) =>
    sld.ColorMapEntry(
      colorArgb: hexToArgb(entry.color),
      quantity: entry.quantity,
      opacity: entry.opacity ?? 1.0,
      label: entry.label,
    );

sld.ChannelSelection _convertChannelSelection(
  ms.ChannelSelection cs,
) => sld.ChannelSelection(
  redChannel: cs.redChannel != null ? _convertChannel(cs.redChannel!) : null,
  greenChannel:
      cs.greenChannel != null ? _convertChannel(cs.greenChannel!) : null,
  blueChannel: cs.blueChannel != null ? _convertChannel(cs.blueChannel!) : null,
  grayChannel: cs.grayChannel != null ? _convertChannel(cs.grayChannel!) : null,
);

sld.SelectedChannel _convertChannel(ms.Channel ch) => sld.SelectedChannel(
  channelName: ch.sourceChannelName,
  contrastEnhancement:
      ch.contrastEnhancement != null
          ? _convertContrastEnhancement(ch.contrastEnhancement!)
          : null,
);

sld.ContrastEnhancement _convertContrastEnhancement(
  ms.ContrastEnhancement ce,
) => sld.ContrastEnhancement(
  method:
      ce.enhancementType != null
          ? switch (ce.enhancementType!) {
            'normalize' => sld.ContrastMethod.normalize,
            'histogram' => sld.ContrastMethod.histogram,
            'none' => sld.ContrastMethod.none,
            _ => null,
          }
          : null,
  gammaValue: ce.gammaValue,
);

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

sld.Filter? _convertFilter(
  ms.Filter filter,
  List<String> warnings,
) => switch (filter) {
  ms.ComparisonFilter(:final operator, :final property, :final value) =>
    _convertComparisonFilter(operator, property, value),
  ms.CombinationFilter(operator: ms.CombinationOperator.and, :final filters) =>
    sld.And(
      filters:
          filters
              .map((f) => _convertFilter(f, warnings))
              .whereType<sld.Filter>()
              .toList(),
    ),
  ms.CombinationFilter(operator: ms.CombinationOperator.or, :final filters) =>
    sld.Or(
      filters:
          filters
              .map((f) => _convertFilter(f, warnings))
              .whereType<sld.Filter>()
              .toList(),
    ),
  ms.NegationFilter(:final filter) => sld.Not(
    filter:
        _convertFilter(filter, warnings) ??
        const sld.PropertyIsEqualTo(
          expression1: sld.Literal(''),
          expression2: sld.Literal(''),
        ),
  ),
  ms.SpatialFilter() => _convertSpatialFilter(filter, warnings),
  ms.DistanceFilter() => _convertDistanceFilter(filter, warnings),
};

/// BUG-4 fix: ComparisonFilter.property is always a property name reference,
/// ComparisonFilter.value is always a literal value. We use separate
/// conversion paths to avoid the ambiguity.
sld.Filter _convertComparisonFilter(
  ms.ComparisonOperator op,
  ms.Expression<String> property,
  ms.Expression<Object> value,
) {
  final expr1 = _convertPropertyToSldExpression(property);
  final expr2 = _convertValueToSldExpression(value);
  return switch (op) {
    ms.ComparisonOperator.eq => sld.PropertyIsEqualTo(
      expression1: expr1,
      expression2: expr2,
    ),
    ms.ComparisonOperator.neq => sld.PropertyIsNotEqualTo(
      expression1: expr1,
      expression2: expr2,
    ),
    ms.ComparisonOperator.lt => sld.PropertyIsLessThan(
      expression1: expr1,
      expression2: expr2,
    ),
    ms.ComparisonOperator.gt => sld.PropertyIsGreaterThan(
      expression1: expr1,
      expression2: expr2,
    ),
    ms.ComparisonOperator.lte => sld.PropertyIsLessThanOrEqualTo(
      expression1: expr1,
      expression2: expr2,
    ),
    ms.ComparisonOperator.gte => sld.PropertyIsGreaterThanOrEqualTo(
      expression1: expr1,
      expression2: expr2,
    ),
  };
}

sld.SpatialFilter? _convertSpatialFilter(
  ms.SpatialFilter filter,
  List<String> warnings,
) {
  final geom = _convertToGmlGeometry(filter.geometry);
  return switch (filter.operator) {
    ms.SpatialOperator.bbox => sld.BBox(
      propertyName: filter.propertyName,
      envelope:
          geom is gml.GmlEnvelope
              ? geom
              : gml.GmlEnvelope(
                lowerCorner: const gml.GmlCoordinate(0, 0),
                upperCorner: const gml.GmlCoordinate(0, 0),
              ),
    ),
    ms.SpatialOperator.intersects => sld.Intersects(
      propertyName: filter.propertyName,
      geometry: geom,
    ),
    ms.SpatialOperator.within => sld.Within(
      propertyName: filter.propertyName,
      geometry: geom,
    ),
    ms.SpatialOperator.contains => sld.Contains(
      propertyName: filter.propertyName,
      geometry: geom,
    ),
    ms.SpatialOperator.touches => sld.Touches(
      propertyName: filter.propertyName,
      geometry: geom,
    ),
    ms.SpatialOperator.crosses => sld.Crosses(
      propertyName: filter.propertyName,
      geometry: geom,
    ),
    ms.SpatialOperator.overlaps => sld.SpatialOverlaps(
      propertyName: filter.propertyName,
      geometry: geom,
    ),
    ms.SpatialOperator.disjoint => sld.Disjoint(
      propertyName: filter.propertyName,
      geometry: geom,
    ),
  };
}

sld.DistanceFilter? _convertDistanceFilter(
  ms.DistanceFilter filter,
  List<String> warnings,
) {
  final geom = _convertToGmlGeometry(filter.geometry);
  return switch (filter.operator) {
    ms.DistanceOperator.dWithin => sld.DWithin(
      propertyName: filter.propertyName,
      geometry: geom,
      distance: filter.distance,
      units: filter.units,
    ),
    ms.DistanceOperator.beyond => sld.Beyond(
      propertyName: filter.propertyName,
      geometry: geom,
      distance: filter.distance,
      units: filter.units,
    ),
  };
}

// ---------------------------------------------------------------------------
// Geometry conversion: mapstyler_style → gml4dart
// ---------------------------------------------------------------------------

gml.GmlGeometry _convertToGmlGeometry(ms.Geometry geom) => switch (geom) {
  ms.PointGeometry(:final x, :final y) => gml.GmlPoint(
    coordinate: gml.GmlCoordinate(x, y),
  ),
  ms.EnvelopeGeometry(:final minX, :final minY, :final maxX, :final maxY) =>
    gml.GmlEnvelope(
      lowerCorner: gml.GmlCoordinate(minX, minY),
      upperCorner: gml.GmlCoordinate(maxX, maxY),
    ),
  ms.LineStringGeometry(:final coordinates) => gml.GmlLineString(
    coordinates: coordinates.map((c) => gml.GmlCoordinate(c.$1, c.$2)).toList(),
  ),
  ms.PolygonGeometry(:final rings) => gml.GmlPolygon(
    exterior: gml.GmlLinearRing(
      coordinates:
          rings.isNotEmpty
              ? rings.first.map((c) => gml.GmlCoordinate(c.$1, c.$2)).toList()
              : const [],
    ),
    interiors:
        rings.length > 1
            ? rings
                .skip(1)
                .map(
                  (r) => gml.GmlLinearRing(
                    coordinates:
                        r.map((c) => gml.GmlCoordinate(c.$1, c.$2)).toList(),
                  ),
                )
                .toList()
            : const [],
  ),
};

// ---------------------------------------------------------------------------
// Expression conversion: mapstyler_style → flutter_map_sld
// ---------------------------------------------------------------------------

/// Converts a property-context expression to SLD.
/// In GeoStyler, ComparisonFilter.property holds the property name as a
/// string literal expression. In SLD, this becomes a PropertyName.
sld.Expression _convertPropertyToSldExpression(ms.Expression<String> expr) =>
    switch (expr) {
      ms.LiteralExpression<String>(:final value) => sld.PropertyName(value),
      ms.FunctionExpression<String>(
        function: ms.PropertyGet(:final propertyName),
      ) =>
        sld.PropertyName(propertyName),
      _ => sld.PropertyName(''),
    };

/// Converts a value-context expression to SLD.
/// BUG-4 fix: Values are always Literals (not PropertyNames), unless
/// they are FunctionExpression(PropertyGet) which means a dynamic lookup.
sld.Expression _convertValueToSldExpression(
  ms.Expression<Object> expr,
) => switch (expr) {
  ms.LiteralExpression<Object>(:final value) => sld.Literal(value),
  ms.FunctionExpression<Object>(
    function: ms.PropertyGet(:final propertyName),
  ) =>
    sld.PropertyName(propertyName),
  // WRITE-4 fix: convert composite functions where possible, warn otherwise.
  ms.FunctionExpression<Object>(
    function: ms.ArgsFunction(name: 'strConcat', :final args),
  ) =>
    sld.Concatenate(
      expressions: args.map(_convertValueToSldExpression).toList(),
    ),
  ms.FunctionExpression<Object>(
    function: ms.ArgsFunction(name: 'numberFormat', :final args),
  )
      when args.length >= 2 =>
    sld.FormatNumber(
      numericValue: _convertValueToSldExpression(args[0]),
      pattern: _extractStringValue(args[1]),
    ),
  ms.FunctionExpression<Object>(
    function: ms.StepFunction(:final input, :final defaultValue, :final stops),
  ) =>
    _convertStepToCategorize(input, defaultValue, stops),
  ms.FunctionExpression<Object>(
    function: ms.InterpolateFunction(:final mode, :final input, :final stops),
  ) =>
    _convertInterpolateFunctionToSld(mode, input, stops),
  ms.FunctionExpression<Object>(
    function: ms.CaseFunction(:final cases, :final fallback),
  ) =>
    _convertCaseFunctionToRecode(cases, fallback),
  ms.FunctionExpression<Object>() => sld.Literal(null),
};

// ---------------------------------------------------------------------------
// Composite expression write helpers (WRITE-4 fix)
// ---------------------------------------------------------------------------

/// step → Categorize
sld.Categorize _convertStepToCategorize(
  ms.Expression<Object> input,
  ms.Expression<Object> defaultValue,
  List<ms.StepParameter> stops,
) {
  final thresholds = <sld.Expression>[];
  final values = <sld.Expression>[_convertValueToSldExpression(defaultValue)];
  for (final stop in stops) {
    thresholds.add(_convertValueToSldExpression(stop.boundary));
    values.add(_convertValueToSldExpression(stop.value));
  }
  return sld.Categorize(
    lookupValue: _convertValueToSldExpression(input),
    thresholds: thresholds,
    values: values,
  );
}

/// interpolate → Interpolate
sld.Interpolate _convertInterpolateFunctionToSld(
  List<Object> mode,
  ms.Expression<Object> input,
  List<ms.InterpolateParameter> stops,
) {
  final sldMode =
      (mode.isNotEmpty && mode.first == 'cubic')
          ? sld.InterpolateMode.cubic
          : sld.InterpolateMode.linear;
  return sld.Interpolate(
    lookupValue: _convertValueToSldExpression(input),
    mode: sldMode,
    dataPoints:
        stops
            .map(
              (s) => sld.InterpolationPoint(
                data: _extractNumValue(s.stop),
                value: _convertValueToSldExpression(s.value),
              ),
            )
            .toList(),
  );
}

/// case → Recode (best-effort: only works for equalTo conditions).
sld.Recode _convertCaseFunctionToRecode(
  List<ms.CaseParameter> cases,
  ms.Expression<Object> fallback,
) {
  // Try to extract the lookup value from the first equalTo condition.
  sld.Expression? lookupValue;
  final mappings = <sld.RecodeMapping>[];
  for (final c in cases) {
    if (c.condition case ms.FunctionExpression<Object>(
      function: ms.ArgsFunction(
        name: 'equalTo',
        args: [final lookup, final input],
      ),
    )) {
      lookupValue ??= _convertValueToSldExpression(lookup);
      mappings.add(
        sld.RecodeMapping(
          inputValue: _convertValueToSldExpression(input),
          outputValue: _convertValueToSldExpression(c.value),
        ),
      );
    }
  }
  return sld.Recode(
    lookupValue: lookupValue ?? const sld.Literal(''),
    mappings: mappings,
    fallbackValue: _convertValueToSldExpression(fallback),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

double? _literalDouble(ms.Expression<double>? expr) => switch (expr) {
  ms.LiteralExpression<double>(:final value) => value,
  _ => null,
};

String? _literalString(ms.Expression<String>? expr) => switch (expr) {
  ms.LiteralExpression<String>(:final value) => value,
  _ => null,
};

String _extractStringValue(ms.Expression<Object> expr) => switch (expr) {
  ms.LiteralExpression<Object>(:final value) => value.toString(),
  _ => '',
};

num _extractNumValue(ms.Expression<Object> expr) => switch (expr) {
  ms.LiteralExpression<Object>(:final value) when value is num => value,
  _ => 0,
};

/// Converts GeoStyler `miter` to SLD `mitre`.
String? _convertLineJoinReverse(String? join) {
  if (join == 'miter') return 'mitre';
  return join;
}
