import 'package:mapstyler_style/mapstyler_style.dart';
import 'package:qml4dart/qml4dart.dart';

/// Converts [Style] values into [QmlDocument] values.
abstract class MapstylerToQmlAdapter {
  const MapstylerToQmlAdapter();

  QmlDocument toQmlDocument(Style style);
}
