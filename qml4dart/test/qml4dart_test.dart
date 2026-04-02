import 'dart:io';

import 'package:qml4dart/qml4dart.dart';
import 'package:test/test.dart';

String _fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

void main() {
  const codec = Qml4DartCodec();

  // ---------------------------------------------------------------------------
  // Model smoke tests
  // ---------------------------------------------------------------------------
  group('Model', () {
    test('QmlDocument can be constructed', () {
      const doc = QmlDocument(
        renderer: QmlRenderer(type: QmlRendererType.singleSymbol),
      );
      expect(doc.renderer.type, QmlRendererType.singleSymbol);
    });

    test('QmlRendererType round-trips through string', () {
      for (final t in QmlRendererType.values) {
        if (t == QmlRendererType.unknown) continue;
        expect(QmlRendererType.fromString(t.toQmlString()), t);
      }
    });

    test('QmlSymbolType round-trips through string', () {
      for (final t in QmlSymbolType.values) {
        if (t == QmlSymbolType.unknown) continue;
        expect(QmlSymbolType.fromString(t.toQmlString()), t);
      }
    });

    test('QmlSymbolLayerType round-trips through className', () {
      for (final t in QmlSymbolLayerType.values) {
        if (t == QmlSymbolLayerType.unknown) continue;
        expect(QmlSymbolLayerType.fromClassName(t.toClassName()), t);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Parsing – singleSymbol
  // ---------------------------------------------------------------------------
  group('Parse singleSymbol', () {
    test('SimpleFill new format', () {
      final result = codec.parseString(_fixture('single_symbol_fill_new.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;
      expect(result.warnings, isEmpty);

      expect(doc.version, '3.28.0-Firenze');
      expect(doc.hasScaleBasedVisibility, isFalse);

      final r = doc.renderer;
      expect(r.type, QmlRendererType.singleSymbol);
      expect(r.symbols, hasLength(1));
      expect(r.symbols.containsKey('0'), isTrue);

      final sym = r.symbols['0']!;
      expect(sym.type, QmlSymbolType.fill);
      expect(sym.alpha, 1.0);
      expect(sym.layers, hasLength(1));

      final layer = sym.layers.first;
      expect(layer.type, QmlSymbolLayerType.simpleFill);
      expect(layer.className, 'SimpleFill');
      expect(layer.properties['color'], '181,121,72,255');
      expect(layer.properties['outline_width'], '0.26');
    });

    test('SimpleFill old prop format', () {
      final result = codec.parseString(_fixture('single_symbol_fill_old.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final layer = doc.renderer.symbols['0']!.layers.first;
      expect(layer.properties['color'], '181,121,72,255');
      expect(layer.properties['outline_width'], '0.26');
    });

    test('SimpleLine', () {
      final result = codec.parseString(_fixture('single_symbol_line.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final sym = doc.renderer.symbols['0']!;
      expect(sym.type, QmlSymbolType.line);

      final layer = sym.layers.first;
      expect(layer.type, QmlSymbolLayerType.simpleLine);
      expect(layer.properties['line_color'], '255,0,255,255');
      expect(layer.properties['line_width'], '3');
      expect(layer.properties['use_custom_dash'], '1');
    });

    test('SimpleMarker', () {
      final result = codec.parseString(_fixture('single_symbol_marker.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final sym = doc.renderer.symbols['0']!;
      expect(sym.type, QmlSymbolType.marker);
      expect(sym.alpha, 0.8);

      final layer = sym.layers.first;
      expect(layer.type, QmlSymbolLayerType.simpleMarker);
      expect(layer.properties['name'], 'circle');
      expect(layer.properties['size'], '4');
    });

    test('SvgMarker', () {
      final result = codec.parseString(_fixture('svg_marker.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final layer = doc.renderer.symbols['0']!.layers.first;
      expect(layer.type, QmlSymbolLayerType.svgMarker);
      expect(layer.className, 'SvgMarker');
      expect(layer.properties['angle'], '45');
    });

    test('Multi-layer symbol', () {
      final result = codec.parseString(_fixture('multi_layer_symbol.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final sym = doc.renderer.symbols['0']!;
      expect(sym.layers, hasLength(2));
      expect(sym.layers[0].properties['name'], 'square');
      expect(sym.layers[0].locked, isFalse);
      expect(sym.layers[1].properties['name'], 'circle');
      expect(sym.layers[1].locked, isTrue);
      expect(sym.layers[1].pass, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Parsing – categorizedSymbol
  // ---------------------------------------------------------------------------
  group('Parse categorizedSymbol', () {
    test('categories and symbols', () {
      final result = codec.parseString(_fixture('categorized.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final r = doc.renderer;
      expect(r.type, QmlRendererType.categorizedSymbol);
      expect(r.attribute, 'landuse');
      expect(r.categories, hasLength(4));
      expect(r.symbols, hasLength(4));

      expect(r.categories[0].value, 'residential');
      expect(r.categories[0].symbolKey, '0');
      expect(r.categories[0].label, 'Wohngebiet');
      expect(r.categories[0].render, isTrue);

      expect(r.categories[2].value, 'industrial');
      expect(r.categories[2].render, isFalse);

      expect(r.categories[3].value, '');
      expect(r.categories[3].label, 'Sonstige');

      expect(r.symbols['0']!.layers.first.properties['color'],
          '255,255,0,255');
    });
  });

  // ---------------------------------------------------------------------------
  // Parsing – graduatedSymbol
  // ---------------------------------------------------------------------------
  group('Parse graduatedSymbol', () {
    test('ranges and symbols', () {
      final result = codec.parseString(_fixture('graduated.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final r = doc.renderer;
      expect(r.type, QmlRendererType.graduatedSymbol);
      expect(r.attribute, 'population');
      expect(r.graduatedMethod, 'GraduatedColor');
      expect(r.ranges, hasLength(3));
      expect(r.symbols, hasLength(3));

      expect(r.ranges[0].lower, 0.0);
      expect(r.ranges[0].upper, 1000.0);
      expect(r.ranges[0].symbolKey, '0');
      expect(r.ranges[0].label, '0 - 1000');

      expect(r.ranges[2].lower, 5000.0);
      expect(r.ranges[2].upper, 10000.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Parsing – RuleRenderer
  // ---------------------------------------------------------------------------
  group('Parse RuleRenderer', () {
    test('flat rules', () {
      final result = codec.parseString(_fixture('rule_renderer.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final r = doc.renderer;
      expect(r.type, QmlRendererType.ruleRenderer);
      expect(r.rules, hasLength(3));
      expect(r.symbols, hasLength(3));

      final rule0 = r.rules[0];
      expect(rule0.key, 'rule_0');
      expect(rule0.symbolKey, '0');
      expect(rule0.filter, 'Bildpositi = 1');
      expect(rule0.scaleMinDenominator, 100);
      expect(rule0.scaleMaxDenominator, 2000);
      expect(rule0.enabled, isTrue);

      final rule1 = r.rules[1];
      expect(rule1.scaleMinDenominator, isNull);
      expect(rule1.scaleMaxDenominator, isNull);

      final rule2 = r.rules[2];
      expect(rule2.enabled, isFalse);
    });

    test('nested rules', () {
      final result = codec.parseString(_fixture('nested_rules.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      final r = doc.renderer;
      expect(r.rules, hasLength(2));

      final parent1 = r.rules[0];
      expect(parent1.key, 'parent_1');
      expect(parent1.symbolKey, isNull); // grouping only
      expect(parent1.children, hasLength(2));
      expect(parent1.children[0].key, 'child_1a');
      expect(parent1.children[0].symbolKey, '0');
      expect(parent1.children[1].key, 'child_1b');

      final parent2 = r.rules[1];
      expect(parent2.symbolKey, '2');
      expect(parent2.children, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Parsing – scale visibility
  // ---------------------------------------------------------------------------
  group('Parse scale visibility', () {
    test('layer-level scale visibility', () {
      final result = codec.parseString(_fixture('scale_visibility.qml'));
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;

      expect(doc.hasScaleBasedVisibility, isTrue);
      expect(doc.maxScale, 1000);
      expect(doc.minScale, 50000);
    });
  });

  // ---------------------------------------------------------------------------
  // Parsing – error cases
  // ---------------------------------------------------------------------------
  group('Parse errors', () {
    test('invalid XML', () {
      final result = codec.parseString('<not valid xml>>>');
      expect(result, isA<ReadQmlFailure>());
      expect(
        (result as ReadQmlFailure).message,
        contains('XML parsing error'),
      );
    });

    test('wrong root element', () {
      final result = codec.parseString('<foo/>');
      expect(result, isA<ReadQmlFailure>());
      expect(
        (result as ReadQmlFailure).message,
        contains('Expected root element <qgis>'),
      );
    });

    test('missing renderer-v2', () {
      final result = codec.parseString('<qgis version="3.28"/>');
      expect(result, isA<ReadQmlFailure>());
      expect(
        (result as ReadQmlFailure).message,
        contains('Missing <renderer-v2>'),
      );
    });

    test('unknown renderer type produces warning', () {
      final result = codec.parseString('''
        <qgis version="3.28">
          <renderer-v2 type="heatmapRenderer">
            <symbols/>
          </renderer-v2>
        </qgis>
      ''');
      expect(result, isA<ReadQmlSuccess>());
      final success = result as ReadQmlSuccess;
      expect(success.warnings, contains(contains('Unknown renderer type')));
      expect(success.document.renderer.type, QmlRendererType.unknown);
    });

    test('unknown symbol layer class produces warning', () {
      final result = codec.parseString('''
        <qgis version="3.28">
          <renderer-v2 type="singleSymbol">
            <symbols>
              <symbol type="fill" name="0" alpha="1">
                <layer class="GradientFill" enabled="1">
                  <Option type="Map">
                    <Option name="color" value="0,0,0,255" type="QString"/>
                  </Option>
                </layer>
              </symbol>
            </symbols>
          </renderer-v2>
        </qgis>
      ''');
      expect(result, isA<ReadQmlSuccess>());
      final success = result as ReadQmlSuccess;
      expect(
        success.warnings,
        contains(contains('Unknown symbol layer class: GradientFill')),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Writing
  // ---------------------------------------------------------------------------
  group('Write', () {
    test('singleSymbol round-trip', () {
      final parsed = codec.parseString(_fixture('single_symbol_fill_new.qml'));
      final doc = (parsed as ReadQmlSuccess).document;

      final writeResult = codec.encodeString(doc);
      expect(writeResult, isA<WriteQmlSuccess>());
      final xml = (writeResult as WriteQmlSuccess).xml;

      // Re-parse the written XML
      final reparsed = codec.parseString(xml);
      expect(reparsed, isA<ReadQmlSuccess>());
      final doc2 = (reparsed as ReadQmlSuccess).document;

      expect(doc2.renderer.type, doc.renderer.type);
      expect(doc2.renderer.symbols.length, doc.renderer.symbols.length);
      final layer1 = doc.renderer.symbols['0']!.layers.first;
      final layer2 = doc2.renderer.symbols['0']!.layers.first;
      expect(layer2.properties['color'], layer1.properties['color']);
      expect(layer2.properties['outline_width'],
          layer1.properties['outline_width']);
    });

    test('categorized round-trip', () {
      final parsed = codec.parseString(_fixture('categorized.qml'));
      final doc = (parsed as ReadQmlSuccess).document;

      final writeResult = codec.encodeString(doc);
      final xml = (writeResult as WriteQmlSuccess).xml;

      final reparsed = codec.parseString(xml);
      final doc2 = (reparsed as ReadQmlSuccess).document;

      expect(doc2.renderer.type, QmlRendererType.categorizedSymbol);
      expect(doc2.renderer.attribute, 'landuse');
      expect(doc2.renderer.categories, hasLength(4));
      expect(doc2.renderer.categories[0].value, 'residential');
      expect(doc2.renderer.categories[0].label, 'Wohngebiet');
      expect(doc2.renderer.symbols, hasLength(4));
    });

    test('graduated round-trip', () {
      final parsed = codec.parseString(_fixture('graduated.qml'));
      final doc = (parsed as ReadQmlSuccess).document;

      final writeResult = codec.encodeString(doc);
      final xml = (writeResult as WriteQmlSuccess).xml;

      final reparsed = codec.parseString(xml);
      final doc2 = (reparsed as ReadQmlSuccess).document;

      expect(doc2.renderer.type, QmlRendererType.graduatedSymbol);
      expect(doc2.renderer.graduatedMethod, 'GraduatedColor');
      expect(doc2.renderer.ranges, hasLength(3));
      expect(doc2.renderer.ranges[0].lower, 0.0);
      expect(doc2.renderer.ranges[0].upper, 1000.0);
    });

    test('RuleRenderer round-trip', () {
      final parsed = codec.parseString(_fixture('rule_renderer.qml'));
      final doc = (parsed as ReadQmlSuccess).document;

      final writeResult = codec.encodeString(doc);
      final xml = (writeResult as WriteQmlSuccess).xml;

      final reparsed = codec.parseString(xml);
      final doc2 = (reparsed as ReadQmlSuccess).document;

      expect(doc2.renderer.type, QmlRendererType.ruleRenderer);
      expect(doc2.renderer.rules, hasLength(3));
      expect(doc2.renderer.rules[0].filter, 'Bildpositi = 1');
      expect(doc2.renderer.rules[0].scaleMinDenominator, 100);
      expect(doc2.renderer.rules[2].enabled, isFalse);
    });

    test('nested rules round-trip', () {
      final parsed = codec.parseString(_fixture('nested_rules.qml'));
      final doc = (parsed as ReadQmlSuccess).document;

      final writeResult = codec.encodeString(doc);
      final xml = (writeResult as WriteQmlSuccess).xml;

      final reparsed = codec.parseString(xml);
      final doc2 = (reparsed as ReadQmlSuccess).document;

      expect(doc2.renderer.rules, hasLength(2));
      expect(doc2.renderer.rules[0].children, hasLength(2));
      expect(doc2.renderer.rules[0].symbolKey, isNull);
      expect(doc2.renderer.rules[0].children[0].symbolKey, '0');
    });

    test('scale visibility round-trip', () {
      final parsed = codec.parseString(_fixture('scale_visibility.qml'));
      final doc = (parsed as ReadQmlSuccess).document;

      final writeResult = codec.encodeString(doc);
      final xml = (writeResult as WriteQmlSuccess).xml;

      final reparsed = codec.parseString(xml);
      final doc2 = (reparsed as ReadQmlSuccess).document;

      expect(doc2.hasScaleBasedVisibility, isTrue);
      expect(doc2.maxScale, 1000);
      expect(doc2.minScale, 50000);
    });

    test('multi-layer symbol round-trip', () {
      final parsed = codec.parseString(_fixture('multi_layer_symbol.qml'));
      final doc = (parsed as ReadQmlSuccess).document;

      final writeResult = codec.encodeString(doc);
      final xml = (writeResult as WriteQmlSuccess).xml;

      final reparsed = codec.parseString(xml);
      final doc2 = (reparsed as ReadQmlSuccess).document;

      final sym = doc2.renderer.symbols['0']!;
      expect(sym.layers, hasLength(2));
      expect(sym.layers[1].locked, isTrue);
      expect(sym.layers[1].pass, 1);
    });

    test('written XML contains expected structure', () {
      final doc = QmlDocument(
        version: '3.28.0',
        renderer: QmlRenderer(
          type: QmlRendererType.singleSymbol,
          symbols: {
            '0': QmlSymbol(
              type: QmlSymbolType.fill,
              layers: [
                QmlSymbolLayer(
                  type: QmlSymbolLayerType.simpleFill,
                  className: 'SimpleFill',
                  properties: {'color': '255,0,0,255', 'style': 'solid'},
                ),
              ],
            ),
          },
        ),
      );

      final result = codec.encodeString(doc);
      final xml = (result as WriteQmlSuccess).xml;

      expect(xml, contains('<qgis'));
      expect(xml, contains('version="3.28.0"'));
      expect(xml, contains('type="singleSymbol"'));
      expect(xml, contains('class="SimpleFill"'));
      expect(xml, contains('value="255,0,0,255"'));
      expect(xml, contains('<rotation/>'));
      expect(xml, contains('<sizescale/>'));
    });
  });

  // ---------------------------------------------------------------------------
  // File I/O
  // ---------------------------------------------------------------------------
  group('File I/O', () {
    test('parseFile reads fixture', () async {
      final result = await codec.parseFile('test/fixtures/categorized.qml');
      expect(result, isA<ReadQmlSuccess>());
      final doc = (result as ReadQmlSuccess).document;
      expect(doc.renderer.type, QmlRendererType.categorizedSymbol);
    });

    test('parseFile returns failure for missing file', () async {
      final result = await codec.parseFile('test/fixtures/nonexistent.qml');
      expect(result, isA<ReadQmlFailure>());
    });

    test('encodeFile writes and reads back', () async {
      final parsed = codec.parseString(_fixture('single_symbol_marker.qml'));
      final doc = (parsed as ReadQmlSuccess).document;

      final tmpDir = Directory.systemTemp.createTempSync('qml4dart_test_');
      final tmpPath = '${tmpDir.path}/output.qml';

      try {
        final writeResult = await codec.encodeFile(tmpPath, doc);
        expect(writeResult, isA<WriteQmlSuccess>());

        final readBack = await codec.parseFile(tmpPath);
        expect(readBack, isA<ReadQmlSuccess>());
        final doc2 = (readBack as ReadQmlSuccess).document;
        expect(doc2.renderer.symbols['0']!.layers.first.properties['name'],
            'circle');
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });
  });
}
