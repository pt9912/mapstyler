import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

import 'color_parser.dart';
import 'expression_evaluator.dart';
import 'feature.dart';
import 'filter_evaluator.dart';
import 'geometry_ops.dart';
import 'mark_painter.dart';

/// Selects rules whose [ScaleDenominator] includes the given value.
List<Rule> selectRulesAtScale(Style style, double scaleDenominator) =>
    StyleRenderer.selectRulesAtScale(style, scaleDenominator);

/// Converts `mapstyler_style` objects into `flutter_map` layer widgets.
///
/// The renderer preserves rule order, evaluates filters and expressions against
/// [StyledFeature] input, and optionally wires tap and long-press callbacks
/// back to the originating feature.
class StyleRenderer {
  /// Creates a stateless renderer instance.
  const StyleRenderer();

  // Rule selection is pure for a given style and scale, so it can be reused
  // across render passes without touching feature data.
  static final Expando<Map<double, List<Rule>>> _scaleRuleCache =
      Expando<Map<double, List<Rule>>>('flutter_mapstyler.scaleRules');
  // Prepared evaluators and stable per-feature results live with the style.
  static final Expando<_CompiledStyleCache> _compiledStyleCache =
      Expando<_CompiledStyleCache>('flutter_mapstyler.compiledStyleCache');

