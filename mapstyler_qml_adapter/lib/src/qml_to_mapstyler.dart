import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:qml4dart/qml4dart.dart';

/// Converts [QmlDocument] values into [Style] values.
abstract class QmlToMapstylerAdapter {
  const QmlToMapstylerAdapter();

  Style toStyle(QmlDocument document);
}
