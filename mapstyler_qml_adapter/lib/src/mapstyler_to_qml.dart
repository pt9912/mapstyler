/// Converts mapstyler_style types to qml4dart types (Write direction).
///
/// mapstyler_style → **this adapter** → qml4dart → QML XML.
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:qml4dart/qml4dart.dart' as qml;

import 'color_util.dart';

// ---------------------------------------------------------------------------
// Style → QmlDocument
// ---------------------------------------------------------------------------

/// Converts a [ms.Style] to a [ms.WriteStyleResult] containing a
/// [qml.QmlDocument].
ms.WriteStyleResult<qml.QmlDocument> convertStyle(ms.Style style) {
  final warnings = <String>[];

  // Determine renderer type from the rules.
  final renderer = _buildRenderer(style.rules, warnings);

  final doc = qml.QmlDocument(
    version: '3.28.0',
    renderer: renderer,
  );

  return ms.WriteStyleSuccess(output: doc, warnings: warnings);
}

// ---------------------------------------------------------------------------
// Rules → Renderer
// ---------------------------------------------------------------------------

qml.QmlRenderer _buildRenderer(
  List<ms.Rule> rules,
  List<String> warnings,
) {
  if (rules.isEmpty) {
    return const qml.QmlRenderer(type: qml.QmlRendererType.singleSymbol);
  }

  // Single rule without filter → singleSymbol.
  if (rules.length == 1 && rules.first.filter == null) {
    final symbols = <String, qml.QmlSymbol>{};
    symbols['0'] = _buildSymbol(rules.first.symbolizers, warnings);
    return qml.QmlRenderer(
      type: qml.QmlRendererType.singleSymbol,
      symbols: symbols,
    );
  }

  // Multiple rules → RuleRenderer (most general).
  final symbols = <String, qml.QmlSymbol>{};
  final qmlRules = <qml.QmlRule>[];

  for (var i = 0; i < rules.length; i++) {
    final rule = rules[i];
    final key = '$i';
    symbols[key] = _buildSymbol(rule.symbolizers, warnings);

    qmlRules.add(qml.QmlRule(
      key: 'rule_$i',
      symbolKey: key,
      label: rule.name,
      filter: _buildFilterString(rule.filter),
      scaleMinDenominator: rule.scaleDenominator?.min,
      scaleMaxDenominator: rule.scaleDenominator?.max,
    ));
  }

  return qml.QmlRenderer(
    type: qml.QmlRendererType.ruleRenderer,
    symbols: symbols,
    rules: qmlRules,
  );
}

// ---------------------------------------------------------------------------
// Symbolizers → QmlSymbol
// ---------------------------------------------------------------------------

qml.QmlSymbol _buildSymbol(
  List<ms.Symbolizer> symbolizers,
  List<String> warnings,
) {
  if (symbolizers.isEmpty) {
    return const qml.QmlSymbol(type: qml.QmlSymbolType.fill);
  }

  // Determine symbol type from first symbolizer.
  final symType = switch (symbolizers.first) {
    ms.FillSymbolizer() => qml.QmlSymbolType.fill,
    ms.LineSymbolizer() => qml.QmlSymbolType.line,
    ms.MarkSymbolizer() => qml.QmlSymbolType.marker,
    ms.IconSymbolizer() => qml.QmlSymbolType.marker,
    ms.TextSymbolizer() => qml.QmlSymbolType.marker,
    ms.RasterSymbolizer() => qml.QmlSymbolType.fill,
  };

  final layers = <qml.QmlSymbolLayer>[];
  for (final sym in symbolizers) {
    final layer = _buildSymbolLayer(sym, warnings);
    if (layer != null) layers.add(layer);
  }

  return qml.QmlSymbol(type: symType, layers: layers);
}

qml.QmlSymbolLayer? _buildSymbolLayer(
  ms.Symbolizer sym,
  List<String> warnings,
) {
  return switch (sym) {
    ms.FillSymbolizer() => _buildFillLayer(sym),
    ms.LineSymbolizer() => _buildLineLayer(sym),
    ms.MarkSymbolizer() => _buildMarkerLayer(sym),
    ms.IconSymbolizer() => _buildSvgMarkerLayer(sym),
    ms.TextSymbolizer() => _warnUnsupported('TextSymbolizer', warnings),
    ms.RasterSymbolizer() => _warnUnsupported('RasterSymbolizer', warnings),
  };
}

qml.QmlSymbolLayer _buildFillLayer(ms.FillSymbolizer sym) {
  final opacity = _extractDouble(sym.opacity) ?? _extractDouble(sym.fillOpacity);
  return qml.QmlSymbolLayer(
    type: qml.QmlSymbolLayerType.simpleFill,
    className: 'SimpleFill',
    properties: {
      if (_extractString(sym.color) != null)
        'color': hexToQgisColor(_extractString(sym.color)!, opacity: opacity),
      'style': 'solid',
      if (_extractString(sym.outlineColor) != null)
        'outline_color': hexToQgisColor(_extractString(sym.outlineColor)!),
      'outline_style': 'solid',
      if (_extractDouble(sym.outlineWidth) != null)
        'outline_width': _extractDouble(sym.outlineWidth)!.toString(),
    },
  );
}

