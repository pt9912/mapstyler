import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:test/test.dart';

void main() {
  group('ComparisonFilter', () {
    test('fromJson parses == filter', () {
      final json = ['==', 'landuse', 'residential'];
      final filter = Filter.fromJson(json) as ComparisonFilter;
      expect(filter.operator, ComparisonOperator.eq);
      expect(
        (filter.property as LiteralExpression<String>).value,
        'landuse',
      );
      expect(
        (filter.value as LiteralExpression<Object>).value,
        'residential',
      );
    });

    test('fromJson parses numeric comparison', () {
      final json = ['>', 'population', 1000000];
      final filter = Filter.fromJson(json) as ComparisonFilter;
      expect(filter.operator, ComparisonOperator.gt);
      expect(
        (filter.value as LiteralExpression<Object>).value,
        1000000,
      );
    });

    test('all comparison operators round-trip', () {
      for (final op in ComparisonOperator.values) {
        final filter = ComparisonFilter(
          operator: op,
          property: const LiteralExpression('field'),
          value: const LiteralExpression<Object>('val'),
        );
        final json = filter.toJson();
        final restored = Filter.fromJson(json) as ComparisonFilter;
        expect(restored, filter);
      }
    });

    test('equality', () {
      const a = ComparisonFilter(
        operator: ComparisonOperator.eq,
        property: LiteralExpression('f'),
        value: LiteralExpression<Object>('v'),
      );
      const b = ComparisonFilter(
        operator: ComparisonOperator.eq,
        property: LiteralExpression('f'),
        value: LiteralExpression<Object>('v'),
      );
      const c = ComparisonFilter(
        operator: ComparisonOperator.neq,
        property: LiteralExpression('f'),
        value: LiteralExpression<Object>('v'),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CombinationFilter', () {
    test('fromJson parses && with sub-filters', () {
      final json = [
        '&&',
        ['==', 'type', 'road'],
        ['>', 'width', 5],
      ];
      final filter = Filter.fromJson(json) as CombinationFilter;
      expect(filter.operator, CombinationOperator.and);
      expect(filter.filters.length, 2);
      expect(filter.filters[0], isA<ComparisonFilter>());
      expect(filter.filters[1], isA<ComparisonFilter>());
    });

    test('fromJson parses || filter', () {
      final json = [
        '||',
        ['==', 'type', 'a'],
        ['==', 'type', 'b'],
        ['==', 'type', 'c'],
      ];
      final filter = Filter.fromJson(json) as CombinationFilter;
      expect(filter.operator, CombinationOperator.or);
      expect(filter.filters.length, 3);
    });

    test('round-trip', () {
      const filter = CombinationFilter(
        operator: CombinationOperator.and,
        filters: [
          ComparisonFilter(
            operator: ComparisonOperator.eq,
            property: LiteralExpression('a'),
            value: LiteralExpression<Object>(1),
          ),
          ComparisonFilter(
            operator: ComparisonOperator.lt,
            property: LiteralExpression('b'),
            value: LiteralExpression<Object>(10),
          ),
        ],
      );
      final json = filter.toJson();
      final restored = Filter.fromJson(json);
      expect(restored, filter);
    });
  });

  group('NegationFilter', () {
    test('fromJson parses ! filter', () {
      final json = [
        '!',
        ['==', 'hidden', true],
      ];
      final filter = Filter.fromJson(json) as NegationFilter;
      final inner = filter.filter as ComparisonFilter;
      expect(inner.operator, ComparisonOperator.eq);
    });

    test('round-trip', () {
      const filter = NegationFilter(
        filter: ComparisonFilter(
          operator: ComparisonOperator.eq,
          property: LiteralExpression('x'),
          value: LiteralExpression<Object>('y'),
        ),
      );
      final json = filter.toJson();
      final restored = Filter.fromJson(json);
      expect(restored, filter);
    });
  });

  group('SpatialFilter', () {
    test('fromJson parses bbox without propertyName', () {
      final json = [
        'bbox',
        {
          'type': 'Envelope',
          'bbox': [7.0, 46.0, 9.0, 48.0],
        },
      ];
      final filter = Filter.fromJson(json) as SpatialFilter;
      expect(filter.operator, SpatialOperator.bbox);
      expect(filter.propertyName, isNull);
      expect(filter.geometry, isA<EnvelopeGeometry>());
    });

    test('fromJson parses intersects with propertyName', () {
      final json = [
        'intersects',
        'the_geom',
        {
          'type': 'Point',
          'coordinates': [8.5, 47.3],
        },
      ];
      final filter = Filter.fromJson(json) as SpatialFilter;
      expect(filter.operator, SpatialOperator.intersects);
      expect(filter.propertyName, 'the_geom');
      expect(filter.geometry, isA<PointGeometry>());
    });

    test('all spatial operators round-trip without propertyName', () {
      for (final op in SpatialOperator.values) {
        final filter = SpatialFilter(
          operator: op,
          geometry: const PointGeometry(8.5, 47.3),
        );
        final json = filter.toJson();
        final restored = Filter.fromJson(json) as SpatialFilter;
        expect(restored, filter, reason: 'Failed for ${op.name}');
      }
    });

    test('round-trip with propertyName', () {
      const filter = SpatialFilter(
        operator: SpatialOperator.within,
        propertyName: 'geom',
        geometry: PolygonGeometry([
          [(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 0.0)],
        ]),
      );
      final json = filter.toJson();
      final restored = Filter.fromJson(json);
      expect(restored, filter);
    });

    test('equality', () {
      const a = SpatialFilter(
        operator: SpatialOperator.bbox,
        geometry: EnvelopeGeometry(minX: 0, minY: 0, maxX: 1, maxY: 1),
      );
      const b = SpatialFilter(
        operator: SpatialOperator.bbox,
        geometry: EnvelopeGeometry(minX: 0, minY: 0, maxX: 1, maxY: 1),
      );
      const c = SpatialFilter(
        operator: SpatialOperator.contains,
        geometry: EnvelopeGeometry(minX: 0, minY: 0, maxX: 1, maxY: 1),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('DistanceFilter', () {
    test('fromJson parses dWithin without propertyName', () {
      final json = [
        'dWithin',
        {'type': 'Point', 'coordinates': [8.5, 47.3]},
        1000.0,
        'm',
      ];
      final filter = Filter.fromJson(json) as DistanceFilter;
      expect(filter.operator, DistanceOperator.dWithin);
      expect(filter.propertyName, isNull);
      expect(filter.geometry, isA<PointGeometry>());
      expect(filter.distance, 1000.0);
      expect(filter.units, 'm');
    });

    test('fromJson parses beyond with propertyName', () {
      final json = [
        'beyond',
        'location',
        {'type': 'Point', 'coordinates': [0.0, 0.0]},
        5000.0,
        'km',
      ];
      final filter = Filter.fromJson(json) as DistanceFilter;
      expect(filter.operator, DistanceOperator.beyond);
      expect(filter.propertyName, 'location');
      expect(filter.distance, 5000.0);
      expect(filter.units, 'km');
    });

    test('round-trip without propertyName', () {
      const filter = DistanceFilter(
        operator: DistanceOperator.dWithin,
        geometry: PointGeometry(8.5, 47.3),
        distance: 500.0,
        units: 'm',
      );
      final json = filter.toJson();
      final restored = Filter.fromJson(json);
      expect(restored, filter);
    });

    test('round-trip with propertyName', () {
      const filter = DistanceFilter(
        operator: DistanceOperator.beyond,
        propertyName: 'geom',
        geometry: PointGeometry(0.0, 0.0),
        distance: 100.0,
        units: 'km',
      );
      final json = filter.toJson();
      final restored = Filter.fromJson(json);
      expect(restored, filter);
    });

    test('equality', () {
      const a = DistanceFilter(
        operator: DistanceOperator.dWithin,
        geometry: PointGeometry(0, 0),
        distance: 100,
        units: 'm',
      );
      const b = DistanceFilter(
        operator: DistanceOperator.dWithin,
        geometry: PointGeometry(0, 0),
        distance: 100,
        units: 'm',
      );
      const c = DistanceFilter(
        operator: DistanceOperator.dWithin,
        geometry: PointGeometry(0, 0),
        distance: 200,
        units: 'm',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('Nested filters', () {
    test('combination with spatial sub-filter round-trips', () {
      const filter = CombinationFilter(
        operator: CombinationOperator.and,
        filters: [
          ComparisonFilter(
            operator: ComparisonOperator.eq,
            property: LiteralExpression('type'),
            value: LiteralExpression<Object>('building'),
          ),
          SpatialFilter(
            operator: SpatialOperator.bbox,
            geometry:
                EnvelopeGeometry(minX: 7, minY: 46, maxX: 9, maxY: 48),
          ),
        ],
      );
      final json = filter.toJson();
      final restored = Filter.fromJson(json);
      expect(restored, filter);
    });

    test('negated spatial filter round-trips', () {
      const filter = NegationFilter(
        filter: SpatialFilter(
          operator: SpatialOperator.disjoint,
          geometry: PointGeometry(8.5, 47.3),
        ),
      );
      final json = filter.toJson();
      final restored = Filter.fromJson(json);
      expect(restored, filter);
    });
  });
}
