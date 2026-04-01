import 'expression.dart';

/// GeoStyler function — JSON: {"name": "functionName", "args": [...]}
sealed class GeoStylerFunction {
  const GeoStylerFunction();

  String get name;

  factory GeoStylerFunction.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return switch (name) {
      'property' => PropertyGet._fromJson(json),
      'case' => CaseFunction._fromJson(json),
      'step' => StepFunction._fromJson(json),
      'interpolate' => InterpolateFunction._fromJson(json),
      _ => ArgsFunction._fromJson(json),
    };
  }

  Map<String, dynamic> toJson();
}

// -- PropertyGet --

final class PropertyGet extends GeoStylerFunction {
  final String propertyName;
  const PropertyGet(this.propertyName);

  @override
  String get name => 'property';

  factory PropertyGet._fromJson(Map<String, dynamic> json) {
    final args = json['args'] as List;
    return PropertyGet(args[0] as String);
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': 'property',
        'args': [propertyName],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyGet && propertyName == other.propertyName;

  @override
  int get hashCode => propertyName.hashCode;
}

// -- ArgsFunction --

/// Generic function for simple math/string/boolean operations.
///
/// Numeric: add, subtract, multiply, divide, modulo, pow, abs, ceil, floor,
///   round, sqrt, log, exp, min, max, pi, random, rint,
///   acos, asin, atan, atan2, cos, sin, tan, toDegrees, toRadians
///
/// String: strConcat, strToLowerCase, strToUpperCase, strTrim,
///   strLength, strSubstring, strReplace, strIndexOf,
///   strStartsWith, strEndsWith, strMatches, numberFormat
///
/// Boolean: all, any, between, equalTo, notEqualTo,
///   greaterThan, greaterThanOrEqualTo, lessThan, lessThanOrEqualTo,
///   in, parseBoolean, not
final class ArgsFunction extends GeoStylerFunction {
  @override
  final String name;
  final List<Expression<Object>> args;

  const ArgsFunction({required this.name, this.args = const []});

