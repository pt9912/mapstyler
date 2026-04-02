import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

/// Example: parse a QGIS QML style, convert to mapstyler types,
/// and write it back to QML XML.
void main() async {
  final parser = QmlStyleParser();

  // -- Read: QML XML → mapstyler Style ------------------------------------
  print('--- QML → mapstyler_style ---');
  final readResult = await parser.readStyle(_categorizedQml);

  switch (readResult) {
    case ReadStyleSuccess(:final output, :final warnings):
      for (final w in warnings) {
        print('  Warning: $w');
      }
      _printStyle(output);

      // -- Write: mapstyler Style → QML XML --------------------------------
      print('\n--- mapstyler_style → QML ---');
      final writeResult = await parser.writeStyle(output);
      if (writeResult case WriteStyleSuccess(:final output)) {
        print(output); // QML XML string
      }

    case ReadStyleFailure(:final errors):
      print('  Failed: $errors');
  }

  // -- Build from code and write ------------------------------------------
  print('\n--- From code → QML ---');
  const style = Style(
    rules: [
      Rule(
        name: 'Forests',
        filter: ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('landuse'),
          value: LiteralExpression<Object>('forest'),
        ),
        symbolizers: [
          FillSymbolizer(
            color: LiteralExpression('#228B22'),
            opacity: LiteralExpression(0.7),
            outlineColor: LiteralExpression('#006400'),
            outlineWidth: LiteralExpression(1.0),
          ),
        ],
      ),
    ],
  );
  final result = await parser.writeStyle(style);
  if (result case WriteStyleSuccess(:final output)) {
    print(output);
  }
}

// ---------------------------------------------------------------------------
// Pretty-print
// ---------------------------------------------------------------------------

void _printStyle(Style style) {
  print('Style: ${style.name ?? "(unnamed)"}');
  for (final rule in style.rules) {
    final parts = <String>[
      rule.name ?? '(unnamed)',
      '${rule.symbolizers.length} symbolizer(s)',
      if (rule.filter != null) 'filtered',
      if (rule.scaleDenominator != null)
        'scale ${rule.scaleDenominator!.min}–${rule.scaleDenominator!.max}',
    ];
    print('  ${parts.join(' | ')}');
    for (final sym in rule.symbolizers) {
      print('    ${sym.kind}');
    }
  }
}

// ---------------------------------------------------------------------------
// Sample QML XML
// ---------------------------------------------------------------------------

const _categorizedQml = '''
<qgis version="3.28.0" hasScaleBasedVisibilityFlag="1"
      maxScale="1000" minScale="100000">
  <renderer-v2 type="categorizedSymbol" attr="landuse">
    <categories>
      <category value="residential" symbol="0" label="Residential" render="true"/>
      <category value="commercial" symbol="1" label="Commercial" render="true"/>
    </categories>
    <symbols>
      <symbol type="fill" name="0" alpha="1">
        <layer class="SimpleFill" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="255,204,0,255" type="QString"/>
            <Option name="style" value="solid" type="QString"/>
            <Option name="outline_color" value="0,0,0,255" type="QString"/>
            <Option name="outline_width" value="0.5" type="QString"/>
          </Option>
        </layer>
      </symbol>
      <symbol type="fill" name="1" alpha="0.8">
        <layer class="SimpleFill" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option name="color" value="255,0,0,255" type="QString"/>
            <Option name="style" value="solid" type="QString"/>
            <Option name="outline_color" value="51,51,51,255" type="QString"/>
            <Option name="outline_width" value="0.26" type="QString"/>
          </Option>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
</qgis>
''';
