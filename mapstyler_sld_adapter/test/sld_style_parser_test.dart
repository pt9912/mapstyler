import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:mapstyler_sld_adapter/mapstyler_sld_adapter.dart';
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:test/test.dart';

void main() {
  group('SldStyleParser', () {
    const parser = SldStyleParser();

    test('has title "SLD"', () {
      expect(parser.title, 'SLD');
    });

    test('readStyle converts SLD document to Style', () async {
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

      final result = await parser.readStyle(doc);
      expect(result, isA<ms.ReadStyleSuccess>());
      final success = result as ms.ReadStyleSuccess;
      expect(success.output.name, 'Roads');
      expect(success.output.rules, hasLength(1));
      expect(success.output.rules.first.name, 'Highways');
      expect(success.output.rules.first.symbolizers.first,
          isA<ms.LineSymbolizer>());
    });

    test('writeStyle converts Style to SLD document', () async {
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

      final result = await parser.writeStyle(style);
      expect(result, isA<ms.WriteStyleSuccess<sld.SldDocument>>());
      final success = result as ms.WriteStyleSuccess<sld.SldDocument>;
      expect(success.output.layers.first.name, 'Buildings');
    });

    test('readStyle → writeStyle round-trip', () async {
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
                        stroke: sld.Stroke(colorArgb: 0xFF006400, width: 1.0),
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
      final readResult = await parser.readStyle(doc);
      final style = (readResult as ms.ReadStyleSuccess).output;

      // Write back
      final writeResult = await parser.writeStyle(style);
      final docOut = (writeResult as ms.WriteStyleSuccess).output;

      // Read again
      final readResult2 = await parser.readStyle(docOut);
      final style2 = (readResult2 as ms.ReadStyleSuccess).output;

      // Compare
      expect(style2.name, style.name);
      expect(style2.rules.length, style.rules.length);
      expect(style2.rules.first.name, style.rules.first.name);
    });
  });
}
