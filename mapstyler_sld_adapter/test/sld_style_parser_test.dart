import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:mapstyler_sld_adapter/mapstyler_sld_adapter.dart';
import 'package:mapstyler_sld_adapter/src/sld_to_mapstyler.dart';
import 'package:mapstyler_sld_adapter/src/mapstyler_to_sld.dart';
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:test/test.dart';

void main() {
  group('SldStyleParser', () {
    const parser = SldStyleParser();

    test('has title "SLD"', () {
      expect(parser.title, 'SLD');
    });

    test('readStyle parses SLD XML string', () async {
      const sldXml = '''
<StyledLayerDescriptor version="1.0.0"
    xmlns="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>Roads</Name>
    <UserStyle>
      <FeatureTypeStyle>
        <Rule>
          <Name>Highways</Name>
          <LineSymbolizer>
            <Stroke>
              <CssParameter name="stroke">#ff0000</CssParameter>
              <CssParameter name="stroke-width">3.0</CssParameter>
            </Stroke>
          </LineSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
''';

      final result = await parser.readStyle(sldXml);
      expect(result, isA<ms.ReadStyleSuccess>());
      final success = result as ms.ReadStyleSuccess;
      expect(success.output.name, 'Roads');
      expect(success.output.rules, hasLength(1));
      expect(success.output.rules.first.name, 'Highways');
      expect(success.output.rules.first.symbolizers.first,
          isA<ms.LineSymbolizer>());
    });
  });

  group('convertDocument (internal)', () {
    test('converts SLD document to Style', () {
      final doc = sld.SldDocument(
        layers: [
          sld.SldLayer(
            name: 'Roads',
            styles: [
              sld.UserStyle(
                featureTypeStyles: [
                  sld.FeatureTypeStyle(rules: [
                    const sld.Rule(
                      name: 'Highways',
                      lineSymbolizer: sld.LineSymbolizer(
                        stroke: sld.Stroke(
                          colorArgb: 0xFFFF0000,
                          width: 3.0,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ],
      );

      final result = convertDocument(doc);
      expect(result, isA<ms.ReadStyleSuccess>());
      final success = result as ms.ReadStyleSuccess;
      expect(success.output.name, 'Roads');
      expect(success.output.rules, hasLength(1));
    });
  });

  group('convertStyle (internal)', () {
    test('converts Style to SLD document', () {
      const style = ms.Style(
        name: 'Buildings',
        rules: [
          ms.Rule(
            name: 'Residential',
            filter: ms.ComparisonFilter(
              operator: ms.ComparisonOperator.eq,
              property: ms.LiteralExpression('type'),
              value: ms.LiteralExpression('residential'),
            ),
            symbolizers: [
              ms.FillSymbolizer(
                color: ms.LiteralExpression('#ffcc00'),
              ),
            ],
          ),
        ],
      );

      final result = convertStyle(style);
      expect(result, isA<ms.WriteStyleSuccess<sld.SldDocument>>());
      final success = result as ms.WriteStyleSuccess<sld.SldDocument>;
      expect(success.output.layers.first.name, 'Buildings');
    });
  });

  group('round-trip (internal)', () {
    test('readStyle → writeStyle round-trip', () {
      final doc = sld.SldDocument(
        layers: [
          sld.SldLayer(
            name: 'Landuse',
            styles: [
              sld.UserStyle(
                featureTypeStyles: [
                  sld.FeatureTypeStyle(rules: [
                    const sld.Rule(
                      name: 'Forest',
                      polygonSymbolizer: sld.PolygonSymbolizer(
                        fill: sld.Fill(colorArgb: 0xFF228B22),
                        stroke:
                            sld.Stroke(colorArgb: 0xFF006400, width: 1.0),
                      ),
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ],
      );

      // Read
      final readResult = convertDocument(doc);
      final style = (readResult as ms.ReadStyleSuccess).output;

      // Write back
      final writeResult = convertStyle(style);
      final docOut =
          (writeResult as ms.WriteStyleSuccess<sld.SldDocument>).output;

      // Read again
      final readResult2 = convertDocument(docOut);
      final style2 = (readResult2 as ms.ReadStyleSuccess).output;

      // Compare
      expect(style2.name, style.name);
      expect(style2.rules.length, style.rules.length);
      expect(style2.rules.first.name, style.rules.first.name);
    });
  });
}
