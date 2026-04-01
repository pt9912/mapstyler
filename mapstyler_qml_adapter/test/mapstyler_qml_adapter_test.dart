import 'package:mapstyler_qml_adapter/mapstyler_qml_adapter.dart';
import 'package:test/test.dart';

void main() {
  test('library exports adapter types', () {
    expect(QmlToMapstylerAdapter, isNotNull);
    expect(MapstylerToQmlAdapter, isNotNull);
  });
}
