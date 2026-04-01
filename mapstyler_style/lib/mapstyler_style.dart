/// Core types for cartographic styling — compatible with the GeoStyler
/// JSON format.
///
/// This package provides the common type system for the mapstyler
/// ecosystem: [Style], [Rule], [Symbolizer], [Filter], [Expression],
/// and the [StyleParser] interface.
///
/// ```dart
/// import 'package:mapstyler_style/mapstyler_style.dart';
///
/// final style = Style.fromJson({
///   'name': 'Example',
///   'rules': [
///     {
///       'name': 'Buildings',
///       'filter': ['==', 'type', 'building'],
///       'symbolizers': [
///         {'kind': 'Fill', 'color': '#cc0000'},
///       ],
///     },
///   ],
/// });
/// ```
library mapstyler_style;

export 'src/expression.dart';
export 'src/filter.dart';
export 'src/function.dart';
export 'src/geometry.dart';
export 'src/parser.dart';
export 'src/rule.dart';
export 'src/style.dart';
export 'src/symbolizer.dart';
