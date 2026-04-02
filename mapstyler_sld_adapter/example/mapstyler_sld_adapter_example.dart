import 'package:mapstyler_sld_adapter/mapstyler_sld_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

/// Example: parse SLD XML via the adapter and inspect the result.
void main() async {
  final parser = SldStyleParser();

  // -- Read: SLD XML → mapstyler Style ------------------------------------
  print('--- SLD → mapstyler_style ---');
  final result = await parser.readStyle(_sampleSld);

  switch (result) {
    case ReadStyleSuccess(:final output, :final warnings):
      for (final w in warnings) {
        print('  Warning: $w');
      }
      _printStyle(output);

    case ReadStyleFailure(:final errors):
      print('  Failed: $errors');
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
// Sample SLD XML
// ---------------------------------------------------------------------------

const _sampleSld = '''
<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
    xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
    xmlns="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>Land use</Name>
    <UserStyle>
      <Name>Land use style</Name>
      <FeatureTypeStyle>
        <Rule>
          <Name>Residential</Name>
          <ogc:Filter>
            <ogc:PropertyIsEqualTo>
              <ogc:PropertyName>landuse</ogc:PropertyName>
              <ogc:Literal>residential</ogc:Literal>
            </ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <MinScaleDenominator>0</MinScaleDenominator>
          <MaxScaleDenominator>50000</MaxScaleDenominator>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#ffcc00</CssParameter>
              <CssParameter name="fill-opacity">0.5</CssParameter>
            </Fill>
            <Stroke>
              <CssParameter name="stroke">#aa8800</CssParameter>
              <CssParameter name="stroke-width">1.5</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
        </Rule>
        <Rule>
          <Name>Roads</Name>
          <LineSymbolizer>
            <Stroke>
              <CssParameter name="stroke">#333333</CssParameter>
              <CssParameter name="stroke-width">2.0</CssParameter>
            </Stroke>
          </LineSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
''';
