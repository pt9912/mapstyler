/// Converts qml4dart types to mapstyler_style types (Read direction).
///
/// QML XML → qml4dart (parser) → **this adapter** → mapstyler_style.
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:qml4dart/qml4dart.dart' as qml;

import 'color_util.dart';

// ---------------------------------------------------------------------------
// QmlDocument → Style
// ---------------------------------------------------------------------------

/// Converts a [qml.QmlDocument] to a [ms.ReadStyleResult].
ms.ReadStyleResult convertDocument(qml.QmlDocument doc) {
  final warnings = <String>[];
  final rules = <ms.Rule>[];

  final r = doc.renderer;

  // Build document-level scale denominator if set.
  final docScale = doc.hasScaleBasedVisibility
      ? ms.ScaleDenominator(
          min: doc.maxScale, // maxScale = most zoomed-in = min denominator
          max: doc.minScale, // minScale = most zoomed-out = max denominator
        )
      : null;

  switch (r.type) {
    case qml.QmlRendererType.singleSymbol:
      final sym = r.symbols['0'];
      if (sym != null) {
        rules.add(ms.Rule(
          name: 'default',
          symbolizers: _convertSymbol(sym, warnings),
          scaleDenominator: docScale,
        ));
      }

    case qml.QmlRendererType.categorizedSymbol:
      for (final cat in r.categories) {
        final sym = r.symbols[cat.symbolKey];
        if (sym == null) {
          warnings.add('Category "${cat.value}": symbol ${cat.symbolKey} '
              'not found');
          continue;
        }
        if (!cat.render) continue;

        ms.Filter? filter;
        if (r.attribute != null && cat.value.isNotEmpty) {
          filter = ms.ComparisonFilter(
            operator: ms.ComparisonOperator.eq,
            property: ms.LiteralExpression(r.attribute!),
            value: ms.LiteralExpression<Object>(cat.value),
          );
        }

        rules.add(ms.Rule(
          name: cat.label ?? cat.value,
          filter: filter,
          symbolizers: _convertSymbol(sym, warnings),
          scaleDenominator: docScale,
        ));
      }

    case qml.QmlRendererType.graduatedSymbol:
      for (final range in r.ranges) {
        final sym = r.symbols[range.symbolKey];
        if (sym == null) {
          warnings.add('Range ${range.lower}–${range.upper}: '
              'symbol ${range.symbolKey} not found');
          continue;
        }
        if (!range.render) continue;

        ms.Filter? filter;
        if (r.attribute != null) {
          filter = ms.CombinationFilter(
            operator: ms.CombinationOperator.and,
            filters: [
              ms.ComparisonFilter(
                operator: ms.ComparisonOperator.gte,
                property: ms.LiteralExpression(r.attribute!),
                value: ms.LiteralExpression<Object>(range.lower),
              ),
              ms.ComparisonFilter(
                operator: ms.ComparisonOperator.lt,
                property: ms.LiteralExpression(r.attribute!),
                value: ms.LiteralExpression<Object>(range.upper),
              ),
            ],
          );
        }

        rules.add(ms.Rule(
          name: range.label ?? '${range.lower}–${range.upper}',
          filter: filter,
          symbolizers: _convertSymbol(sym, warnings),
          scaleDenominator: docScale,
        ));
      }

    case qml.QmlRendererType.ruleRenderer:
      _convertRules(r.rules, r.symbols, null, rules, warnings);

    case qml.QmlRendererType.unknown:
      warnings.add('Unknown renderer type, cannot convert');
  }

  return ms.ReadStyleSuccess(
    output: ms.Style(name: doc.version, rules: rules),
    warnings: warnings,
  );
}

// ---------------------------------------------------------------------------
// Rules (RuleRenderer, supports nesting)
// ---------------------------------------------------------------------------

