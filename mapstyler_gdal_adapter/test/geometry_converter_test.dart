import 'package:mapstyler_gdal_adapter/mapstyler_gdal_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('VectorLayerInfo', () {
    test('const construction', () {
      const info = VectorLayerInfo(
        name: 'places',
        featureCount: 42,
        fields: [(name: 'name', type: 'string')],
        extent: (minX: 0, minY: 0, maxX: 10, maxY: 10),
      );
      expect(info.name, 'places');
      expect(info.featureCount, 42);
      expect(info.fields, hasLength(1));
      expect(info.extent?.minX, 0);
    });

    test('default values', () {
      const info = VectorLayerInfo(name: 'empty', featureCount: -1);
      expect(info.fields, isEmpty);
      expect(info.extent, isNull);
    });
  });
}
