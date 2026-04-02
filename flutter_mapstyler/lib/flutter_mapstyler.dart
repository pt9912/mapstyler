/// Bridges `mapstyler_style` with `flutter_map`.
///
/// The package evaluates mapstyler expressions and filters against
/// [StyledFeature] data, then converts matching symbolizers into
/// `flutter_map` layer widgets.
library flutter_mapstyler;

export 'src/color_parser.dart';
export 'src/expression_evaluator.dart' show evaluateExpression;
export 'src/feature.dart';
export 'src/filter_evaluator.dart' show evaluateFilter;
export 'src/mark_painter.dart';
export 'src/style_renderer.dart';
