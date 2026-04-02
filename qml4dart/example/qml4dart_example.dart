import 'package:qml4dart/qml4dart.dart';

/// Beispiel: QML parsen, Inhalte ausgeben und als XML zurückschreiben.
void main() {
  const codec = Qml4DartCodec();

  // -- Parsen ----------------------------------------------------------
  final result = codec.parseString(_exampleQml);

  switch (result) {
    case ReadQmlFailure(:final message):
      print('Fehler: $message');
      return;
    case ReadQmlSuccess(:final document, :final warnings):
      for (final w in warnings) {
        print('Warning: $w');
      }
      _printDocument(document);

      // -- Schreiben -----------------------------------------------------
      final writeResult = codec.encodeString(document);
      if (writeResult case WriteQmlSuccess(:final xml)) {
        print('\n--- Erzeugtes QML ---');
        print(xml);
      }
  }
}

void _printDocument(QmlDocument doc) {
  print('QGIS Version: ${doc.version}');
  print('Renderer:     ${doc.renderer.type.toQmlString()}');

  if (doc.renderer.attribute != null) {
    print('Attribut:     ${doc.renderer.attribute}');
  }

  print('Symbole:      ${doc.renderer.symbols.length}');
  for (final entry in doc.renderer.symbols.entries) {
    final sym = entry.value;
    print('  [${entry.key}] ${sym.type.toQmlString()}, '
        'alpha=${sym.alpha}, layers=${sym.layers.length}');
    for (final layer in sym.layers) {
      print('    ${layer.className}: '
          '${layer.properties.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
    }
  }

  if (doc.renderer.categories.isNotEmpty) {
    print('Kategorien:');
    for (final cat in doc.renderer.categories) {
      print('  "${cat.value}" → Symbol ${cat.symbolKey} '
          '(${cat.label ?? '-'}, render=${cat.render})');
    }
  }

  if (doc.renderer.ranges.isNotEmpty) {
    print('Wertebereiche:');
    for (final range in doc.renderer.ranges) {
      print('  ${range.lower}–${range.upper} → Symbol ${range.symbolKey} '
          '(${range.label ?? '-'})');
    }
  }

  if (doc.renderer.rules.isNotEmpty) {
    print('Regeln:');
    _printRules(doc.renderer.rules, indent: 2);
  }
}

void _printRules(List<QmlRule> rules, {int indent = 0}) {
  final pad = ' ' * indent;
  for (final rule in rules) {
    final parts = <String>[
      if (rule.label != null) rule.label!,
      if (rule.filter != null) 'filter="${rule.filter}"',
      if (rule.symbolKey != null) '→ Symbol ${rule.symbolKey}',
      if (!rule.enabled) '(disabled)',
    ];
    print('$pad- ${parts.join('  ')}');
    if (rule.children.isNotEmpty) {
      _printRules(rule.children, indent: indent + 2);
    }
  }
}

const _exampleQml = '''
<qgis version="3.28.0-Firenze" hasScaleBasedVisibilityFlag="1" maxScale="1000" minScale="100000">
  <renderer-v2 type="categorizedSymbol" attr="landuse" forceraster="0" symbollevels="0" enableorderby="0">
    <categories>
      <category value="residential" symbol="0" label="Wohngebiet" render="true"/>
      <category value="commercial" symbol="1" label="Gewerbe" render="true"/>
      <category value="industrial" symbol="2" label="Industrie" render="false"/>
    </categories>
    <symbols>
      <symbol type="fill" name="0" alpha="1" clip_to_extent="1" force_rhr="0">
        <layer class="SimpleFill" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="255,255,0,255" type="QString"/>
            <Option name="style" value="solid" type="QString"/>
            <Option name="outline_color" value="0,0,0,255" type="QString"/>
            <Option name="outline_style" value="solid" type="QString"/>
            <Option name="outline_width" value="0.26" type="QString"/>
          </Option>
        </layer>
      </symbol>
      <symbol type="fill" name="1" alpha="1" clip_to_extent="1" force_rhr="0">
        <layer class="SimpleFill" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="255,0,0,255" type="QString"/>
            <Option name="style" value="solid" type="QString"/>
            <Option name="outline_color" value="0,0,0,255" type="QString"/>
            <Option name="outline_style" value="solid" type="QString"/>
            <Option name="outline_width" value="0.26" type="QString"/>
          </Option>
        </layer>
      </symbol>
      <symbol type="fill" name="2" alpha="0.5" clip_to_extent="1" force_rhr="0">
        <layer class="SimpleFill" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="128,0,128,255" type="QString"/>
            <Option name="style" value="solid" type="QString"/>
            <Option name="outline_color" value="0,0,0,255" type="QString"/>
            <Option name="outline_style" value="solid" type="QString"/>
            <Option name="outline_width" value="0.26" type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
    <rotation/>
    <sizescale/>
  </renderer-v2>
</qgis>
''';