  factory ArgsFunction._fromJson(Map<String, dynamic> json) => ArgsFunction(
        name: json['name'] as String,
        args: (json['args'] as List<dynamic>? ?? [])
            .map((a) => Expression.fromJson<Object>(a, (v) => v as Object))
            .toList(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'args': args.map((a) => a.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArgsFunction &&
          name == other.name &&
          _listEquals(args, other.args);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(args));
}

// -- CaseFunction --

final class CaseParameter {
  final Expression<Object> condition;
  final Expression<Object> value;

  const CaseParameter({required this.condition, required this.value});

  factory CaseParameter.fromJson(Map<String, dynamic> json) => CaseParameter(
        condition:
            Expression.fromJson<Object>(json['case'], (v) => v as Object),
        value:
            Expression.fromJson<Object>(json['value'], (v) => v as Object),
      );

  Map<String, dynamic> toJson() => {
        'case': condition.toJson(),
        'value': value.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseParameter &&
          condition == other.condition &&
          value == other.value;

  @override
  int get hashCode => Object.hash(condition, value);
}

/// GeoStyler case function:
/// {"name": "case", "args": [{case: expr, value: expr}, ..., fallback]}
final class CaseFunction extends GeoStylerFunction {
  final List<CaseParameter> cases;
  final Expression<Object> fallback;

  const CaseFunction({required this.cases, required this.fallback});

  @override
  String get name => 'case';

  factory CaseFunction._fromJson(Map<String, dynamic> json) {
    final args = json['args'] as List<dynamic>;
    final cases = <CaseParameter>[];
    for (var i = 0; i < args.length - 1; i++) {
      cases.add(
          CaseParameter.fromJson(args[i] as Map<String, dynamic>));
    }
    final fallback = Expression.fromJson<Object>(
        args.last, (v) => v as Object);
    return CaseFunction(cases: cases, fallback: fallback);
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': 'case',
        'args': [
          ...cases.map((c) => c.toJson()),
          fallback.toJson(),
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseFunction &&
          _listEquals(cases, other.cases) &&
          fallback == other.fallback;

  @override
  int get hashCode => Object.hash(Object.hashAll(cases), fallback);
}

// -- StepFunction --

final class StepParameter {
  final Expression<Object> boundary;
  final Expression<Object> value;

  const StepParameter({required this.boundary, required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepParameter &&
          boundary == other.boundary &&
          value == other.value;

  @override
  int get hashCode => Object.hash(boundary, value);
}

/// GeoStyler step function:
/// {"name": "step", "args": [input, defaultValue, boundary1, value1, ...]}
final class StepFunction extends GeoStylerFunction {
  final Expression<Object> input;
  final Expression<Object> defaultValue;
  final List<StepParameter> stops;

  const StepFunction({
    required this.input,
    required this.defaultValue,
    this.stops = const [],
  });

  @override
  String get name => 'step';

  factory StepFunction._fromJson(Map<String, dynamic> json) {
    final args = json['args'] as List<dynamic>;
    final input =
        Expression.fromJson<Object>(args[0], (v) => v as Object);
    final defaultValue =
        Expression.fromJson<Object>(args[1], (v) => v as Object);
    final stops = <StepParameter>[];
    for (var i = 2; i < args.length - 1; i += 2) {
      stops.add(StepParameter(
        boundary:
            Expression.fromJson<Object>(args[i], (v) => v as Object),
        value:
            Expression.fromJson<Object>(args[i + 1], (v) => v as Object),
      ));
    }
    return StepFunction(
        input: input, defaultValue: defaultValue, stops: stops);
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': 'step',
        'args': [
          input.toJson(),
          defaultValue.toJson(),
          for (final stop in stops) ...[
            stop.boundary.toJson(),
            stop.value.toJson(),
          ],
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepFunction &&
          input == other.input &&
          defaultValue == other.defaultValue &&
          _listEquals(stops, other.stops);

  @override
  int get hashCode =>
      Object.hash(input, defaultValue, Object.hashAll(stops));
}

// -- InterpolateFunction --

final class InterpolateParameter {
  final Expression<Object> stop;
  final Expression<Object> value;

  const InterpolateParameter({required this.stop, required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpolateParameter &&
          stop == other.stop &&
          value == other.value;

  @override
  int get hashCode => Object.hash(stop, value);
}

/// GeoStyler interpolate function:
/// {"name": "interpolate", "args": [mode, input, stop1, value1, ...]}
/// mode is ["linear"], ["exponential", base], or ["cubic"]
final class InterpolateFunction extends GeoStylerFunction {
  final List<Object> mode; // ["linear"], ["exponential", base], ["cubic"]
  final Expression<Object> input;
  final List<InterpolateParameter> stops;

  const InterpolateFunction({
    required this.mode,
    required this.input,
    this.stops = const [],
  });

  @override
  String get name => 'interpolate';

  factory InterpolateFunction._fromJson(Map<String, dynamic> json) {
    final args = json['args'] as List<dynamic>;
    final mode = (args[0] as List<dynamic>).cast<Object>();
    final input =
        Expression.fromJson<Object>(args[1], (v) => v as Object);
    final stops = <InterpolateParameter>[];
    for (var i = 2; i < args.length - 1; i += 2) {
      stops.add(InterpolateParameter(
        stop:
            Expression.fromJson<Object>(args[i], (v) => v as Object),
        value:
            Expression.fromJson<Object>(args[i + 1], (v) => v as Object),
      ));
    }
    return InterpolateFunction(mode: mode, input: input, stops: stops);
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': 'interpolate',
        'args': [
          mode,
          input.toJson(),
          for (final stop in stops) ...[
            stop.stop.toJson(),
            stop.value.toJson(),
          ],
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpolateFunction &&
          _listEquals(mode, other.mode) &&
          input == other.input &&
          _listEquals(stops, other.stops);

  @override
  int get hashCode => Object.hash(Object.hashAll(mode), input, Object.hashAll(stops));
}

// -- Helpers --

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
