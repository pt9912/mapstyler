import 'dart:convert';

import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('ScaleDenominator', () {
    test('fromJson parses min/max', () {
      final sd = ScaleDenominator.fromJson({'min': 0, 'max': 50000});
      expect(sd.min, 0.0);
      expect(sd.max, 50000.0);
    });

    test('fromJson with only min', () {
      final sd = ScaleDenominator.fromJson({'min': 1000});
      expect(sd.min, 1000.0);
      expect(sd.max, isNull);
    });

    test('round-trip', () {
      final json = {'min': 0.0, 'max': 50000.0};
      final sd = ScaleDenominator.fromJson(json);
      expect(sd.toJson(), json);
    });

    test('equality', () {
      const a = ScaleDenominator(min: 0, max: 50000);
      const b = ScaleDenominator(min: 0, max: 50000);
      const c = ScaleDenominator(min: 1000, max: 50000);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Rule', () {
    test('fromJson parses complete rule', () {
      final json = {
        'name': 'Wohngebiet',
        'filter': ['==', 'landuse', 'residential'],
        'scaleDenominator': {'min': 0, 'max': 50000},
        'symbolizers': [
          {'kind': 'Fill', 'color': '#ffcc00', 'opacity': 0.5},
        ],
      };
      final rule = Rule.fromJson(json);
      expect(rule.name, 'Wohngebiet');
      expect(rule.filter, isA<ComparisonFilter>());
      expect(rule.scaleDenominator, isNotNull);
      expect(rule.symbolizers.length, 1);
      expect(rule.symbolizers[0], isA<FillSymbolizer>());
    });

    test('fromJson minimal rule', () {
      final json = {
        'symbolizers': <dynamic>[],
      };
      final rule = Rule.fromJson(json);
      expect(rule.name, isNull);
      expect(rule.filter, isNull);
      expect(rule.scaleDenominator, isNull);
      expect(rule.symbolizers, isEmpty);
    });

    test('fromJson with multiple symbolizers', () {
      final json = {
        'name': 'Hospital',
        'symbolizers': [
          {
            'kind': 'Mark',
            'wellKnownName': 'cross',
            'color': '#ff0000',
            'radius': 8.0,
          },
          {
            'kind': 'Text',
            'label': {'name': 'property', 'args': ['name']},
            'size': 12.0,
          },
        ],
      };
      final rule = Rule.fromJson(json);
      expect(rule.symbolizers.length, 2);
      expect(rule.symbolizers[0], isA<MarkSymbolizer>());
      expect(rule.symbolizers[1], isA<TextSymbolizer>());
    });

    test('round-trip', () {
      final rule = Rule(
        name: 'Test',
        filter: const ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('type'),
          value: LiteralExpression<Object>('road'),
        ),
        symbolizers: const [
          LineSymbolizer(
            color: LiteralExpression('#333'),
            width: LiteralExpression(2.0),
          ),
        ],
        scaleDenominator: const ScaleDenominator(min: 0, max: 100000),
      );
      final json = rule.toJson();
      final restored = Rule.fromJson(json);
      expect(restored, rule);
    });

    test('equality', () {
      final a = Rule(name: 'R1', symbolizers: const []);
      final b = Rule(name: 'R1', symbolizers: const []);
      final c = Rule(name: 'R2', symbolizers: const []);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Style', () {
    test('fromJson parses complete style', () {
      final json = {
        'name': 'Flächennutzung',
        'rules': [
          {
            'name': 'Wohngebiet',
            'filter': ['==', 'landuse', 'residential'],
            'symbolizers': [
              {'kind': 'Fill', 'color': '#ffcc00', 'opacity': 0.5},
            ],
          },
          {
            'name': 'Wald',
            'filter': ['==', 'landuse', 'forest'],
            'symbolizers': [
              {'kind': 'Fill', 'color': '#228B22', 'opacity': 0.6},
            ],
          },
        ],
      };
      final style = Style.fromJson(json);
      expect(style.name, 'Flächennutzung');
      expect(style.rules.length, 2);
      expect(style.rules[0].name, 'Wohngebiet');
      expect(style.rules[1].name, 'Wald');
    });

    test('fromJson empty style', () {
      final style = Style.fromJson({});
      expect(style.name, isNull);
      expect(style.rules, isEmpty);
    });

    test('fromJsonString', () {
      const jsonString = '{"name":"test","rules":[]}';
      final style = Style.fromJsonString(jsonString);
      expect(style.name, 'test');
      expect(style.rules, isEmpty);
    });

    test('toJsonString', () {
      final style = Style(name: 'test');
      final jsonString = style.toJsonString();
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['name'], 'test');
      expect(decoded['rules'], isEmpty);
    });

    test('round-trip', () {
      final style = Style(
        name: 'Complete',
        rules: [
          Rule(
            name: 'Roads',
            filter: const CombinationFilter(
              operator: CombinationOperator.and,
              filters: [
                ComparisonFilter(
                  operator: ComparisonOperator.eq,
                  property: LiteralExpression('type'),
                  value: LiteralExpression<Object>('road'),
                ),
                ComparisonFilter(
                  operator: ComparisonOperator.gt,
                  property: LiteralExpression('width'),
                  value: LiteralExpression<Object>(3),
                ),
              ],
            ),
            symbolizers: const [
              LineSymbolizer(
                color: LiteralExpression('#333333'),
                width: LiteralExpression(2.0),
              ),
            ],
            scaleDenominator: const ScaleDenominator(min: 0, max: 100000),
          ),
          Rule(
            name: 'Labels',
            symbolizers: const [
              TextSymbolizer(
                label: FunctionExpression(PropertyGet('name')),
                size: LiteralExpression(12.0),
              ),
            ],
          ),
        ],
      );
      final json = style.toJson();
      final restored = Style.fromJson(json);
      expect(restored, style);
    });

    test('round-trip via JSON string', () {
      final style = Style(
        name: 'StringTest',
        rules: [
          Rule(
            name: 'Fill',
            symbolizers: const [
              FillSymbolizer(color: LiteralExpression('#ff0000')),
            ],
          ),
        ],
      );
      final jsonString = style.toJsonString();
      final restored = Style.fromJsonString(jsonString);
      expect(restored, style);
    });

    test('equality', () {
      final a = Style(name: 'S');
      final b = Style(name: 'S');
      final c = Style(name: 'X');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ScaleDenominator.copyWith', () {
    test('replaces single field', () {
      const sd = ScaleDenominator(min: 0, max: 50000);
      final copy = sd.copyWith(min: 1000.0);
      expect(copy.min, 1000.0);
      expect(copy.max, 50000);
    });

    test('clears nullable field with explicit null', () {
      const sd = ScaleDenominator(min: 0, max: 50000);
      final copy = sd.copyWith(max: null);
      expect(copy.min, 0);
      expect(copy.max, isNull);
    });

    test('omitted fields keep current value', () {
      const sd = ScaleDenominator(min: 100, max: 9999);
      final copy = sd.copyWith();
      expect(copy, sd);
    });
  });

  group('Rule.copyWith', () {
    test('replaces name', () {
      final rule = Rule(name: 'A');
      final copy = rule.copyWith(name: 'B');
      expect(copy.name, 'B');
    });

    test('replaces symbolizers', () {
      final rule = Rule(
        symbolizers: const [
          FillSymbolizer(color: LiteralExpression('#f00')),
        ],
      );
      final copy = rule.copyWith(symbolizers: const [
        LineSymbolizer(color: LiteralExpression('#333')),
      ]);
      expect(copy.symbolizers, hasLength(1));
      expect(copy.symbolizers.first, isA<LineSymbolizer>());
    });

    test('clears filter with explicit null', () {
      final rule = Rule(
        filter: const ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('x'),
          value: LiteralExpression<Object>(1),
        ),
      );
      final copy = rule.copyWith(filter: null);
      expect(copy.filter, isNull);
    });

    test('clears scaleDenominator with explicit null', () {
      final rule = Rule(
        scaleDenominator: const ScaleDenominator(min: 0, max: 100),
      );
      final copy = rule.copyWith(scaleDenominator: null);
      expect(copy.scaleDenominator, isNull);
    });

    test('omitted fields keep current value', () {
      final rule = Rule(
        name: 'R',
        filter: const ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('a'),
          value: LiteralExpression<Object>('b'),
        ),
        symbolizers: const [FillSymbolizer()],
        scaleDenominator: const ScaleDenominator(min: 0),
      );
      final copy = rule.copyWith();
      expect(copy, rule);
    });

    test('copyWith round-trips through JSON', () {
      final rule = Rule(
        name: 'Original',
        symbolizers: const [
          FillSymbolizer(color: LiteralExpression('#ff0000')),
        ],
      );
      final modified = rule.copyWith(name: 'Modified');
      final json = modified.toJson();
      final restored = Rule.fromJson(json);
      expect(restored, modified);
    });
  });

  group('Style.copyWith', () {
    test('replaces name', () {
      final style = Style(name: 'A');
      final copy = style.copyWith(name: 'B');
      expect(copy.name, 'B');
      expect(copy.rules, isEmpty);
    });

    test('clears name with explicit null', () {
      final style = Style(name: 'A');
      final copy = style.copyWith(name: null);
      expect(copy.name, isNull);
    });

    test('replaces rules', () {
      final style = Style(name: 'S', rules: [Rule(name: 'R1')]);
      final copy = style.copyWith(rules: [Rule(name: 'R2')]);
      expect(copy.name, 'S');
      expect(copy.rules, hasLength(1));
      expect(copy.rules.first.name, 'R2');
    });

    test('omitted fields keep current value', () {
      final style = Style(
        name: 'Keep',
        rules: [Rule(name: 'R')],
      );
      final copy = style.copyWith();
      expect(copy, style);
    });

    test('copyWith round-trips through JSON', () {
      final style = Style(
        name: 'Original',
        rules: [
          Rule(symbolizers: const [
            FillSymbolizer(color: LiteralExpression('#ff0000')),
          ]),
        ],
      );
      final modified = style.copyWith(name: 'Modified');
      final json = modified.toJson();
      final restored = Style.fromJson(json);
      expect(restored, modified);
    });
  });

  group('List immutability', () {
    test('Style.rules is unmodifiable', () {
      final style = Style(rules: [Rule(name: 'A')]);
      expect(() => style.rules.add(Rule(name: 'B')),
          throwsA(isA<UnsupportedError>()));
    });

    test('Rule.symbolizers is unmodifiable', () {
      final rule = Rule(symbolizers: const [FillSymbolizer()]);
      expect(() => rule.symbolizers.add(const LineSymbolizer()),
          throwsA(isA<UnsupportedError>()));
    });

    test('Style.rules defensive copy protects against external mutation', () {
      final list = <Rule>[Rule(name: 'A')];
      final style = Style(rules: list);
      list.add(Rule(name: 'B'));
      expect(style.rules, hasLength(1));
    });

    test('Rule.symbolizers defensive copy protects against external mutation', () {
      final list = <Symbolizer>[const FillSymbolizer()];
      final rule = Rule(symbolizers: list);
      list.add(const LineSymbolizer());
      expect(rule.symbolizers, hasLength(1));
    });
  });

  group('Full GeoStyler JSON example', () {
    test('parses the README example', () {
      final json = {
        'name': 'Flächennutzung',
        'rules': [
          {
            'name': 'Wohngebiet',
            'filter': ['==', 'landuse', 'residential'],
            'symbolizers': [
              {'kind': 'Fill', 'color': '#ffcc00', 'opacity': 0.5},
            ],
          },
        ],
      };
      final style = Style.fromJson(json);
      expect(style.name, 'Flächennutzung');
      expect(style.rules.length, 1);

      final rule = style.rules[0];
      expect(rule.name, 'Wohngebiet');

      final filter = rule.filter as ComparisonFilter;
      expect(filter.operator, ComparisonOperator.eq);
      expect(
        (filter.property as LiteralExpression<String>).value,
        'landuse',
      );

      final sym = rule.symbolizers[0] as FillSymbolizer;
      expect((sym.color as LiteralExpression<String>).value, '#ffcc00');
      expect((sym.opacity as LiteralExpression<double>).value, 0.5);
    });

    test('parses complex GeoStyler JSON from docs', () {
      final json = {
        'name': 'Flächennutzungsplan',
        'rules': [
          {
            'name': 'Wohngebiet',
            'filter': ['==', 'landuse', 'residential'],
            'scaleDenominator': {'min': 0, 'max': 50000},
            'symbolizers': [
              {
                'kind': 'Fill',
                'color': '#ffcc00',
                'opacity': 0.5,
                'outlineColor': '#aa8800',
                'outlineWidth': 1.5,
              },
            ],
          },
          {
            'name': 'Straßen',
            'filter': ['==', 'type', 'road'],
            'symbolizers': [
              {
                'kind': 'Line',
                'color': '#333333',
                'width': 2.0,
                'dasharray': [10.0, 5.0],
                'cap': 'round',
                'join': 'round',
              },
            ],
          },
          {
            'name': 'Krankenhäuser',
            'filter': ['==', 'amenity', 'hospital'],
            'symbolizers': [
              {
                'kind': 'Mark',
                'wellKnownName': 'cross',
                'color': '#ff0000',
                'radius': 8.0,
                'strokeColor': '#990000',
                'strokeWidth': 1.0,
              },
              {
                'kind': 'Text',
                'label': {'name': 'property', 'args': ['name']},
                'size': 12.0,
                'color': '#333333',
                'haloColor': '#ffffff',
                'haloWidth': 2.0,
              },
            ],
          },
        ],
      };

      final style = Style.fromJson(json);
      expect(style.rules.length, 3);
      expect(style.rules[0].symbolizers[0], isA<FillSymbolizer>());
      expect(style.rules[1].symbolizers[0], isA<LineSymbolizer>());
      expect(style.rules[2].symbolizers.length, 2);
      expect(style.rules[2].symbolizers[0], isA<MarkSymbolizer>());
      expect(style.rules[2].symbolizers[1], isA<TextSymbolizer>());

      // Round-trip the whole thing
      final restored = Style.fromJson(style.toJson());
      expect(restored, style);
    });
  });
}