qml.QmlSymbolLayer _buildLineLayer(ms.LineSymbolizer sym) {
  final props = <String, String>{};
  final color = _extractString(sym.color);
  final opacity = _extractDouble(sym.opacity);
  if (color != null) {
    props['line_color'] = hexToQgisColor(color, opacity: opacity);
  }
  if (_extractDouble(sym.width) != null) {
    props['line_width'] = _extractDouble(sym.width)!.toString();
  }
  if (sym.cap != null) props['capstyle'] = sym.cap!;
  if (sym.join != null) props['joinstyle'] = sym.join!;
  if (sym.dasharray != null && sym.dasharray!.isNotEmpty) {
    props['customdash'] = sym.dasharray!.join(';');
    props['use_custom_dash'] = '1';
  }

  return qml.QmlSymbolLayer(
    type: qml.QmlSymbolLayerType.simpleLine,
    className: 'SimpleLine',
    properties: props,
  );
}

qml.QmlSymbolLayer _buildMarkerLayer(ms.MarkSymbolizer sym) {
  final props = <String, String>{};
  props['name'] = _mapToQgisShape(sym.wellKnownName);
  final color = _extractString(sym.color);
  final opacity = _extractDouble(sym.opacity);
  if (color != null) {
    props['color'] = hexToQgisColor(color, opacity: opacity);
  }
  final radius = _extractDouble(sym.radius);
  if (radius != null) props['size'] = (radius * 2).toString(); // radius→diameter
  final outlineColor = _extractString(sym.strokeColor);
  if (outlineColor != null) props['outline_color'] = hexToQgisColor(outlineColor);
  if (_extractDouble(sym.strokeWidth) != null) {
    props['outline_width'] = _extractDouble(sym.strokeWidth)!.toString();
  }
  props['outline_style'] = 'solid';
  final angle = _extractDouble(sym.rotate);
  if (angle != null) props['angle'] = angle.toString();

  return qml.QmlSymbolLayer(
    type: qml.QmlSymbolLayerType.simpleMarker,
    className: 'SimpleMarker',
    properties: props,
  );
}

qml.QmlSymbolLayer _buildSvgMarkerLayer(ms.IconSymbolizer sym) {
  final props = <String, String>{};
  final image = _extractString(sym.image);
  if (image != null) props['name'] = image;
  if (_extractDouble(sym.size) != null) {
    props['size'] = _extractDouble(sym.size)!.toString();
  }
  final angle = _extractDouble(sym.rotate);
  if (angle != null) props['angle'] = angle.toString();

  return qml.QmlSymbolLayer(
    type: qml.QmlSymbolLayerType.svgMarker,
    className: 'SvgMarker',
    properties: props,
  );
}

qml.QmlSymbolLayer? _warnUnsupported(String name, List<String> warnings) {
  warnings.add('$name not supported in QML conversion');
  return null;
}

// ---------------------------------------------------------------------------
// Filter → QGIS expression string
// ---------------------------------------------------------------------------

String? _buildFilterString(ms.Filter? filter) {
  if (filter == null) return null;
  return switch (filter) {
    ms.ComparisonFilter(:final operator, :final property, :final value) =>
      '${_exprToString(property)} ${_opToString(operator)} ${_exprToFilterValue(value)}',
    ms.CombinationFilter(:final operator, :final filters) => filters
        .map(_buildFilterString)
        .whereType<String>()
        .join(operator == ms.CombinationOperator.and ? ' AND ' : ' OR '),
    ms.NegationFilter(:final filter) => 'NOT (${_buildFilterString(filter)})',
    ms.SpatialFilter() => null,
    ms.DistanceFilter() => null,
  };
}

String _opToString(ms.ComparisonOperator op) => switch (op) {
      ms.ComparisonOperator.eq => '=',
      ms.ComparisonOperator.neq => '!=',
      ms.ComparisonOperator.lt => '<',
      ms.ComparisonOperator.gt => '>',
      ms.ComparisonOperator.lte => '<=',
      ms.ComparisonOperator.gte => '>=',
    };

String _exprToString(ms.Expression<String> expr) => switch (expr) {
      ms.LiteralExpression(:final value) => value,
      ms.FunctionExpression(:final function) => switch (function) {
          ms.PropertyGet(:final propertyName) => propertyName,
          _ => function.name,
        },
    };

String _exprToFilterValue(ms.Expression<Object> expr) => switch (expr) {
      ms.LiteralExpression(:final value) =>
        value is num ? '$value' : "'$value'",
      ms.FunctionExpression(:final function) => function.name,
    };

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String? _extractString(ms.Expression<String>? expr) => switch (expr) {
      ms.LiteralExpression(:final value) => value,
      _ => null,
    };

double? _extractDouble(ms.Expression<double>? expr) => switch (expr) {
      ms.LiteralExpression(:final value) => value,
      _ => null,
    };

String _mapToQgisShape(String wkn) => switch (wkn) {
      'circle' => 'circle',
      'square' => 'square',
      'diamond' => 'diamond',
      'triangle' => 'triangle',
      'star' => 'star',
      'cross' => 'cross',
      'x' => 'cross2',
      _ => wkn,
    };
