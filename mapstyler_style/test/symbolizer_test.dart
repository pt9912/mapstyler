import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('FillSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Fill',
        'color': '#ffcc00',
        'opacity': 0.8,
        'fillOpacity': 0.5,
        'outlineColor': '#aa8800',
        'outlineWidth': 1.5,
      };
      final sym = Symbolizer.fromJson(json) as FillSymbolizer;
      expect(sym.kind, 'Fill');
      expect((sym.color as LiteralExpression<String>).value, '#ffcc00');
      expect((sym.opacity as LiteralExpression<double>).value, 0.8);
      expect((sym.fillOpacity as LiteralExpression<double>).value, 0.5);
      expect(
        (sym.outlineColor as LiteralExpression<String>).value,
        '#aa8800',
      );
      expect((sym.outlineWidth as LiteralExpression<double>).value, 1.5);
    });

    test('fromJson minimal (only kind)', () {
      final json = {'kind': 'Fill'};
      final sym = Symbolizer.fromJson(json) as FillSymbolizer;
      expect(sym.color, isNull);
      expect(sym.opacity, isNull);
    });

    test('fromJson with function expression', () {
      final json = {
        'kind': 'Fill',
        'color': {'name': 'property', 'args': ['fillColor']},
      };
      final sym = Symbolizer.fromJson(json) as FillSymbolizer;
      expect(sym.color, isA<FunctionExpression<String>>());
      final func = (sym.color as FunctionExpression<String>).function;
      expect((func as PropertyGet).propertyName, 'fillColor');
    });

    test('round-trip', () {
      final json = {
        'kind': 'Fill',
        'color': '#ffcc00',
        'opacity': 0.5,
        'outlineColor': '#000000',
        'outlineWidth': 2.0,
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('equality', () {
      const a = FillSymbolizer(color: LiteralExpression('#ff0000'));
      const b = FillSymbolizer(color: LiteralExpression('#ff0000'));
      const c = FillSymbolizer(color: LiteralExpression('#00ff00'));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('LineSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Line',
        'color': '#333333',
        'width': 2.0,
        'opacity': 1.0,
        'dasharray': [10.0, 5.0],
        'cap': 'round',
        'join': 'round',
      };
      final sym = Symbolizer.fromJson(json) as LineSymbolizer;
      expect((sym.color as LiteralExpression<String>).value, '#333333');
      expect((sym.width as LiteralExpression<double>).value, 2.0);
      expect(sym.dasharray, [10.0, 5.0]);
      expect(sym.cap, 'round');
      expect(sym.join, 'round');
    });

    test('round-trip', () {
      final json = {
        'kind': 'Line',
        'color': '#333333',
        'width': 2.0,
        'cap': 'round',
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('kind getter', () {
      const sym = LineSymbolizer();
      expect(sym.kind, 'Line');
    });

    test('equality', () {
      const a = LineSymbolizer(
        color: LiteralExpression('#000'),
        width: LiteralExpression(1.0),
      );
      const b = LineSymbolizer(
        color: LiteralExpression('#000'),
        width: LiteralExpression(1.0),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('MarkSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Mark',
        'wellKnownName': 'circle',
        'radius': 8.0,
        'color': '#ff0000',
        'opacity': 1.0,
        'strokeColor': '#990000',
        'strokeWidth': 1.0,
        'rotate': 45.0,
      };
      final sym = Symbolizer.fromJson(json) as MarkSymbolizer;
      expect(sym.wellKnownName, 'circle');
      expect((sym.radius as LiteralExpression<double>).value, 8.0);
      expect((sym.rotate as LiteralExpression<double>).value, 45.0);
    });

    test('round-trip', () {
      final json = {
        'kind': 'Mark',
        'wellKnownName': 'star',
        'radius': 10.0,
        'color': '#ffcc00',
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('kind getter', () {
      const sym = MarkSymbolizer(wellKnownName: 'circle');
      expect(sym.kind, 'Mark');
    });

    test('equality', () {
      const a = MarkSymbolizer(wellKnownName: 'circle');
      const b = MarkSymbolizer(wellKnownName: 'circle');
      const c = MarkSymbolizer(wellKnownName: 'square');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('IconSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Icon',
        'image': 'https://example.com/icon.png',
        'format': 'image/png',
        'size': 24.0,
        'opacity': 0.9,
        'rotate': 90.0,
      };
      final sym = Symbolizer.fromJson(json) as IconSymbolizer;
      expect(
        (sym.image as LiteralExpression<String>).value,
        'https://example.com/icon.png',
      );
      expect(sym.format, 'image/png');
    });

    test('fromJson with function expression for image', () {
      final json = {
        'kind': 'Icon',
        'image': {'name': 'property', 'args': ['iconUrl']},
      };
      final sym = Symbolizer.fromJson(json) as IconSymbolizer;
      expect(sym.image, isA<FunctionExpression<String>>());
    });

    test('round-trip', () {
      final json = {
        'kind': 'Icon',
        'image': 'marker.svg',
        'size': 16.0,
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });
  });

  group('TextSymbolizer', () {
    test('fromJson with all fields', () {
      final json = {
        'kind': 'Text',
        'label': {'name': 'property', 'args': ['name']},
        'color': '#333333',
        'size': 12.0,
        'font': 'Arial',
        'opacity': 1.0,
        'rotate': 0.0,
        'haloColor': '#ffffff',
        'haloWidth': 2.0,
        'placement': 'point',
      };
      final sym = Symbolizer.fromJson(json) as TextSymbolizer;
      expect(sym.label, isA<FunctionExpression<String>>());
      expect(sym.font, 'Arial');
      expect(sym.placement, 'point');
      expect(
        (sym.haloColor as LiteralExpression<String>).value,
        '#ffffff',
      );
      expect((sym.haloWidth as LiteralExpression<double>).value, 2.0);
    });

    test('fromJson with literal label', () {
      final json = {
        'kind': 'Text',
        'label': 'Static Label',
        'size': 14.0,
      };
      final sym = Symbolizer.fromJson(json) as TextSymbolizer;
      expect(sym.label, isA<LiteralExpression<String>>());
      expect((sym.label as LiteralExpression<String>).value, 'Static Label');
    });

    test('round-trip', () {
      final json = {
        'kind': 'Text',
        'label': 'Hello',
        'color': '#000000',
        'size': 14.0,
        'font': 'Helvetica',
        'placement': 'line',
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });
  });

  group('RasterSymbolizer', () {
    test('fromJson minimal', () {
      final json = {'kind': 'Raster'};
      final sym = Symbolizer.fromJson(json) as RasterSymbolizer;
      expect(sym.kind, 'Raster');
      expect(sym.opacity, isNull);
      expect(sym.colorMap, isNull);
      expect(sym.channelSelection, isNull);
    });

    test('fromJson with opacity', () {
      final json = {'kind': 'Raster', 'opacity': 0.7};
      final sym = Symbolizer.fromJson(json) as RasterSymbolizer;
      expect((sym.opacity as LiteralExpression<double>).value, 0.7);
    });

    test('fromJson with colorMap', () {
      final json = {
        'kind': 'Raster',
        'colorMap': {
          'type': 'ramp',
          'colorMapEntries': [
            {'color': '#0000ff', 'quantity': 0.0, 'label': 'Low'},
            {'color': '#ff0000', 'quantity': 100.0, 'label': 'High', 'opacity': 0.8},
          ],
        },
      };
      final sym = Symbolizer.fromJson(json) as RasterSymbolizer;
      final cm = sym.colorMap!;
      expect(cm.type, 'ramp');
      expect(cm.colorMapEntries.length, 2);
      expect(cm.colorMapEntries[0].color, '#0000ff');
      expect(cm.colorMapEntries[0].quantity, 0.0);
      expect(cm.colorMapEntries[0].label, 'Low');
      expect(cm.colorMapEntries[0].opacity, isNull);
      expect(cm.colorMapEntries[1].opacity, 0.8);
    });

    test('fromJson with channelSelection RGB', () {
      final json = {
        'kind': 'Raster',
        'channelSelection': {
          'redChannel': {'sourceChannelName': '1'},
          'greenChannel': {'sourceChannelName': '2'},
          'blueChannel': {
            'sourceChannelName': '3',
            'contrastEnhancement': {
              'enhancementType': 'normalize',
              'gammaValue': 1.2,
            },
          },
        },
      };
      final sym = Symbolizer.fromJson(json) as RasterSymbolizer;
      final cs = sym.channelSelection!;
      expect(cs.redChannel!.sourceChannelName, '1');
      expect(cs.greenChannel!.sourceChannelName, '2');
      expect(cs.blueChannel!.sourceChannelName, '3');
      expect(cs.blueChannel!.contrastEnhancement!.enhancementType, 'normalize');
      expect(cs.blueChannel!.contrastEnhancement!.gammaValue, 1.2);
      expect(cs.grayChannel, isNull);
    });

    test('fromJson with channelSelection gray', () {
      final json = {
        'kind': 'Raster',
        'channelSelection': {
          'grayChannel': {'sourceChannelName': '1'},
        },
      };
      final sym = Symbolizer.fromJson(json) as RasterSymbolizer;
      expect(sym.channelSelection!.grayChannel!.sourceChannelName, '1');
      expect(sym.channelSelection!.redChannel, isNull);
    });

    test('fromJson with contrastEnhancement', () {
      final json = {
        'kind': 'Raster',
        'contrastEnhancement': {
          'enhancementType': 'histogram',
          'gammaValue': 0.8,
        },
      };
      final sym = Symbolizer.fromJson(json) as RasterSymbolizer;
      expect(sym.contrastEnhancement!.enhancementType, 'histogram');
      expect(sym.contrastEnhancement!.gammaValue, 0.8);
    });

    test('fromJson with CSS-filter properties', () {
      final json = {
        'kind': 'Raster',
        'hueRotate': 90.0,
        'brightnessMin': 0.2,
        'brightnessMax': 0.9,
        'saturation': 1.5,
        'contrast': 1.2,
      };
      final sym = Symbolizer.fromJson(json) as RasterSymbolizer;
      expect((sym.hueRotate as LiteralExpression<double>).value, 90.0);
      expect((sym.brightnessMin as LiteralExpression<double>).value, 0.2);
      expect((sym.brightnessMax as LiteralExpression<double>).value, 0.9);
      expect((sym.saturation as LiteralExpression<double>).value, 1.5);
      expect((sym.contrast as LiteralExpression<double>).value, 1.2);
    });

    test('round-trip with all fields', () {
      final json = {
        'kind': 'Raster',
        'opacity': 0.8,
        'colorMap': {
          'type': 'intervals',
          'colorMapEntries': [
            {'color': '#00ff00', 'quantity': 50.0},
          ],
        },
        'channelSelection': {
          'grayChannel': {'sourceChannelName': '1'},
        },
        'contrastEnhancement': {
          'enhancementType': 'normalize',
        },
        'hueRotate': 45.0,
        'saturation': 1.0,
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('round-trip minimal', () {
      final json = {'kind': 'Raster', 'opacity': 0.5};
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('equality', () {
      const a = RasterSymbolizer(opacity: LiteralExpression(0.5));
      const b = RasterSymbolizer(opacity: LiteralExpression(0.5));
      const c = RasterSymbolizer(opacity: LiteralExpression(0.8));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('ColorMap equality', () {
      const a = ColorMap(
        type: 'ramp',
        colorMapEntries: [
          ColorMapEntry(color: '#ff0000', quantity: 0),
          ColorMapEntry(color: '#0000ff', quantity: 100),
        ],
      );
      const b = ColorMap(
        type: 'ramp',
        colorMapEntries: [
          ColorMapEntry(color: '#ff0000', quantity: 0),
          ColorMapEntry(color: '#0000ff', quantity: 100),
        ],
      );
      const c = ColorMap(type: 'intervals', colorMapEntries: []);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('ColorMap with extended flag round-trips', () {
      final json = {
        'type': 'ramp',
        'colorMapEntries': <dynamic>[],
        'extended': true,
      };
      final cm = ColorMap.fromJson(json);
      expect(cm.extended, true);
      expect(cm.toJson(), json);
    });
  });

  group('IconSymbolizer', () {
    test('kind getter', () {
      const sym = IconSymbolizer(image: LiteralExpression('x'));
      expect(sym.kind, 'Icon');
    });

    test('equality with all fields (non-const)', () {
      // Use final (not const) to avoid canonicalization so == evaluates all fields.
      final a = IconSymbolizer(
        image: const LiteralExpression('a.png'),
        format: 'image/png',
        size: const LiteralExpression(24.0),
        opacity: const LiteralExpression(0.9),
        rotate: const LiteralExpression(90.0),
      );
      final b = IconSymbolizer(
        image: const LiteralExpression('a.png'),
        format: 'image/png',
        size: const LiteralExpression(24.0),
        opacity: const LiteralExpression(0.9),
        rotate: const LiteralExpression(90.0),
      );
      final c = IconSymbolizer(
        image: const LiteralExpression('a.png'),
        format: 'image/svg',
        size: const LiteralExpression(24.0),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('round-trip with all fields', () {
      final json = {
        'kind': 'Icon',
        'image': 'marker.png',
        'format': 'image/png',
        'size': 24.0,
        'opacity': 0.9,
        'rotate': 45.0,
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });
  });

  group('TextSymbolizer', () {
    test('kind getter', () {
      const sym = TextSymbolizer(label: LiteralExpression('x'));
      expect(sym.kind, 'Text');
    });

    test('equality with all fields (non-const)', () {
      final a = TextSymbolizer(
        label: const LiteralExpression('L'),
        color: const LiteralExpression('#000'),
        size: const LiteralExpression(14.0),
        font: 'Arial',
        opacity: const LiteralExpression(1.0),
        rotate: const LiteralExpression(0.0),
        haloColor: const LiteralExpression('#fff'),
        haloWidth: const LiteralExpression(2.0),
        placement: 'point',
      );
      final b = TextSymbolizer(
        label: const LiteralExpression('L'),
        color: const LiteralExpression('#000'),
        size: const LiteralExpression(14.0),
        font: 'Arial',
        opacity: const LiteralExpression(1.0),
        rotate: const LiteralExpression(0.0),
        haloColor: const LiteralExpression('#fff'),
        haloWidth: const LiteralExpression(2.0),
        placement: 'point',
      );
      final c = TextSymbolizer(
        label: const LiteralExpression('L'),
        font: 'Helvetica',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('round-trip with all fields', () {
      final json = {
        'kind': 'Text',
        'label': 'Test',
        'color': '#000',
        'size': 14.0,
        'font': 'Arial',
        'opacity': 1.0,
        'rotate': 0.0,
        'haloColor': '#fff',
        'haloWidth': 2.0,
        'placement': 'point',
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });
  });

  group('ColorMapEntry', () {
    test('round-trip with all fields', () {
      final json = {
        'color': '#ff0000',
        'quantity': 100.0,
        'label': 'High',
        'opacity': 0.8,
      };
      final entry = ColorMapEntry.fromJson(json);
      expect(entry.toJson(), json);
    });

    test('round-trip minimal', () {
      final json = {'color': '#00ff00', 'quantity': 0.0};
      final entry = ColorMapEntry.fromJson(json);
      expect(entry.toJson(), json);
    });

    test('equality', () {
      const a = ColorMapEntry(color: '#ff0000', quantity: 0);
      const b = ColorMapEntry(color: '#ff0000', quantity: 0);
      const c = ColorMapEntry(color: '#ff0000', quantity: 100);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('equality with label and opacity (non-const)', () {
      final a =
          ColorMapEntry(color: '#f00', quantity: 0, label: 'L', opacity: 0.5);
      final b =
          ColorMapEntry(color: '#f00', quantity: 0, label: 'L', opacity: 0.5);
      final c =
          ColorMapEntry(color: '#f00', quantity: 0, label: 'X', opacity: 0.5);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ContrastEnhancement', () {
    test('round-trip with all fields', () {
      final json = {'enhancementType': 'normalize', 'gammaValue': 1.2};
      final ce = ContrastEnhancement.fromJson(json);
      expect(ce.toJson(), json);
    });

    test('round-trip minimal', () {
      final json = <String, dynamic>{};
      final ce = ContrastEnhancement.fromJson(json);
      expect(ce.toJson(), json);
    });

    test('equality', () {
      const a =
          ContrastEnhancement(enhancementType: 'normalize', gammaValue: 1.0);
      const b =
          ContrastEnhancement(enhancementType: 'normalize', gammaValue: 1.0);
      const c =
          ContrastEnhancement(enhancementType: 'histogram', gammaValue: 1.0);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Channel', () {
    test('round-trip without contrastEnhancement', () {
      final json = {'sourceChannelName': '1'};
      final ch = Channel.fromJson(json);
      expect(ch.toJson(), json);
    });

    test('round-trip with contrastEnhancement', () {
      final json = {
        'sourceChannelName': '3',
        'contrastEnhancement': {'enhancementType': 'normalize', 'gammaValue': 1.5},
      };
      final ch = Channel.fromJson(json);
      expect(ch.toJson(), json);
    });

    test('equality', () {
      const a = Channel(sourceChannelName: '1');
      const b = Channel(sourceChannelName: '1');
      const c = Channel(sourceChannelName: '2');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ChannelSelection', () {
    test('round-trip RGB', () {
      final json = {
        'redChannel': {'sourceChannelName': '1'},
        'greenChannel': {'sourceChannelName': '2'},
        'blueChannel': {'sourceChannelName': '3'},
      };
      final cs = ChannelSelection.fromJson(json);
      expect(cs.toJson(), json);
    });

    test('round-trip gray', () {
      final json = {
        'grayChannel': {'sourceChannelName': '1'},
      };
      final cs = ChannelSelection.fromJson(json);
      expect(cs.toJson(), json);
    });

    test('equality', () {
      const a = ChannelSelection(
        grayChannel: Channel(sourceChannelName: '1'),
      );
      const b = ChannelSelection(
        grayChannel: Channel(sourceChannelName: '1'),
      );
      const c = ChannelSelection(
        grayChannel: Channel(sourceChannelName: '2'),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('RasterSymbolizer CSS-filter round-trip', () {
    test('round-trip with all CSS-filter properties', () {
      final json = {
        'kind': 'Raster',
        'opacity': 0.8,
        'hueRotate': 90.0,
        'brightnessMin': 0.2,
        'brightnessMax': 0.9,
        'saturation': 1.5,
        'contrast': 1.2,
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('round-trip with full raster config', () {
      final json = {
        'kind': 'Raster',
        'opacity': 0.8,
        'colorMap': {
          'type': 'ramp',
          'colorMapEntries': [
            {'color': '#0000ff', 'quantity': 0.0, 'label': 'Low', 'opacity': 1.0},
            {'color': '#ff0000', 'quantity': 100.0, 'label': 'High'},
          ],
          'extended': true,
        },
        'channelSelection': {
          'redChannel': {'sourceChannelName': '1'},
          'greenChannel': {'sourceChannelName': '2'},
          'blueChannel': {
            'sourceChannelName': '3',
            'contrastEnhancement': {
              'enhancementType': 'normalize',
              'gammaValue': 1.2,
            },
          },
        },
        'contrastEnhancement': {
          'enhancementType': 'histogram',
          'gammaValue': 0.8,
        },
        'hueRotate': 45.0,
        'brightnessMin': 0.1,
        'brightnessMax': 0.95,
        'saturation': 1.2,
        'contrast': 1.1,
      };
      final sym = Symbolizer.fromJson(json);
      expect(sym.toJson(), json);
    });

    test('equality with all fields (non-const)', () {
      // Use final to avoid const canonicalization — ensures == evaluates all fields.
      final a = RasterSymbolizer(
        opacity: const LiteralExpression(0.8),
        colorMap: ColorMap(type: 'ramp', colorMapEntries: [
          const ColorMapEntry(color: '#f00', quantity: 0),
        ]),
        channelSelection: const ChannelSelection(
          grayChannel: Channel(sourceChannelName: '1'),
        ),
        contrastEnhancement: const ContrastEnhancement(
          enhancementType: 'normalize',
          gammaValue: 1.0,
        ),
        hueRotate: const LiteralExpression(45.0),
        brightnessMin: const LiteralExpression(0.1),
        brightnessMax: const LiteralExpression(0.9),
        saturation: const LiteralExpression(1.2),
        contrast: const LiteralExpression(1.1),
      );
      final b = RasterSymbolizer(
        opacity: const LiteralExpression(0.8),
        colorMap: ColorMap(type: 'ramp', colorMapEntries: [
          const ColorMapEntry(color: '#f00', quantity: 0),
        ]),
        channelSelection: const ChannelSelection(
          grayChannel: Channel(sourceChannelName: '1'),
        ),
        contrastEnhancement: const ContrastEnhancement(
          enhancementType: 'normalize',
          gammaValue: 1.0,
        ),
        hueRotate: const LiteralExpression(45.0),
        brightnessMin: const LiteralExpression(0.1),
        brightnessMax: const LiteralExpression(0.9),
        saturation: const LiteralExpression(1.2),
        contrast: const LiteralExpression(1.1),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Symbolizer.fromJson', () {
    test('throws on unknown kind', () {
      expect(
        () => Symbolizer.fromJson({'kind': 'Unknown'}),
        throwsFormatException,
      );
    });
  });
}
