import 'package:qml4dart/qml4dart.dart';
import 'package:test/test.dart';

void main() {
  test('QmlDocument can be constructed', () {
    const document = QmlDocument(
      renderer: QmlRenderer(type: QmlRendererType.unknown),
    );

    expect(document.renderer.type, QmlRendererType.unknown);
  });
}