void _convertRules(
  List<qml.QmlRule> qmlRules,
  Map<String, qml.QmlSymbol> symbols,
  ms.Filter? parentFilter,
  List<ms.Rule> output,
  List<String> warnings,
) {
  for (final qr in qmlRules) {
    if (!qr.enabled) continue;

    // Build filter from expression string.
    ms.Filter? ruleFilter;
    if (qr.filter != null && qr.filter!.isNotEmpty) {
      ruleFilter = _parseSimpleFilter(qr.filter!);
      if (ruleFilter == null) {
        warnings.add('Could not parse filter: ${qr.filter}');
      }
    }

    // Combine with parent filter.
    final combinedFilter = switch ((parentFilter, ruleFilter)) {
      (null, null) => null,
      (null, final f?) => f,
      (final p?, null) => p,
      (final p?, final f?) => ms.CombinationFilter(
          operator: ms.CombinationOperator.and,
          filters: [p, f],
        ),
    };

    final scale = _buildScaleDenominator(
      qr.scaleMinDenominator,
      qr.scaleMaxDenominator,
    );

    if (qr.children.isNotEmpty) {
      // Grouping rule: recurse with combined filter.
      _convertRules(qr.children, symbols, combinedFilter, output, warnings);
    } else if (qr.symbolKey != null) {
      final sym = symbols[qr.symbolKey!];
      if (sym == null) {
        warnings.add('Rule "${qr.label}": symbol ${qr.symbolKey} not found');
        continue;
      }
      output.add(ms.Rule(
        name: qr.label,
        filter: combinedFilter,
        symbolizers: _convertSymbol(sym, warnings),
        scaleDenominator: scale,
      ));
    }
  }
}

// ---------------------------------------------------------------------------
// Symbol → Symbolizers
// ---------------------------------------------------------------------------

List<ms.Symbolizer> _convertSymbol(
  qml.QmlSymbol sym,
  List<String> warnings,
) {
  final result = <ms.Symbolizer>[];
  for (final layer in sym.layers) {
    if (!layer.enabled) continue;
    final symbolizer = _convertSymbolLayer(layer, sym.alpha, warnings);
    if (symbolizer != null) result.add(symbolizer);
  }
  return result;
}

