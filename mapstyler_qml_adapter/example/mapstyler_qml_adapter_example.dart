import 'package:qml4dart/qml4dart.dart';
import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

/// Example: parse a QGIS QML style, convert to mapstyler types, modify it,
/// and write it back to QML.
void main() async {
  // -- Read: QML → mapstyler_style ----------------------------------------
  final style = _readQml(_categorizedQml);

  // -- Inspect the result --------------------------------------------------
  _printStyle(style);

  // -- Write: mapstyler_style → QML ---------------------------------------
  _writeQml(style);

  // -- Round-trip ----------------------------------------------------------
  print('\n--- Round-trip ---');
  final roundTripped = _roundTrip(_categorizedQml);
  _printStyle(roundTripped);
}

// ---------------------------------------------------------------------------
// Read direction
// ---------------------------------------------------------------------------

Style _readQml(String qmlXml) {
  const codec = Qml4DartCodec();
  final parseResult = codec.parseString(qmlXml);

  switch (parseResult) {
    case ReadQmlFailure(:final message):
      throw Exception('QML parse error: $message');
    case ReadQmlSuccess(:final document, :final warnings):
      for (final w in warnings) {
        print('QML parse warning: $w');
      }

      final result = convertDocument(document);
      switch (result) {
        case ReadStyleSuccess(:final output, warnings: final w):
          for (final warning in w) {
            print('Conversion warning: $warning');
          }
          return output;
        case ReadStyleFailure(:final errors):
          throw Exception('Conversion failed: $errors');
      }
  }
}

// ---------------------------------------------------------------------------
// Write direction
// ---------------------------------------------------------------------------

void _writeQml(Style style) {
  print('\n--- Write: mapstyler_style to QML ---');
  final result = convertStyle(style);

  switch (result) {
    case WriteStyleSuccess(:final output, :final warnings):
      for (final w in warnings) {
        print('Write warning: $w');
      }
      const codec = Qml4DartCodec();
      final xmlResult = codec.encodeString(output);
      if (xmlResult case WriteQmlSuccess(:final xml)) {
        print(xml);
      }
    case WriteStyleFailure(:final errors):
      print('Write failed: $errors');
  }
}

// ---------------------------------------------------------------------------
// Round-trip
// ---------------------------------------------------------------------------

Style _roundTrip(String qmlXml) {
  // QML XML → qml4dart → mapstyler_style → qml4dart → QML XML → repeat
  const codec = Qml4DartCodec();

  // Step 1: QML → mapstyler
  final doc1 = (codec.parseString(qmlXml) as ReadQmlSuccess).document;
  final style =
      (convertDocument(doc1) as ReadStyleSuccess).output;

  // Step 2: mapstyler → QML
  final doc2 =
      (convertStyle(style) as WriteStyleSuccess<QmlDocument>).output;

  // Step 3: QML → mapstyler again
  final restored =
      (convertDocument(doc2) as ReadStyleSuccess).output;

  return restored;
}

// ---------------------------------------------------------------------------
// Pretty-print
// ---------------------------------------------------------------------------

void _printStyle(Style style) {
  print('Style: ${style.name ?? '(unnamed)'}');
  print('Rules: ${style.rules.length}');
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
// Sample QML data
// ---------------------------------------------------------------------------

/// Categorized fill style with scale-based visibility.
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
