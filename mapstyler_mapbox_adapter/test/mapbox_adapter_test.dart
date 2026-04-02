import 'dart:convert';

import 'package:mapstyler_mapbox_adapter/mapstyler_mapbox_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  const adapter = MapboxStyleAdapter();

  // ---------------------------------------------------------------------------
  // Read: fill layer
  // ---------------------------------------------------------------------------
  group('read fill', () {
    test('converts fill layer to FillSymbolizer', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('water', 'fill', paint: {
          'fill-color': '#0000ff',
          'fill-opacity': 0.8,
          'fill-outline-color': '#000080',
        }),
      ])));
      final style = (result as ReadStyleSuccess).output;
      expect(style.rules, hasLength(1));
      final sym = style.rules.first.symbolizers.first as FillSymbolizer;
      expect((sym.color as LiteralExpression<String>).value, '#0000ff');
      expect((sym.opacity as LiteralExpression<double>).value, 0.8);
      expect((sym.outlineColor as LiteralExpression<String>).value, '#000080');
    });
  });

  // ---------------------------------------------------------------------------
  // Read: line layer
  // ---------------------------------------------------------------------------
  group('read line', () {
    test('converts line layer to LineSymbolizer', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('roads', 'line',
            paint: {'line-color': '#333', 'line-width': 2, 'line-opacity': 1.0,
                    'line-dasharray': [10, 5]},
            layout: {'line-cap': 'round', 'line-join': 'bevel'}),
      ])));
      final sym = ((result as ReadStyleSuccess).output.rules.first
          .symbolizers.first) as LineSymbolizer;
      expect((sym.color as LiteralExpression<String>).value, '#333');
      expect((sym.width as LiteralExpression<double>).value, 2.0);
      expect(sym.dasharray, [10.0, 5.0]);
      expect(sym.cap, 'round');
      expect(sym.join, 'bevel');
    });
  });

  // ---------------------------------------------------------------------------
  // Read: circle layer → MarkSymbolizer
  // ---------------------------------------------------------------------------
  group('read circle', () {
    test('converts circle to MarkSymbolizer', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('pois', 'circle', paint: {
          'circle-radius': 5,
          'circle-color': '#ff0000',
          'circle-stroke-color': '#000',
          'circle-stroke-width': 1,
        }),
      ])));
      final sym = ((result as ReadStyleSuccess).output.rules.first
          .symbolizers.first) as MarkSymbolizer;
      expect(sym.wellKnownName, 'circle');
      expect((sym.radius as LiteralExpression<double>).value, 5.0);
      expect((sym.strokeWidth as LiteralExpression<double>).value, 1.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Read: symbol layer → Text + Icon
  // ---------------------------------------------------------------------------
  group('read symbol', () {
    test('text-field produces TextSymbolizer', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('labels', 'symbol',
            layout: {'text-field': ['get', 'name'], 'text-size': 14,
                     'text-font': ['Arial'], 'symbol-placement': 'point'},
            paint: {'text-color': '#333', 'text-halo-color': '#fff',
                    'text-halo-width': 2}),
      ])));
      final sym = ((result as ReadStyleSuccess).output.rules.first
          .symbolizers.first) as TextSymbolizer;
      expect(sym.label, isA<FunctionExpression<String>>());
      expect((sym.size as LiteralExpression<double>).value, 14.0);
      expect(sym.font, 'Arial');
      expect(sym.placement, 'point');
      expect((sym.haloWidth as LiteralExpression<double>).value, 2.0);
    });

    test('icon-image produces IconSymbolizer', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('icons', 'symbol',
            layout: {'icon-image': 'marker', 'icon-size': 1.5,
                     'icon-rotate': 45}),
      ])));
      final sym = ((result as ReadStyleSuccess).output.rules.first
          .symbolizers.first) as IconSymbolizer;
      expect((sym.image as LiteralExpression<String>).value, 'marker');
    });

    test('text + icon produces two symbolizers', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('both', 'symbol',
            layout: {'text-field': 'label', 'icon-image': 'marker'}),
      ])));
      final syms = (result as ReadStyleSuccess).output.rules.first.symbolizers;
      expect(syms, hasLength(2));
      expect(syms[0], isA<TextSymbolizer>());
      expect(syms[1], isA<IconSymbolizer>());
    });
  });

  // ---------------------------------------------------------------------------
  // Read: raster
  // ---------------------------------------------------------------------------
  group('read raster', () {
    test('converts raster layer', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('sat', 'raster', paint: {
          'raster-opacity': 0.7,
          'raster-hue-rotate': 45,
          'raster-saturation': 0.5,
        }),
      ])));
      final sym = ((result as ReadStyleSuccess).output.rules.first
          .symbolizers.first) as RasterSymbolizer;
      expect((sym.opacity as LiteralExpression<double>).value, 0.7);
      expect((sym.hueRotate as LiteralExpression<double>).value, 45.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Read: unsupported layers produce warnings
  // ---------------------------------------------------------------------------
  group('unsupported layers', () {
    test('background produces warning', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('bg', 'background'),
      ])));
      final success = result as ReadStyleSuccess;
      expect(success.warnings, anyElement(contains('background')));
      expect(success.output.rules, isEmpty);
    });

    test('fill-extrusion produces warning', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('3d', 'fill-extrusion'),
      ])));
      expect((result as ReadStyleSuccess).warnings,
          anyElement(contains('fill-extrusion')));
    });
  });

  // ---------------------------------------------------------------------------
  // Read: filters
  // ---------------------------------------------------------------------------
  group('read filters', () {
    test('legacy v1 comparison', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('l', 'fill', filter: ['==', 'type', 'residential']),
      ])));
      final f = (result as ReadStyleSuccess).output.rules.first.filter
          as ComparisonFilter;
      expect(f.operator, ComparisonOperator.eq);
      expect((f.property as LiteralExpression<String>).value, 'type');
      expect((f.value as LiteralExpression<Object>).value, 'residential');
    });

    test('expression v2 comparison', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('l', 'fill', filter: ['>=', ['get', 'area'], 1000]),
      ])));
      final f = (result as ReadStyleSuccess).output.rules.first.filter
          as ComparisonFilter;
      expect(f.operator, ComparisonOperator.gte);
    });

    test('all/any combination', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('l', 'fill', filter: [
          'all',
          ['==', 'type', 'road'],
          ['>', 'width', 5],
        ]),
      ])));
      final f = (result as ReadStyleSuccess).output.rules.first.filter
          as CombinationFilter;
      expect(f.operator, CombinationOperator.and);
      expect(f.filters, hasLength(2));
    });

    test('negation', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        _layer('l', 'fill', filter: ['!', ['==', 'hidden', true]]),
      ])));
      expect((result as ReadStyleSuccess).output.rules.first.filter,
          isA<NegationFilter>());
    });
  });

  // ---------------------------------------------------------------------------
  // Read: zoom → ScaleDenominator
  // ---------------------------------------------------------------------------
  group('zoom to scale', () {
    test('minzoom/maxzoom converted', () async {
      final result = await adapter.readStyle(jsonEncode(_style([
        {'id': 'l', 'type': 'fill', 'minzoom': 10, 'maxzoom': 18},
      ])));
      final sd = (result as ReadStyleSuccess)
          .output.rules.first.scaleDenominator!;
      expect(sd.max, greaterThan(sd.min!));
      expect(sd.min, greaterThan(0));
    });
  });

  // ---------------------------------------------------------------------------
  // Read: invalid JSON
  // ---------------------------------------------------------------------------
  group('read errors', () {
    test('invalid JSON fails', () async {
      final result = await adapter.readStyle('not json');
      expect(result, isA<ReadStyleFailure>());
    });

    test('wrong version fails', () async {
      final result = await adapter.readStyle(
          jsonEncode({'version': 7, 'sources': {}, 'layers': []}));
      expect(result, isA<ReadStyleFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // Write: Style → Mapbox JSON
  // ---------------------------------------------------------------------------
  group('write', () {
    test('FillSymbolizer → fill layer', () async {
      const style = Style(rules: [
        Rule(name: 'water', symbolizers: [
          FillSymbolizer(
            color: LiteralExpression('#0000ff'),
            opacity: LiteralExpression(0.8),
          ),
        ]),
      ]);
      final result = await adapter.writeStyle(style);
      expect(result, isA<WriteStyleSuccess<String>>());
      final json = jsonDecode((result as WriteStyleSuccess<String>).output);
      expect(json['version'], 8);
      final layer = json['layers'][0];
      expect(layer['type'], 'fill');
      expect(layer['paint']['fill-color'], '#0000ff');
    });

    test('LineSymbolizer → line layer', () async {
      const style = Style(rules: [
        Rule(symbolizers: [
          LineSymbolizer(
            color: LiteralExpression('#333'),
            width: LiteralExpression(2.0),
            cap: 'round',
            dasharray: [10, 5],
          ),
        ]),
      ]);
      final result = await adapter.writeStyle(style);
      final json = jsonDecode((result as WriteStyleSuccess<String>).output);
      final layer = json['layers'][0];
      expect(layer['type'], 'line');
      expect(layer['layout']['line-cap'], 'round');
      expect(layer['paint']['line-dasharray'], [10, 5]);
    });

    test('MarkSymbolizer(circle) → circle layer', () async {
      const style = Style(rules: [
        Rule(symbolizers: [
          MarkSymbolizer(
            wellKnownName: 'circle',
            radius: LiteralExpression(5.0),
            color: LiteralExpression('#ff0000'),
          ),
        ]),
      ]);
      final result = await adapter.writeStyle(style);
      final json = jsonDecode((result as WriteStyleSuccess<String>).output);
      expect(json['layers'][0]['type'], 'circle');
    });

    test('non-circle MarkSymbolizer produces warning', () async {
      const style = Style(rules: [
        Rule(symbolizers: [
          MarkSymbolizer(wellKnownName: 'square'),
        ]),
      ]);
      final result = await adapter.writeStyle(style);
      final success = result as WriteStyleSuccess<String>;
      expect(success.warnings, anyElement(contains('square')));
    });

    test('TextSymbolizer → symbol layer', () async {
      const style = Style(rules: [
        Rule(symbolizers: [
          TextSymbolizer(
            label: FunctionExpression(PropertyGet('name')),
            size: LiteralExpression(14.0),
          ),
        ]),
      ]);
      final result = await adapter.writeStyle(style);
      final json = jsonDecode((result as WriteStyleSuccess<String>).output);
      final layer = json['layers'][0];
      expect(layer['type'], 'symbol');
      expect(layer['layout']['text-field'], ['get', 'name']);
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip
  // ---------------------------------------------------------------------------
  group('round-trip', () {
    test('read → write → read preserves structure', () async {
      final input = jsonEncode(_style([
        _layer('water', 'fill', paint: {'fill-color': '#0000ff'}),
        _layer('roads', 'line',
            paint: {'line-color': '#333', 'line-width': 2},
            layout: {'line-cap': 'round'}),
        _layer('pois', 'circle',
            paint: {'circle-radius': 5, 'circle-color': '#ff0000'}),
      ]));

      final r1 = await adapter.readStyle(input);
      final style1 = (r1 as ReadStyleSuccess).output;

      final w = await adapter.writeStyle(style1);
      final mapboxJson = (w as WriteStyleSuccess<String>).output;

      final r2 = await adapter.readStyle(mapboxJson);
      final style2 = (r2 as ReadStyleSuccess).output;

      expect(style2.rules.length, style1.rules.length);
      for (var i = 0; i < style1.rules.length; i++) {
        expect(style2.rules[i].symbolizers.length,
            style1.rules[i].symbolizers.length);
        expect(style2.rules[i].symbolizers.first.kind,
            style1.rules[i].symbolizers.first.kind);
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, Object?> _style(List<Map<String, Object?>> layers) => {
      'version': 8,
      'name': 'Test',
      'sources': <String, Object?>{},
      'layers': layers,
    };

Map<String, Object?> _layer(
  String id,
  String type, {
  Map<String, Object?>? paint,
  Map<String, Object?>? layout,
  List<Object?>? filter,
}) =>
    {
      'id': id,
      'type': type,
      if (paint != null) 'paint': paint,
      if (layout != null) 'layout': layout,
      if (filter != null) 'filter': filter,
    };
