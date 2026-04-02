/// Final coverage tests for remaining uncovered lines.
import 'package:flutter_map_sld/flutter_map_sld.dart' as sld;
import 'package:mapstyler_sld_adapter/src/mapstyler_to_sld.dart';
import 'package:mapstyler_sld_adapter/src/sld_to_mapstyler.dart';
import 'package:mapstyler_style/mapstyler_style.dart' as ms;
import 'package:test/test.dart';

void main() {
  // Read: TextSymbolizer with null label → warning + null return (line 255)
  test('Read: TextSymbolizer without label emits warning', () {
    final doc = _docWithRule(const sld.Rule(
      textSymbolizer: sld.TextSymbolizer(), // no label
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    expect(result.warnings, anyElement(contains('no label')));
    expect(result.output.rules.first.symbolizers, isEmpty);
  });

  // Read: RasterSymbolizer with ShadedRelief → warning (line 333)
  test('Read: RasterSymbolizer shadedRelief emits warning', () {
    final doc = _docWithRule(sld.Rule(
      rasterSymbolizer: sld.RasterSymbolizer(
        shadedRelief: const sld.ShadedRelief(),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    expect(result.warnings, anyElement(contains('ShadedRelief')));
  });

  // Read: RasterSymbolizer with VendorOptions → warning (line 336-337)
  test('Read: RasterSymbolizer vendorOptions emits warning', () {
    final doc = _docWithRule(sld.Rule(
      rasterSymbolizer: sld.RasterSymbolizer(
        vendorOptions: const [
          sld.VendorOption(name: 'foo', value: 'bar'),
        ],
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    expect(result.warnings, anyElement(contains('VendorOptions')));
  });

  // Read: ContrastEnhancement with ContrastMethod.none (line 401)
  test('Read: ContrastMethod.none converts to "none"', () {
    final doc = _docWithRule(sld.Rule(
      rasterSymbolizer: sld.RasterSymbolizer(
        contrastEnhancement: const sld.ContrastEnhancement(
          method: sld.ContrastMethod.none,
        ),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final raster =
        result.output.rules.first.symbolizers.first as ms.RasterSymbolizer;
    expect(raster.contrastEnhancement?.enhancementType, 'none');
  });

  // Read: neq, lte, gte filters (lines 417, 423, 425)
  test('Read: PropertyIsNotEqualTo', () {
    final doc = _docWithRule(const sld.Rule(
      filter: sld.PropertyIsNotEqualTo(
        expression1: sld.PropertyName('type'),
        expression2: sld.Literal('water'),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final cf = result.output.rules.first.filter as ms.ComparisonFilter;
    expect(cf.operator, ms.ComparisonOperator.neq);
  });

  test('Read: PropertyIsLessThanOrEqualTo', () {
    final doc = _docWithRule(const sld.Rule(
      filter: sld.PropertyIsLessThanOrEqualTo(
        expression1: sld.PropertyName('pop'),
        expression2: sld.Literal(1000),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final cf = result.output.rules.first.filter as ms.ComparisonFilter;
    expect(cf.operator, ms.ComparisonOperator.lte);
  });

  test('Read: PropertyIsGreaterThanOrEqualTo', () {
    final doc = _docWithRule(const sld.Rule(
      filter: sld.PropertyIsGreaterThanOrEqualTo(
        expression1: sld.PropertyName('pop'),
        expression2: sld.Literal(5000),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final cf = result.output.rules.first.filter as ms.ComparisonFilter;
    expect(cf.operator, ms.ComparisonOperator.gte);
  });

  // Read: _convertPropertyExpression with Literal (line 674)
  test('Read: Literal as property expression', () {
    final doc = _docWithRule(const sld.Rule(
      filter: sld.PropertyIsEqualTo(
        expression1: sld.Literal('literal_field'),
        expression2: sld.Literal('val'),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final cf = result.output.rules.first.filter as ms.ComparisonFilter;
    expect(cf.property, const ms.LiteralExpression('literal_field'));
  });

  // Read: Categorize in _convertExpressionToObject (line 738)
  test('Read: Categorize in nested expression context', () {
    final doc = _docWithRule(const sld.Rule(
      textSymbolizer: sld.TextSymbolizer(
        label: sld.Concatenate(expressions: [
          sld.Categorize(
            lookupValue: sld.PropertyName('pop'),
            thresholds: [sld.Literal(1000)],
            values: [sld.Literal('small'), sld.Literal('big')],
          ),
        ]),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final sym =
        result.output.rules.first.symbolizers.first as ms.TextSymbolizer;
    expect(sym.label, isA<ms.FunctionExpression<String>>());
    final strConcat =
        (sym.label as ms.FunctionExpression<String>).function as ms.ArgsFunction;
    expect(strConcat.name, 'strConcat');
    // The inner Categorize should become a StepFunction via _convertExpressionToObject
    expect(strConcat.args.first, isA<ms.FunctionExpression<Object>>());
    final inner =
        (strConcat.args.first as ms.FunctionExpression<Object>).function;
    expect(inner, isA<ms.StepFunction>());
  });

  // Read: Interpolate in nested expression context (line 739)
  test('Read: Interpolate in nested expression context', () {
    final doc = _docWithRule(const sld.Rule(
      textSymbolizer: sld.TextSymbolizer(
        label: sld.Concatenate(expressions: [
          sld.Interpolate(
            lookupValue: sld.PropertyName('temp'),
            dataPoints: [
              sld.InterpolationPoint(data: 0, value: sld.Literal('cold')),
              sld.InterpolationPoint(data: 30, value: sld.Literal('hot')),
            ],
          ),
        ]),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final sym =
        result.output.rules.first.symbolizers.first as ms.TextSymbolizer;
    final strConcat =
        (sym.label as ms.FunctionExpression<String>).function as ms.ArgsFunction;
    final inner =
        (strConcat.args.first as ms.FunctionExpression<Object>).function;
    expect(inner, isA<ms.InterpolateFunction>());
  });

  // Read: Recode in nested expression context (line 740)
  test('Read: Recode in nested expression context', () {
    final doc = _docWithRule(sld.Rule(
      textSymbolizer: sld.TextSymbolizer(
        label: sld.Concatenate(expressions: [
          sld.Recode(
            lookupValue: const sld.PropertyName('type'),
            mappings: const [
              sld.RecodeMapping(
                inputValue: sld.Literal('a'),
                outputValue: sld.Literal('alpha'),
              ),
            ],
          ),
        ]),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final sym =
        result.output.rules.first.symbolizers.first as ms.TextSymbolizer;
    final strConcat =
        (sym.label as ms.FunctionExpression<String>).function as ms.ArgsFunction;
    final inner =
        (strConcat.args.first as ms.FunctionExpression<Object>).function;
    expect(inner, isA<ms.CaseFunction>());
  });

  // Read: FormatNumber in nested _convertExpressionToObject (line 730-735)
  test('Read: FormatNumber in nested expression context', () {
    final doc = _docWithRule(const sld.Rule(
      textSymbolizer: sld.TextSymbolizer(
        label: sld.Concatenate(expressions: [
          sld.FormatNumber(
            numericValue: sld.PropertyName('val'),
            pattern: '#.#',
          ),
        ]),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final sym =
        result.output.rules.first.symbolizers.first as ms.TextSymbolizer;
    final strConcat =
        (sym.label as ms.FunctionExpression<String>).function as ms.ArgsFunction;
    final inner =
        (strConcat.args.first as ms.FunctionExpression<Object>).function
            as ms.ArgsFunction;
    expect(inner.name, 'numberFormat');
  });

  // Read: Concatenate in nested _convertExpressionToObject (line 725-728)
  test('Read: Concatenate in nested expression context', () {
    final doc = _docWithRule(const sld.Rule(
      textSymbolizer: sld.TextSymbolizer(
        label: sld.Concatenate(expressions: [
          sld.Concatenate(expressions: [
            sld.Literal('inner1'),
            sld.Literal('inner2'),
          ]),
        ]),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final sym =
        result.output.rules.first.symbolizers.first as ms.TextSymbolizer;
    final outer =
        (sym.label as ms.FunctionExpression<String>).function as ms.ArgsFunction;
    expect(outer.name, 'strConcat');
    final inner =
        (outer.args.first as ms.FunctionExpression<Object>).function
            as ms.ArgsFunction;
    expect(inner.name, 'strConcat');
  });

  // Read: empty Categorize values (EDGE-2, line 771-775)
  test('Read: Categorize with empty values uses fallback', () {
    final doc = _docWithRule(const sld.Rule(
      filter: sld.PropertyIsEqualTo(
        expression1: sld.PropertyName('cat'),
        expression2: sld.Categorize(
          lookupValue: sld.PropertyName('pop'),
          thresholds: [],
          values: [],
        ),
      ),
    ));
    final result = convertDocument(doc) as ms.ReadStyleSuccess;
    final cf = result.output.rules.first.filter as ms.ComparisonFilter;
    expect(cf.value, isA<ms.FunctionExpression<Object>>());
    final step =
        (cf.value as ms.FunctionExpression<Object>).function as ms.StepFunction;
    expect(step.stops, isEmpty);
  });

  // Write: ContrastEnhancement with 'none' (line 315 mapstyler_to_sld.dart)
  test('Write: ContrastEnhancement none round-trips', () {
    const style = ms.Style(rules: [
      ms.Rule(symbolizers: [
        ms.RasterSymbolizer(
          contrastEnhancement: ms.ContrastEnhancement(
            enhancementType: 'none',
            gammaValue: 1.0,
          ),
        ),
      ]),
    ]);
    final result = convertStyle(style) as ms.WriteStyleSuccess;
    final readBack =
        convertDocument(result.output) as ms.ReadStyleSuccess;
    final raster =
        readBack.output.rules.first.symbolizers.first as ms.RasterSymbolizer;
    expect(raster.contrastEnhancement?.enhancementType, 'none');
  });

  // Write: unknown FunctionExpression → Literal(null) fallback (line 512)
  test('Write: unknown FunctionExpression becomes Literal(null)', () {
    const unknownFunc = ms.FunctionExpression<Object>(ms.ArgsFunction(
      name: 'unknownOp',
      args: [],
    ));
    const style = ms.Style(rules: [
      ms.Rule(
        filter: ms.ComparisonFilter(
          operator: ms.ComparisonOperator.eq,
          property: ms.LiteralExpression('field'),
          value: unknownFunc,
        ),
      ),
    ]);
    final result = convertStyle(style) as ms.WriteStyleSuccess;
    final sldFilter = result.output.layers.first.styles.first
        .featureTypeStyles.first.rules.first.filter as sld.PropertyIsEqualTo;
    expect(sldFilter.expression2, isA<sld.Literal>());
    expect((sldFilter.expression2 as sld.Literal).value, isNull);
  });

  // Write: contrastEnhancement on per-channel (line 271-272)
  test('Write: per-channel contrastEnhancement round-trips', () {
    const style = ms.Style(rules: [
      ms.Rule(symbolizers: [
        ms.RasterSymbolizer(
          channelSelection: ms.ChannelSelection(
            grayChannel: ms.Channel(
              sourceChannelName: '1',
              contrastEnhancement: ms.ContrastEnhancement(
                enhancementType: 'histogram',
                gammaValue: 0.5,
              ),
            ),
          ),
        ),
      ]),
    ]);
    final result = convertStyle(style) as ms.WriteStyleSuccess;
    final sldRs = result.output.layers.first.styles.first
        .featureTypeStyles.first.rules.first.rasterSymbolizer!;
    expect(sldRs.channelSelection?.grayChannel?.contrastEnhancement?.method,
        sld.ContrastMethod.histogram);
    expect(sldRs.channelSelection?.grayChannel?.contrastEnhancement?.gammaValue,
        0.5);
  });
}

sld.SldDocument _docWithRule(sld.Rule rule) => sld.SldDocument(
      layers: [
        sld.SldLayer(
          styles: [
            sld.UserStyle(
              featureTypeStyles: [
                sld.FeatureTypeStyle(rules: [rule]),
              ],
            ),
          ],
        ),
      ],
    );