ms.Symbolizer? _convertSymbolLayer(
  qml.QmlSymbolLayer layer,
  double symbolAlpha,
  List<String> warnings,
) {
  final p = layer.properties;

  // Effective opacity: symbol alpha * layer-level color alpha.
  double? effectiveOpacity(String? colorProp) {
    final colorOpacity = qgisColorToOpacity(colorProp);
    if (symbolAlpha < 1.0 || colorOpacity != null) {
      return symbolAlpha * (colorOpacity ?? 1.0);
    }
    return null;
  }

  switch (layer.type) {
    case qml.QmlSymbolLayerType.simpleFill:
      return ms.FillSymbolizer(
        color: _hexExpr(p['color']),
        opacity: _doubleExpr(effectiveOpacity(p['color'])),
        fillOpacity: _doubleExpr(effectiveOpacity(p['color'])),
        outlineColor: _hexExpr(p['outline_color']),
        outlineWidth: _doubleExpr(double.tryParse(p['outline_width'] ?? '')),
      );

    case qml.QmlSymbolLayerType.simpleLine:
      return ms.LineSymbolizer(
        color: _hexExpr(p['line_color']),
        width: _doubleExpr(double.tryParse(p['line_width'] ?? '')),
        opacity: _doubleExpr(effectiveOpacity(p['line_color'])),
        dasharray: _parseDashArray(p['customdash'], p['use_custom_dash']),
        cap: p['capstyle'],
        join: p['joinstyle'],
      );

    case qml.QmlSymbolLayerType.simpleMarker:
      return ms.MarkSymbolizer(
        wellKnownName: _mapMarkerShape(p['name'] ?? 'circle'),
        radius: _doubleExpr(
          _halve(double.tryParse(p['size'] ?? '')),
        ),
        color: _hexExpr(p['color']),
        opacity: _doubleExpr(effectiveOpacity(p['color'])),
        strokeColor: _hexExpr(p['outline_color']),
        strokeWidth: _doubleExpr(double.tryParse(p['outline_width'] ?? '')),
        rotate: _doubleExpr(double.tryParse(p['angle'] ?? '')),
      );

    case qml.QmlSymbolLayerType.svgMarker:
      final image = p['name'] ?? '';
      return ms.IconSymbolizer(
        image: ms.LiteralExpression(image),
        size: _doubleExpr(double.tryParse(p['size'] ?? '')),
        opacity: _doubleExpr(effectiveOpacity(p['color'])),
        rotate: _doubleExpr(double.tryParse(p['angle'] ?? '')),
      );

    case qml.QmlSymbolLayerType.rasterFill:
      warnings.add('RasterFill not mapped to mapstyler_style');
      return null;

    case qml.QmlSymbolLayerType.unknown:
      warnings.add('Unknown symbol layer class: ${layer.className}');
      return null;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ms.Expression<String>? _hexExpr(String? qgisColor) {
  final hex = qgisColorToHex(qgisColor);
  if (hex == null) return null;
  return ms.LiteralExpression(hex);
}

ms.Expression<double>? _doubleExpr(double? value) {
  if (value == null || value == 0.0) return null;
  return ms.LiteralExpression(value);
}

double? _halve(double? value) {
  if (value == null) return null;
  return value / 2;
}

List<double>? _parseDashArray(String? customDash, String? useCustomDash) {
  if (useCustomDash != '1' || customDash == null || customDash.isEmpty) {
    return null;
  }
  return customDash
      .split(';')
      .map((s) => double.tryParse(s.trim()))
      .whereType<double>()
      .toList();
}

/// Maps QGIS marker shapes to GeoStyler WellKnownName values.
String _mapMarkerShape(String qgisName) => switch (qgisName) {
      'circle' => 'circle',
      'square' => 'square',
      'diamond' => 'diamond',
      'triangle' || 'equilateral_triangle' => 'triangle',
      'star' || 'star_diamond' => 'star',
      'cross' || 'cross_fill' => 'cross',
      'cross2' || 'x' => 'x',
      _ => qgisName,
    };

ms.ScaleDenominator? _buildScaleDenominator(double? min, double? max) {
  if (min == null && max == null) return null;
  return ms.ScaleDenominator(min: min, max: max);
}

/// Parses simple QGIS filter expressions like `field = 'value'` or
/// `field = 1`. Returns `null` for complex expressions.
ms.Filter? _parseSimpleFilter(String expr) {
  // Try: field = 'value' or field = value
  final eqMatch = RegExp(r"^(\w+)\s*=\s*'?([^']*)'?$").firstMatch(expr);
  if (eqMatch != null) {
    return ms.ComparisonFilter(
      operator: ms.ComparisonOperator.eq,
      property: ms.LiteralExpression(eqMatch.group(1)!),
      value: ms.LiteralExpression<Object>(_parseValue(eqMatch.group(2)!)),
    );
  }

  // Try: field > value, field < value, field >= value, field <= value
  final cmpMatch =
      RegExp(r'^(\w+)\s*(>=|<=|>|<|!=)\s*(.+)$').firstMatch(expr);
  if (cmpMatch != null) {
    final op = switch (cmpMatch.group(2)!) {
      '>=' => ms.ComparisonOperator.gte,
      '<=' => ms.ComparisonOperator.lte,
      '>' => ms.ComparisonOperator.gt,
      '<' => ms.ComparisonOperator.lt,
      '!=' => ms.ComparisonOperator.neq,
      _ => ms.ComparisonOperator.eq,
    };
    return ms.ComparisonFilter(
      operator: op,
      property: ms.LiteralExpression(cmpMatch.group(1)!),
      value: ms.LiteralExpression<Object>(
        _parseValue(cmpMatch.group(3)!.trim().replaceAll("'", '')),
      ),
    );
  }

  return null;
}

Object _parseValue(String s) {
  final asNum = num.tryParse(s);
  if (asNum != null) return asNum;
  return s;
}