  /// Renders a complete [Style] against the given [features].
  ///
  /// Returns an ordered list of flutter_map layer widgets. When
  /// [scaleDenominator] is set, only scale-matching rules are rendered.
  /// Callbacks are attached to rendered features when supported by the
  /// generated layer type. When [viewport] is set, only features whose
  /// geometries intersect the current view bounds are rendered.
  List<Widget> renderStyle({
    required Style style,
    required StyledFeatureCollection features,
    double? scaleDenominator,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    final session = _RenderSession(
      style: style,
      compiledStyleCache: _compiledStyleCache[style] ??= _CompiledStyleCache(),
      scaleDenominator: scaleDenominator,
      viewport: viewport,
    );

    final rules = scaleDenominator != null
        ? _selectRulesAtScaleCached(style, scaleDenominator)
        : style.rules;

    final layers = <Widget>[];
    for (final rule in rules) {
      layers.addAll(_renderRule(
        rule: rule,
        features: features.features,
        session: session,
        onFeatureTap: onFeatureTap,
        onFeatureLongPress: onFeatureLongPress,
      ));
    }
    return layers;
  }

  /// Renders a single [Rule] against the given [features].
  ///
  /// This is useful for tests or custom pipelines that already selected the
  /// rule externally. Unlike [renderStyle], this path does not attach the
  /// rule to a style-wide cache unless it is called from [renderStyle].
  List<Widget> renderRule({
    required Rule rule,
    required List<StyledFeature> features,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    return _renderRule(
      rule: rule,
      features: features,
      session: _RenderSession(
        style: null,
        scaleDenominator: null,
        viewport: viewport,
      ),
      onFeatureTap: onFeatureTap,
      onFeatureLongPress: onFeatureLongPress,
    );
  }

  List<Widget> _renderRule({
    required Rule rule,
    required List<StyledFeature> features,
    required _RenderSession session,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    final matching = session.featuresForRule(rule, session.featuresForViewport(features));
    if (matching.isEmpty) return const [];

    final layers = <Widget>[];
    for (final symbolizer in rule.symbolizers) {
      final layer = _symbolizerToLayer(
        symbolizer: symbolizer,
        features: matching,
        session: session,
        onFeatureTap: onFeatureTap,
        onFeatureLongPress: onFeatureLongPress,
      );
      if (layer != null) layers.add(layer);
    }
    return layers;
  }

  /// Converts a single [Symbolizer] into a flutter_map layer widget.
  ///
  /// Useful for custom rendering pipelines that do not operate on a full
  /// [Style] object. When [viewport] is provided, the input feature set is
  /// prefiltered before symbolizer-specific rendering begins.
  Widget? symbolizerToLayer({
    required Symbolizer symbolizer,
    required List<StyledFeature> features,
    LatLngBounds? viewport,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    final session = _RenderSession(
      style: null,
      scaleDenominator: null,
      viewport: viewport,
    );
    return _symbolizerToLayer(
      symbolizer: symbolizer,
      features: session.featuresForViewport(features),
      session: session,
      onFeatureTap: onFeatureTap,
      onFeatureLongPress: onFeatureLongPress,
    );
  }

  Widget? _symbolizerToLayer({
    required Symbolizer symbolizer,
    required List<StyledFeature> features,
    required _RenderSession session,
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    return switch (symbolizer) {
      FillSymbolizer() => _renderFill(
          symbolizer,
          features,
          session,
          onFeatureTap: onFeatureTap,
          onFeatureLongPress: onFeatureLongPress,
        ),
      LineSymbolizer() => _renderLine(
          symbolizer,
          features,
          session,
          onFeatureTap: onFeatureTap,
          onFeatureLongPress: onFeatureLongPress,
        ),
      MarkSymbolizer() => _renderMark(
          symbolizer,
          features,
          session,
          onFeatureTap: onFeatureTap,
          onFeatureLongPress: onFeatureLongPress,
        ),
      IconSymbolizer() => _renderIcon(
          symbolizer,
          features,
          session,
          onFeatureTap: onFeatureTap,
          onFeatureLongPress: onFeatureLongPress,
        ),
      TextSymbolizer() => _renderText(
          symbolizer,
          features,
          session,
          onFeatureTap: onFeatureTap,
          onFeatureLongPress: onFeatureLongPress,
        ),
      RasterSymbolizer() => _renderRaster(symbolizer, features, session),
    };
  }

  /// Selects rules whose [ScaleDenominator] includes the given value.
  static List<Rule> selectRulesAtScale(Style style, double scaleDenominator) {
    return style.rules.where((rule) {
      final sd = rule.scaleDenominator;
      if (sd == null) return true;
      if (sd.min != null && scaleDenominator < sd.min!) return false;
      if (sd.max != null && scaleDenominator > sd.max!) return false;
      return true;
    }).toList(growable: false);
  }

  List<Rule> _selectRulesAtScaleCached(Style style, double scaleDenominator) {
    final cache = _scaleRuleCache[style] ??= <double, List<Rule>>{};
    return cache.putIfAbsent(
      scaleDenominator,
      () => StyleRenderer.selectRulesAtScale(style, scaleDenominator),
    );
  }

  static LatLng _toLatLng(PointGeometry point) => LatLng(point.y, point.x);

  static List<LatLng> _coordsToLatLng(List<(double, double)> coords) =>
      coords.map((coord) => LatLng(coord.$2, coord.$1)).toList(growable: false);

  Widget? _renderFill(
    FillSymbolizer sym,
    List<StyledFeature> features,
    _RenderSession session, {
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    final polygons = <Polygon<StyledFeature>>[];
    for (final feature in session.featuresForGeometry<PolygonGeometry>(features)) {
      final geom = feature.geometry as PolygonGeometry;
      final colorStr = session.evaluate(sym.color, feature) ?? '#cccccc';
      final opacity = _opacity(
        session.evaluate(sym.opacity, feature),
        session.evaluate(sym.fillOpacity, feature),
      );
      final outlineColorStr = session.evaluate(sym.outlineColor, feature);
      final outlineWidth = session.evaluate(sym.outlineWidth, feature) ?? 0.0;

      polygons.add(
        Polygon<StyledFeature>(
          points: _coordsToLatLng(geom.rings.first),
          holePointsList: geom.rings.length > 1
              ? geom.rings
                  .skip(1)
                  .map(_coordsToLatLng)
                  .toList(growable: false)
              : null,
          color: parseHexColor(colorStr, opacity: opacity),
          borderColor: outlineColorStr != null
              ? parseHexColor(outlineColorStr)
              : const Color(0x00000000),
          borderStrokeWidth: outlineWidth,
          hitValue: feature,
        ),
      );
    }

    if (polygons.isEmpty) return null;

    final layer = PolygonLayer<StyledFeature>(
      polygons: polygons,
      hitNotifier: onFeatureTap != null || onFeatureLongPress != null
          ? ValueNotifier<LayerHitResult<StyledFeature>?>(null)
          : null,
    );

    return _wrapGeometryLayerInteractions(
      child: layer,
      hitNotifier: layer.hitNotifier,
      features: polygons.map((polygon) => polygon.hitValue).whereType<StyledFeature>().toList(),
      onFeatureTap: onFeatureTap,
      onFeatureLongPress: onFeatureLongPress,
      geometrySelector: (feature) => feature.geometry,
    );
  }

  Widget? _renderLine(
    LineSymbolizer sym,
    List<StyledFeature> features,
    _RenderSession session, {
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    final polylines = <Polyline<StyledFeature>>[];
    for (final feature in session.featuresForGeometry<LineStringGeometry>(features)) {
      final geom = feature.geometry as LineStringGeometry;
      final colorStr = session.evaluate(sym.color, feature) ?? '#333333';
      final opacity = _opacity(session.evaluate(sym.opacity, feature));
      final width = session.evaluate(sym.width, feature) ?? 1.0;

      polylines.add(
        Polyline<StyledFeature>(
          points: _coordsToLatLng(geom.coordinates),
          color: parseHexColor(colorStr, opacity: opacity),
          strokeWidth: width,
          pattern: _strokePattern(sym.dasharray),
          strokeCap: _strokeCap(sym.cap),
          strokeJoin: _strokeJoin(sym.join),
          hitValue: feature,
        ),
      );
    }

    if (polylines.isEmpty) return null;

    final layer = PolylineLayer<StyledFeature>(
      polylines: polylines,
      hitNotifier: onFeatureTap != null || onFeatureLongPress != null
          ? ValueNotifier<LayerHitResult<StyledFeature>?>(null)
          : null,
    );

    return _wrapGeometryLayerInteractions(
      child: layer,
      hitNotifier: layer.hitNotifier,
      features: polylines.map((line) => line.hitValue).whereType<StyledFeature>().toList(),
      onFeatureTap: onFeatureTap,
      onFeatureLongPress: onFeatureLongPress,
      geometrySelector: (feature) => feature.geometry,
    );
  }

  Widget? _renderMark(
    MarkSymbolizer sym,
    List<StyledFeature> features,
    _RenderSession session, {
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    final markers = <Marker>[];
    for (final feature in session.featuresForGeometry<PointGeometry>(features)) {
      final geom = feature.geometry as PointGeometry;
      final radius = session.evaluate(sym.radius, feature) ?? 6.0;
      final colorStr = session.evaluate(sym.color, feature) ?? '#ff0000';
      final opacity = _opacity(session.evaluate(sym.opacity, feature));
      final strokeColorStr = session.evaluate(sym.strokeColor, feature);
      final strokeWidth = session.evaluate(sym.strokeWidth, feature) ?? 0.0;
      final angle = session.evaluate(sym.rotate, feature) ?? 0.0;
      final size = radius * 2;

      Widget child = CustomPaint(
        size: Size(size, size),
        painter: MarkPainter(
          wellKnownName: sym.wellKnownName,
          color: parseHexColor(colorStr, opacity: opacity),
          strokeColor:
              strokeColorStr != null ? parseHexColor(strokeColorStr) : null,
          strokeWidth: strokeWidth,
        ),
      );

      if (angle != 0.0) {
        child = Transform.rotate(
          angle: _degreesToRadians(angle),
          child: child,
        );
      }

      markers.add(
        Marker(
          point: _toLatLng(geom),
          width: size,
          height: size,
          child: _wrapMarkerInteractions(
            feature: feature,
            onFeatureTap: onFeatureTap,
            onFeatureLongPress: onFeatureLongPress,
            child: child,
          ),
        ),
      );
    }

    if (markers.isEmpty) return null;
    return MarkerLayer(markers: markers);
  }

  Widget? _renderIcon(
    IconSymbolizer sym,
    List<StyledFeature> features,
    _RenderSession session, {
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    final markers = <Marker>[];
    for (final feature in session.featuresForGeometry<PointGeometry>(features)) {
      final geom = feature.geometry as PointGeometry;
      final imagePath = session.evaluate(sym.image, feature) ?? '';
      if (imagePath.isEmpty) continue;

      final size = session.evaluate(sym.size, feature) ?? 24.0;
      final opacity = _opacity(session.evaluate(sym.opacity, feature));
      final angle = session.evaluate(sym.rotate, feature) ?? 0.0;
      final imageProvider = _resolveImageProvider(imagePath);

      Widget child = Opacity(
        opacity: opacity,
        child: imageProvider == null
            ? SizedBox(width: size, height: size)
            : Image(
                image: imageProvider,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
              ),
      );

      if (angle != 0.0) {
        child = Transform.rotate(
          angle: _degreesToRadians(angle),
          child: child,
        );
      }

      markers.add(
        Marker(
          point: _toLatLng(geom),
          width: size,
          height: size,
          child: _wrapMarkerInteractions(
            feature: feature,
            onFeatureTap: onFeatureTap,
            onFeatureLongPress: onFeatureLongPress,
            child: child,
          ),
        ),
      );
    }

    if (markers.isEmpty) return null;
    return MarkerLayer(markers: markers);
  }

  Widget? _renderText(
    TextSymbolizer sym,
    List<StyledFeature> features,
    _RenderSession session, {
    FeatureTapCallback? onFeatureTap,
    FeatureLongPressCallback? onFeatureLongPress,
  }) {
    final markers = <Marker>[];
    for (final feature in features) {
      final anchor = _textAnchorForFeature(feature);
      if (anchor == null) continue;

      final label = session.evaluate(sym.label, feature) ?? '';
      if (label.isEmpty) continue;

      final colorStr = session.evaluate(sym.color, feature) ?? '#333333';
      final size = session.evaluate(sym.size, feature) ?? 12.0;
      final opacity = _opacity(session.evaluate(sym.opacity, feature));
      final angle = session.evaluate(sym.rotate, feature) ?? 0.0;
      final haloColorStr = session.evaluate(sym.haloColor, feature);
      final haloWidth = session.evaluate(sym.haloWidth, feature) ?? 0.0;

      final textStyle = TextStyle(
        color: parseHexColor(colorStr, opacity: opacity),
        fontSize: size,
        fontFamily: sym.font,
        shadows: haloWidth > 0 && haloColorStr != null
            ? [
                Shadow(
                  color: parseHexColor(haloColorStr, opacity: opacity),
                  blurRadius: haloWidth,
                ),
              ]
            : null,
      );

      Widget child = Text(
        label,
        style: textStyle,
        textAlign: TextAlign.center,
      );

      if (angle != 0.0) {
        child = Transform.rotate(
          angle: _degreesToRadians(angle),
          child: child,
        );
      }

      markers.add(
        Marker(
          point: LatLng(anchor.latitude, anchor.longitude),
          width: math.max(label.length * size * 0.7, size),
          height: size * 1.6,
          child: _wrapMarkerInteractions(
            feature: feature,
            onFeatureTap: onFeatureTap,
            onFeatureLongPress: onFeatureLongPress,
            child: child,
          ),
        ),
      );
    }

    if (markers.isEmpty) return null;
    return MarkerLayer(markers: markers);
  }

  Widget? _renderRaster(
    RasterSymbolizer sym,
    List<StyledFeature> features,
    _RenderSession session,
  ) {
    // Tile-based rasters are modeled as features carrying a URL template.
    final tileFeature = features.cast<StyledFeature?>().firstWhere(
          (feature) => feature?.properties['urlTemplate'] is String,
          orElse: () => null,
        );
    if (tileFeature != null) {
      final props = tileFeature.properties;
      final layer = TileLayer(
        urlTemplate: props['urlTemplate'] as String,
        fallbackUrl: props['fallbackUrl'] as String?,
        additionalOptions: _stringMap(props['additionalOptions']),
        subdomains: _stringList(props['subdomains']) ?? const ['a', 'b', 'c'],
        tms: props['tms'] == true,
        minZoom: _toDouble(props['minZoom']) ?? 0,
        maxZoom: _toDouble(props['maxZoom']) ?? double.infinity,
        minNativeZoom: _toInt(props['minNativeZoom']) ?? 0,
        maxNativeZoom: _toInt(props['maxNativeZoom']) ?? 19,
      );
      return _applyRasterEffects(
        child: layer,
        feature: tileFeature,
        sym: sym,
        session: session,
      );
    }

    // Image overlays are modeled as envelope geometries with a source path.
    final overlays = <BaseOverlayImage>[];
    for (final feature in features) {
      if (feature.geometry is! EnvelopeGeometry) continue;
      final imagePath = feature.properties['image'] ??
          feature.properties['url'] ??
          feature.properties['asset'];
      if (imagePath is! String || imagePath.isEmpty) continue;

      final provider = _resolveImageProvider(imagePath);
      if (provider == null) continue;

      final bounds = feature.geometry as EnvelopeGeometry;
      overlays.add(
        OverlayImage(
          bounds: LatLngBounds(
            LatLng(bounds.maxY, bounds.minX),
            LatLng(bounds.minY, bounds.maxX),
          ),
          imageProvider: provider,
          opacity: _opacity(session.evaluate(sym.opacity, feature)),
        ),
      );
    }

    if (overlays.isEmpty) return null;

    return _applyRasterEffects(
      child: OverlayImageLayer(overlayImages: overlays),
      feature: features.isEmpty ? null : features.first,
      sym: sym,
      session: session,
    );
  }

  Widget _applyRasterEffects({
    required Widget child,
    required RasterSymbolizer sym,
    required _RenderSession session,
    StyledFeature? feature,
  }) {
    final opacity = feature != null ? _opacity(session.evaluate(sym.opacity, feature)) : 1.0;
    Widget current = opacity < 1 ? Opacity(opacity: opacity, child: child) : child;

    // Raster color adjustments are composed into a single matrix to avoid
    // stacking multiple ColorFiltered widgets.
    final filter = _rasterColorFilter(sym, feature, session);
    if (filter != null) {
      current = ColorFiltered(colorFilter: filter, child: current);
    }
    return current;
  }

  ColorFilter? _rasterColorFilter(
    RasterSymbolizer sym,
    StyledFeature? feature,
    _RenderSession session,
  ) {
    final saturation =
        feature != null ? session.evaluate(sym.saturation, feature) : null;
    final contrast =
        feature != null ? session.evaluate(sym.contrast, feature) : null;
    final hueRotate =
        feature != null ? session.evaluate(sym.hueRotate, feature) : null;
    final brightnessMin =
        feature != null ? session.evaluate(sym.brightnessMin, feature) : null;
    final brightnessMax =
        feature != null ? session.evaluate(sym.brightnessMax, feature) : null;

    final matrix = _composeColorMatrix(
      saturation: saturation,
      contrast: contrast,
      hueRotate: hueRotate,
      brightnessMin: brightnessMin,
      brightnessMax: brightnessMax,
    );
    return matrix == null ? null : ColorFilter.matrix(matrix);
  }

  LatLngLike? _textAnchorForFeature(StyledFeature feature) => switch (feature.geometry) {
        PointGeometry() => LatLngLike(
            (feature.geometry as PointGeometry).y,
            (feature.geometry as PointGeometry).x,
          ),
        LineStringGeometry() => pointOnLineAtMidpoint(
            feature.geometry as LineStringGeometry,
          ),
        PolygonGeometry() => centroidOfPolygon(feature.geometry as PolygonGeometry),
        EnvelopeGeometry() => LatLngLike(
            ((feature.geometry as EnvelopeGeometry).minY +
                    (feature.geometry as EnvelopeGeometry).maxY) /
                2,
            ((feature.geometry as EnvelopeGeometry).minX +
                    (feature.geometry as EnvelopeGeometry).maxX) /
                2,
          ),
      };
}

class _RenderSession {
  /// Captures per-render caches plus optional style-wide prepared evaluators.
  _RenderSession({
    required this.style,
    this.compiledStyleCache,
    this.scaleDenominator,
    this.viewport,
  });

  final Style? style;
  final _CompiledStyleCache? compiledStyleCache;
  final double? scaleDenominator;
  final LatLngBounds? viewport;
  final Map<(Rule, int), List<StyledFeature>> _ruleFeatureCache = {};
  final Map<(int, int), List<StyledFeature>> _viewportFeatureCache = {};
  final Map<(Type, int), List<StyledFeature>> _geometryBuckets = {};
  final Map<(Object, int, int, int), Object?> _expressionCache = {};
  final Map<Object, Function> _compiledExpressions = {};
  final Map<Rule, CompiledFilterEvaluator> _compiledFilters = {};

  /// Returns only those features whose geometry envelopes intersect the view.
  List<StyledFeature> featuresForViewport(List<StyledFeature> features) {
    final viewportEnvelope = _viewportEnvelope;
    if (viewportEnvelope == null) return features;
    final key = (
      identityHashCode(features),
      viewport.hashCode,
    );
    return _viewportFeatureCache.putIfAbsent(key, () {
      return features
          .where(
            (feature) => _geometryIntersectsViewport(
              feature.geometry,
              viewportEnvelope,
            ),
          )
          .toList(growable: false);
    });
  }

  /// Returns the subset of [features] whose rule filter matches.
  List<StyledFeature> featuresForRule(Rule rule, List<StyledFeature> features) {
    return _ruleFeatureCache.putIfAbsent((rule, identityHashCode(features)), () {
      final evaluator = _compiledStyleFilter(rule);
      return features
          .where(
            (feature) => evaluator(
              feature.properties,
              geometry: feature.geometry,
            ),
          )
          .toList(growable: false);
    });
  }

  /// Buckets features by geometry type to avoid repeated `is T` scans.
  List<StyledFeature> featuresForGeometry<T extends Geometry>(
    List<StyledFeature> features,
  ) {
    return _geometryBuckets.putIfAbsent((T, identityHashCode(features)), () {
      return features.where((feature) => feature.geometry is T).toList(growable: false);
    });
  }

  /// Evaluates [expression] for [feature] with short-lived or persistent cache.
  T? evaluate<T>(Expression<T>? expression, StyledFeature feature) {
    if (expression == null) return null;
    final evaluator = _compiledExpression<T>(expression);
    if (!_isCacheableExpression(expression)) {
      return evaluator(feature.properties);
    }

    final featureId = feature.id;
    final key = (
      featureId ?? identityHashCode(feature),
      identityHashCode(expression),
      _propertySignature(feature.properties),
      _scaleBucket(scaleDenominator),
    );

    if (featureId == null) {
      final cached = _expressionCache[key];
      if (cached is T) return cached;
      if (_expressionCache.containsKey(key) && cached == null) return null;
      final result = evaluator(feature.properties);
      _expressionCache[key] = result;
      return result;
    }

    // Expression results are cached only for stable feature ids.
    final persistentCache = compiledStyleCache?.expressionResultCache;
    final cached = persistentCache?[key] ?? _expressionCache[key];
    if (cached is T) return cached;
    if ((persistentCache?.containsKey(key) ?? false) ||
        _expressionCache.containsKey(key) && cached == null) {
      return null;
    }

    final result = evaluator(feature.properties);
    if (persistentCache != null) {
      persistentCache[key] = result;
    } else {
      _expressionCache[key] = result;
    }
    return result;
  }

  /// Reuses compiled expression closures either per-style or per render pass.
  CompiledExpressionEvaluator<T> _compiledExpression<T>(Expression<T> expression) {
    final compiled = compiledStyleCache?.expressionEvaluators.putIfAbsent(
          expression,
          () => compileExpressionEvaluator(expression),
        ) ??
        _compiledExpressions.putIfAbsent(
          expression,
          () => compileExpressionEvaluator(expression),
        );
    return compiled as CompiledExpressionEvaluator<T>;
  }

  /// Reuses a compiled filter evaluator for the rule.
  CompiledFilterEvaluator _compiledStyleFilter(Rule rule) {
    return compiledStyleCache?.filterEvaluators.putIfAbsent(
          rule,
          () => compileFilterEvaluator(rule.filter),
        ) ??
        _compiledFilters.putIfAbsent(
          rule,
          () => compileFilterEvaluator(rule.filter),
        );
  }

  /// Converts the current [viewport] into the package geometry envelope model.
  EnvelopeGeometry? get _viewportEnvelope => viewport == null
      ? null
      : EnvelopeGeometry(
          minX: viewport!.west,
          minY: viewport!.south,
          maxX: viewport!.east,
          maxY: viewport!.north,
        );
}

/// Style-scoped caches reused across independent render passes.
class _CompiledStyleCache {
  final Map<Object, Function> expressionEvaluators = {};
  final Map<Rule, CompiledFilterEvaluator> filterEvaluators = {};
  final Map<(Object, int, int, int), Object?> expressionResultCache = {};
}

/// Adds gesture handling to geometry layers that do not expose per-feature
/// callbacks directly.
class _GeometryLayerInteractionBridge extends StatefulWidget {
  const _GeometryLayerInteractionBridge({
    required this.child,
    required this.features,
    required this.geometrySelector,
    this.hitNotifier,
    this.onFeatureTap,
    this.onFeatureLongPress,
  });

  final Widget child;
  final LayerHitNotifier<StyledFeature>? hitNotifier;
  final List<StyledFeature> features;
  final Geometry Function(StyledFeature feature) geometrySelector;
  final FeatureTapCallback? onFeatureTap;
  final FeatureLongPressCallback? onFeatureLongPress;

  @override
  State<_GeometryLayerInteractionBridge> createState() =>
      _GeometryLayerInteractionBridgeState();
}

/// Tracks the current hit result and falls back to manual geometry hit testing.
class _GeometryLayerInteractionBridgeState
    extends State<_GeometryLayerInteractionBridge> {
  StyledFeature? _currentHit;

  @override
  void initState() {
    super.initState();
    widget.hitNotifier?.addListener(_onHitChanged);
  }

  @override
  void didUpdateWidget(_GeometryLayerInteractionBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hitNotifier != widget.hitNotifier) {
      oldWidget.hitNotifier?.removeListener(_onHitChanged);
      widget.hitNotifier?.addListener(_onHitChanged);
    }
  }

  @override
  void dispose() {
    widget.hitNotifier?.removeListener(_onHitChanged);
    super.dispose();
  }

  void _onHitChanged() {
    final result = widget.hitNotifier?.value;
    setState(() {
      _currentHit = result?.hitValues.firstOrNull;
    });
  }

  StyledFeature? _hitTestAt(Offset localPosition) {
    final mapState = MapCamera.maybeOf(context);
    if (mapState == null) return _currentHit;

    // Polygon hit testing can use geographic containment directly. Lines need
    // a pixel-space tolerance to remain tappable across zoom levels.
    final coordinate = mapState.pointToLatLng(
      math.Point<double>(localPosition.dx, localPosition.dy),
    );
    final point = PointGeometry(coordinate.longitude, coordinate.latitude);
    for (final feature in widget.features.reversed) {
      final geometry = widget.geometrySelector(feature);
      if (geometry is LineStringGeometry &&
          _lineHitTest(localPosition, mapState, geometry)) {
        return feature;
      }
      if (pointInGeometry(point, geometry)) {
        return feature;
      }
    }
    return _currentHit;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onFeatureTap == null && widget.onFeatureLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: widget.onFeatureTap == null
          ? null
          : (details) {
              final hit = _hitTestAt(details.localPosition);
              if (hit != null) widget.onFeatureTap!(hit);
            },
      onLongPressStart: widget.onFeatureLongPress == null
          ? null
          : (details) {
              final box = context.findRenderObject() as RenderBox?;
              final local = box?.globalToLocal(details.globalPosition) ??
                  details.localPosition;
              final hit = _hitTestAt(local);
              if (hit != null) widget.onFeatureLongPress!(hit);
            },
      child: widget.child,
    );
  }
}

/// Wraps polygon and polyline layers with optional interaction support.
Widget _wrapGeometryLayerInteractions({
  required Widget child,
  required List<StyledFeature> features,
  required Geometry Function(StyledFeature feature) geometrySelector,
  LayerHitNotifier<StyledFeature>? hitNotifier,
  FeatureTapCallback? onFeatureTap,
  FeatureLongPressCallback? onFeatureLongPress,
}) {
  if (onFeatureTap == null && onFeatureLongPress == null) return child;
  return _GeometryLayerInteractionBridge(
    child: child,
    hitNotifier: hitNotifier,
    features: features,
    geometrySelector: geometrySelector,
    onFeatureTap: onFeatureTap,
    onFeatureLongPress: onFeatureLongPress,
  );
}

/// Wraps marker children with optional tap and long-press callbacks.
Widget _wrapMarkerInteractions({
  required StyledFeature feature,
  required Widget child,
  FeatureTapCallback? onFeatureTap,
  FeatureLongPressCallback? onFeatureLongPress,
}) {
  if (onFeatureTap == null && onFeatureLongPress == null) return child;
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onFeatureTap == null ? null : () => onFeatureTap(feature),
    onLongPress:
        onFeatureLongPress == null ? null : () => onFeatureLongPress(feature),
    child: child,
  );
}

/// Converts a GeoStyler dash array into the nearest `flutter_map` stroke pattern.
StrokePattern _strokePattern(List<double>? dasharray) {
  if (dasharray == null || dasharray.isEmpty) {
    return const StrokePattern.solid();
  }
  if (dasharray.length == 1) {
    return StrokePattern.dotted(spacingFactor: math.max(dasharray.first, 0.1));
  }
  final normalized = dasharray
      .map((value) => value <= 0 ? 1.0 : value)
      .toList(growable: true);
  if (normalized.length.isOdd) normalized.add(normalized.last);
  return StrokePattern.dashed(segments: normalized);
}

/// Maps GeoStyler line-cap values onto Flutter's [StrokeCap].
StrokeCap _strokeCap(String? value) => switch (value) {
      'butt' => StrokeCap.butt,
      'square' => StrokeCap.square,
      _ => StrokeCap.round,
    };

/// Maps GeoStyler line-join values onto Flutter's [StrokeJoin].
StrokeJoin _strokeJoin(String? value) => switch (value) {
      'bevel' => StrokeJoin.bevel,
      'miter' => StrokeJoin.miter,
      _ => StrokeJoin.round,
    };

/// Combines one or two opacity values while clamping them to `[0, 1]`.
double _opacity(double? opacity, [double? secondary]) {
  final primary = (opacity ?? 1.0).clamp(0.0, 1.0);
  final other = (secondary ?? 1.0).clamp(0.0, 1.0);
  return (primary * other).clamp(0.0, 1.0);
}

/// Converts degrees to radians for Flutter rotation APIs.
double _degreesToRadians(double degrees) => degrees * math.pi / 180;

/// Resolves asset, file, and network paths into an [ImageProvider].
ImageProvider<Object>? _resolveImageProvider(String path) {
  final uri = Uri.tryParse(path);
  final scheme = uri?.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') return NetworkImage(path);
  if (scheme == 'file' && uri != null) return FileImage(File.fromUri(uri));
  if (path.startsWith('/')) return FileImage(File(path));
  if (path.startsWith('asset:')) {
    return AssetImage(path.substring('asset:'.length));
  }
  return AssetImage(path);
}

/// Converts loose map values into the string map expected by [TileLayer].
Map<String, String> _stringMap(Object? value) {
  if (value is Map<String, String>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry('$key', '$entry'));
  }
  return const {};
}

/// Converts loose list values into a string list.
List<String>? _stringList(Object? value) {
  if (value is List<String>) return value;
  if (value is List) return value.map((item) => '$item').toList(growable: false);
  return null;
}

/// Parses numeric values coming from feature properties.
double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Parses integer values coming from feature properties.
int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Builds a single Flutter color matrix from supported raster adjustments.
List<double>? _composeColorMatrix({
  double? saturation,
  double? contrast,
  double? hueRotate,
  double? brightnessMin,
  double? brightnessMax,
}) {
  List<double>? matrix;

  void apply(List<double> next) {
    matrix = matrix == null ? next : _multiplyColorMatrices(matrix!, next);
  }

  if (saturation != null && saturation != 1.0) {
    final s = saturation;
    const luminanceR = 0.213;
    const luminanceG = 0.715;
    const luminanceB = 0.072;
    apply([
      luminanceR * (1 - s) + s,
      luminanceG * (1 - s),
      luminanceB * (1 - s),
      0,
      0,
      luminanceR * (1 - s),
      luminanceG * (1 - s) + s,
      luminanceB * (1 - s),
      0,
      0,
      luminanceR * (1 - s),
      luminanceG * (1 - s),
      luminanceB * (1 - s) + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  if (contrast != null && contrast != 1.0) {
    final c = contrast;
    final translate = (1 - c) * 128;
    apply([
      c,
      0,
      0,
      0,
      translate,
      0,
      c,
      0,
      0,
      translate,
      0,
      0,
      c,
      0,
      translate,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  if (hueRotate != null && hueRotate != 0.0) {
    final radians = _degreesToRadians(hueRotate);
    final cosHue = math.cos(radians);
    final sinHue = math.sin(radians);
    apply([
      0.213 + cosHue * 0.787 - sinHue * 0.213,
      0.715 - cosHue * 0.715 - sinHue * 0.715,
      0.072 - cosHue * 0.072 + sinHue * 0.928,
      0,
      0,
      0.213 - cosHue * 0.213 + sinHue * 0.143,
      0.715 + cosHue * 0.285 + sinHue * 0.140,
      0.072 - cosHue * 0.072 - sinHue * 0.283,
      0,
      0,
      0.213 - cosHue * 0.213 - sinHue * 0.787,
      0.715 - cosHue * 0.715 + sinHue * 0.715,
      0.072 + cosHue * 0.928 + sinHue * 0.072,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  if (brightnessMin != null || brightnessMax != null) {
    final min = (brightnessMin ?? 0.0).clamp(0.0, 1.0);
    final max = (brightnessMax ?? 1.0).clamp(min, 1.0);
    final scale = max - min;
    apply([
      scale,
      0,
      0,
      0,
      min * 255,
      0,
      scale,
      0,
      0,
      min * 255,
      0,
      0,
      scale,
      0,
      min * 255,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  return matrix;
}

List<double> _multiplyColorMatrices(List<double> a, List<double> b) {
  final result = List<double>.filled(20, 0);
  for (var row = 0; row < 4; row++) {
    for (var col = 0; col < 5; col++) {
      result[row * 5 + col] =
          a[row * 5] * b[col] +
              a[row * 5 + 1] * b[5 + col] +
              a[row * 5 + 2] * b[10 + col] +
              a[row * 5 + 3] * b[15 + col] +
              (col == 4 ? a[row * 5 + 4] : 0);
    }
  }
  return result;
}

/// Uses a fixed pixel tolerance so thin lines remain tappable while zooming.
bool _lineHitTest(
  Offset localPosition,
  MapCamera camera,
  LineStringGeometry geometry,
) {
  const tolerance = 10.0;
  final points = geometry.coordinates
      .map((coord) => camera.getOffsetFromOrigin(LatLng(coord.$2, coord.$1)))
      .toList(growable: false);
  for (var i = 0; i < points.length - 1; i++) {
    if (_distanceToSegment(localPosition, points[i], points[i + 1]) <= tolerance) {
      return true;
    }
  }
  return false;
}

double _distanceToSegment(Offset point, Offset a, Offset b) {
  final dx = b.dx - a.dx;
  final dy = b.dy - a.dy;
  if (dx == 0 && dy == 0) return (point - a).distance;

  final t = (((point.dx - a.dx) * dx) + ((point.dy - a.dy) * dy)) /
      ((dx * dx) + (dy * dy));
  final clamped = t.clamp(0.0, 1.0);
  final projection = Offset(a.dx + dx * clamped, a.dy + dy * clamped);
  return (point - projection).distance;
}

/// Viewport culling currently uses geometry envelopes as a fast prefilter.
bool _geometryIntersectsViewport(
  Geometry geometry,
  EnvelopeGeometry viewport,
) {
  final envelope = geometryEnvelope(geometry);
  return envelope.minX <= viewport.maxX &&
      envelope.maxX >= viewport.minX &&
      envelope.minY <= viewport.maxY &&
      envelope.maxY >= viewport.minY;
}

/// Hashes nested property structures so cache invalidation notices deep changes.
int _propertySignature(Map<String, Object?> properties) {
  return Object.hashAllUnordered(
    properties.entries.map(
      (entry) => Object.hash(entry.key, _deepHash(entry.value)),
    ),
  );
}

/// Produces a stable hash for nested maps and iterables.
int _deepHash(Object? value) {
  if (value is Map) {
    return Object.hashAllUnordered(
      value.entries.map((entry) => Object.hash(_deepHash(entry.key), _deepHash(entry.value))),
    );
  }
  if (value is Iterable) {
    return Object.hashAll(value.map(_deepHash));
  }
  return value.hashCode;
}

/// Buckets scale values for cache keys without introducing extra quantization.
int _scaleBucket(double? scaleDenominator) => scaleDenominator?.hashCode ?? 0;

/// Random expressions are excluded so cache reuse does not freeze them.
bool _isCacheableExpression(Expression<dynamic> expression) {
  return switch (expression) {
    LiteralExpression() => true,
    FunctionExpression(:final function) => _isCacheableFunction(function),
  };
}

/// Recursive cacheability check that mirrors the supported expression tree.
bool _isCacheableFunction(GeoStylerFunction function) {
  return switch (function) {
    PropertyGet() => true,
    CaseFunction(:final cases, :final fallback) =>
      cases.every(
            (entry) =>
                _isCacheableExpression(entry.condition) &&
                _isCacheableExpression(entry.value),
          ) &&
          _isCacheableExpression(fallback),
    StepFunction(:final input, :final defaultValue, :final stops) =>
      _isCacheableExpression(input) &&
          _isCacheableExpression(defaultValue) &&
          stops.every(
            (stop) =>
                _isCacheableExpression(stop.boundary) &&
                _isCacheableExpression(stop.value),
          ),
    InterpolateFunction(:final input, :final stops) =>
      _isCacheableExpression(input) &&
          stops.every(
            (stop) =>
                _isCacheableExpression(stop.stop) &&
                _isCacheableExpression(stop.value),
          ),
    ArgsFunction(:final name, :final args) =>
      name != 'random' && args.every(_isCacheableExpression),
  };
}
