import 'dart:math' as math;

import 'package:mapstyler_style/mapstyler_style.dart';

/// Prepared evaluator for an [Expression].
typedef CompiledExpressionEvaluator<T> = T? Function(
  Map<String, Object?> properties,
);

/// Evaluates a mapstyler [Expression] against feature properties.
///
/// For [LiteralExpression] returns the literal value directly.
/// For [FunctionExpression] evaluates the function against [properties].
///
/// Supported functions currently include:
/// - structured expressions: `property`, `case`, `step`, `interpolate`
/// - numeric functions: `add`, `subtract`, `multiply`, `divide`, `modulo`,
///   `pow`, `abs`, `ceil`, `floor`, `round`, `sqrt`, `log`, `exp`, `min`,
///   `max`, `pi`, `rint`, `acos`, `asin`, `atan`, `atan2`, `cos`, `sin`,
///   `tan`, `toDegrees`, `toRadians`
/// - string functions: `strConcat`, `strToLowerCase`, `strToUpperCase`,
///   `strTrim`, `strLength`, `strSubstring`, `strReplace`, `strIndexOf`,
///   `strStartsWith`, `strEndsWith`, `strMatches`, `numberFormat`
/// - boolean functions: `all`, `any`, `between`, `equalTo`, `notEqualTo`,
///   `greaterThan`, `greaterThanOrEqualTo`, `lessThan`,
///   `lessThanOrEqualTo`, `in`, `parseBoolean`, `not`
///
/// Unknown functions evaluate to `null`.
T? evaluateExpression<T>(
  Expression<T>? expression,
  Map<String, Object?> properties,
) {
  if (expression == null) return null;
  return compileExpressionEvaluator(expression)(properties);
}

/// Compiles an [Expression] into a reusable evaluator closure.
///
/// This is used internally by [StyleRenderer] so that expressions can be
/// prepared once per style and reused across render passes.
CompiledExpressionEvaluator<T> compileExpressionEvaluator<T>(
  Expression<T>? expression,
) {
  if (expression == null) {
    return (_) => null;
  }

  return switch (expression) {
    LiteralExpression<T>(:final value) => (_) => value,
    FunctionExpression<T>(:final function) => _compileFunction<T>(function),
  };
}

CompiledExpressionEvaluator<T> _compileFunction<T>(GeoStylerFunction function) {
  return switch (function) {
    PropertyGet(:final propertyName) => (properties) => _cast<T>(properties[propertyName]),
    CaseFunction(:final cases, :final fallback) =>
      _compileCase<T>(cases, fallback),
    StepFunction(:final input, :final defaultValue, :final stops) =>
      _compileStep<T>(input, defaultValue, stops),
    InterpolateFunction(:final input, :final mode, :final stops) =>
      _compileInterpolate<T>(input, mode, stops),
    ArgsFunction(:final name, :final args) => _compileArgsFunction<T>(name, args),
  };
}

CompiledExpressionEvaluator<T> _compileCase<T>(
  List<CaseParameter> cases,
  Expression<Object> fallback,
) {
  final compiledCases = cases
      .map(
        (entry) => (
          condition: compileExpressionEvaluator(entry.condition),
          value: compileExpressionEvaluator(entry.value),
        ),
      )
      .toList(growable: false);
  final compiledFallback = compileExpressionEvaluator(fallback);

  return (properties) {
    for (final entry in compiledCases) {
      if (entry.condition(properties) == true) {
        return _cast<T>(entry.value(properties));
      }
    }
    return _cast<T>(compiledFallback(properties));
  };
}

CompiledExpressionEvaluator<T> _compileStep<T>(
  Expression<Object> input,
  Expression<Object> defaultValue,
  List<StepParameter> stops,
) {
  final compiledInput = compileExpressionEvaluator(input);
  final compiledDefault = compileExpressionEvaluator(defaultValue);
  final compiledStops = stops
      .map(
        (stop) => (
          boundary: compileExpressionEvaluator(stop.boundary),
          value: compileExpressionEvaluator(stop.value),
        ),
      )
      .toList(growable: false);

  return (properties) {
    final inputVal = compiledInput(properties);
    if (inputVal is! num) {
      return _cast<T>(compiledDefault(properties));
    }

    T? result = _cast<T>(compiledDefault(properties));
    for (final stop in compiledStops) {
      final boundary = stop.boundary(properties);
      if (boundary is num && inputVal >= boundary) {
        result = _cast<T>(stop.value(properties));
      } else {
        break;
      }
    }
    return result;
  };
}

CompiledExpressionEvaluator<T> _compileInterpolate<T>(
  Expression<Object> input,
  List<Object> mode,
  List<InterpolateParameter> stops,
) {
  final compiledInput = compileExpressionEvaluator(input);
  final method = mode.isEmpty ? null : mode.first;
  final base = mode.length > 1 && mode[1] is num
      ? (mode[1] as num).toDouble()
      : 1.0;

  final compiledStops = stops
      .map(
        (stop) => (
          stop: compileExpressionEvaluator(stop.stop),
          value: compileExpressionEvaluator(stop.value),
        ),
      )
      .toList(growable: false);

  return (properties) {
    final inputValue = compiledInput(properties);
    if (inputValue is! num || compiledStops.isEmpty) return null;

    final sortedStops = [...compiledStops]
      ..sort((a, b) {
        final aStop = a.stop(properties);
        final bStop = b.stop(properties);
        if (aStop is num && bStop is num) {
          return aStop.compareTo(bStop);
        }
        return 0;
      });

    final firstStop = sortedStops.first.stop(properties);
    if (firstStop is! num) return null;
    if (inputValue <= firstStop) {
      return _cast<T>(sortedStops.first.value(properties));
    }

    for (var i = 0; i < sortedStops.length - 1; i++) {
      final lowerStop = sortedStops[i].stop(properties);
      final upperStop = sortedStops[i + 1].stop(properties);
      if (lowerStop is! num || upperStop is! num) continue;
      if (inputValue >= lowerStop && inputValue <= upperStop) {
        final lowerValue = sortedStops[i].value(properties);
        final upperValue = sortedStops[i + 1].value(properties);
        final t = _interpolationFactor(
          input: inputValue.toDouble(),
          lower: lowerStop.toDouble(),
          upper: upperStop.toDouble(),
          method: method,
          base: base,
        );
        return _interpolateValue<T>(lowerValue, upperValue, t);
      }
    }

    return _cast<T>(sortedStops.last.value(properties));
  };
}

CompiledExpressionEvaluator<T> _compileArgsFunction<T>(
  String name,
  List<Expression<Object>> args,
) {
  final compiledArgs =
      args.map(compileExpressionEvaluator).toList(growable: false);

  List<Object?> evaluateArgs(Map<String, Object?> properties) =>
      compiledArgs.map((arg) => arg(properties)).toList(growable: false);

  return (properties) {
    final evaluated = evaluateArgs(properties);
    return switch (name) {
      'strConcat' => _cast<T>(evaluated.join()),
      'strToLowerCase' when evaluated.length == 1 =>
        _cast<T>(evaluated.first?.toString().toLowerCase()),
      'strToUpperCase' when evaluated.length == 1 =>
        _cast<T>(evaluated.first?.toString().toUpperCase()),
      'strTrim' when evaluated.length == 1 =>
        _cast<T>(evaluated.first?.toString().trim()),
      'strLength' when evaluated.length == 1 =>
        _cast<T>(evaluated.first?.toString().length),
      'strSubstring' when evaluated.length >= 2 =>
        _cast<T>(
          _substring(
            evaluated.first?.toString() ?? '',
            start: _toInt(evaluated[1]) ?? 0,
            end: evaluated.length > 2 ? _toInt(evaluated[2]) : null,
          ),
        ),
      'strReplace' when evaluated.length >= 3 =>
        _cast<T>(
          (evaluated[0]?.toString() ?? '').replaceAll(
            evaluated[1]?.toString() ?? '',
            evaluated[2]?.toString() ?? '',
          ),
        ),
      'strIndexOf' when evaluated.length >= 2 =>
        _cast<T>(
          (evaluated[0]?.toString() ?? '').indexOf(evaluated[1]?.toString() ?? ''),
        ),
      'strStartsWith' when evaluated.length >= 2 =>
        _cast<T>(
          (evaluated[0]?.toString() ?? '').startsWith(evaluated[1]?.toString() ?? ''),
        ),
      'strEndsWith' when evaluated.length >= 2 =>
        _cast<T>(
          (evaluated[0]?.toString() ?? '').endsWith(evaluated[1]?.toString() ?? ''),
        ),
      'strMatches' when evaluated.length >= 2 =>
        _cast<T>(
          RegExp(evaluated[1]?.toString() ?? '').hasMatch(
            evaluated[0]?.toString() ?? '',
          ),
        ),
      'numberFormat' when evaluated.isNotEmpty =>
        _cast<T>(
          _numberFormat(
            evaluated.first,
            fractionDigits: evaluated.length > 1 ? _toInt(evaluated[1]) : null,
          ),
        ),
      'add' when evaluated.length == 2 =>
        _cast<T>(_toNum(evaluated[0]) + _toNum(evaluated[1])),
      'subtract' when evaluated.length == 2 =>
        _cast<T>(_toNum(evaluated[0]) - _toNum(evaluated[1])),
      'multiply' when evaluated.length == 2 =>
        _cast<T>(_toNum(evaluated[0]) * _toNum(evaluated[1])),
      'divide' when evaluated.length == 2 && _toNum(evaluated[1]) != 0 =>
        _cast<T>(_toNum(evaluated[0]) / _toNum(evaluated[1])),
      'modulo' when evaluated.length == 2 && _toNum(evaluated[1]) != 0 =>
        _cast<T>(_toNum(evaluated[0]) % _toNum(evaluated[1])),
      'pow' when evaluated.length == 2 =>
        _cast<T>(math.pow(_toNum(evaluated[0]), _toNum(evaluated[1]))),
      'abs' when evaluated.length == 1 =>
        _cast<T>(_toNum(evaluated.first).abs()),
      'ceil' when evaluated.length == 1 =>
        _cast<T>(_toNum(evaluated.first).ceil()),
      'floor' when evaluated.length == 1 =>
        _cast<T>(_toNum(evaluated.first).floor()),
      'round' when evaluated.length == 1 =>
        _cast<T>(_toNum(evaluated.first).round()),
      'sqrt' when evaluated.length == 1 && _toNum(evaluated.first) >= 0 =>
        _cast<T>(math.sqrt(_toNum(evaluated.first).toDouble())),
      'log' when evaluated.length == 1 && _toNum(evaluated.first) > 0 =>
        _cast<T>(math.log(_toNum(evaluated.first).toDouble())),
      'exp' when evaluated.length == 1 =>
        _cast<T>(math.exp(_toNum(evaluated.first).toDouble())),
      'min' when evaluated.isNotEmpty =>
        _cast<T>(evaluated.map(_toNum).reduce(math.min)),
      'max' when evaluated.isNotEmpty =>
        _cast<T>(evaluated.map(_toNum).reduce(math.max)),
      'pi' => _cast<T>(math.pi),
      'random' when evaluated.isEmpty => _cast<T>(_random.nextDouble()),
      'rint' when evaluated.length == 1 =>
        _cast<T>(_toNum(evaluated.first).roundToDouble()),
      'acos' when evaluated.length == 1 =>
        _cast<T>(math.acos(_toNum(evaluated.first).toDouble())),
      'asin' when evaluated.length == 1 =>
        _cast<T>(math.asin(_toNum(evaluated.first).toDouble())),
      'atan' when evaluated.length == 1 =>
        _cast<T>(math.atan(_toNum(evaluated.first).toDouble())),
      'atan2' when evaluated.length == 2 =>
        _cast<T>(
          math.atan2(
            _toNum(evaluated[0]).toDouble(),
            _toNum(evaluated[1]).toDouble(),
          ),
        ),
      'cos' when evaluated.length == 1 =>
        _cast<T>(math.cos(_toNum(evaluated.first).toDouble())),
      'sin' when evaluated.length == 1 =>
        _cast<T>(math.sin(_toNum(evaluated.first).toDouble())),
      'tan' when evaluated.length == 1 =>
        _cast<T>(math.tan(_toNum(evaluated.first).toDouble())),
      'toDegrees' when evaluated.length == 1 =>
        _cast<T>(_toNum(evaluated.first).toDouble() * 180 / math.pi),
      'toRadians' when evaluated.length == 1 =>
        _cast<T>(_toNum(evaluated.first).toDouble() * math.pi / 180),
      'equalTo' when evaluated.length == 2 =>
        _cast<T>(_equals(evaluated[0], evaluated[1])),
      'notEqualTo' when evaluated.length == 2 =>
        _cast<T>(!_equals(evaluated[0], evaluated[1])),
      'greaterThan' when evaluated.length == 2 =>
        _cast<T>(_compare(evaluated[0], evaluated[1]) > 0),
      'greaterThanOrEqualTo' when evaluated.length == 2 =>
        _cast<T>(_compare(evaluated[0], evaluated[1]) >= 0),
      'lessThan' when evaluated.length == 2 =>
        _cast<T>(_compare(evaluated[0], evaluated[1]) < 0),
      'lessThanOrEqualTo' when evaluated.length == 2 =>
        _cast<T>(_compare(evaluated[0], evaluated[1]) <= 0),
      'all' => _cast<T>(evaluated.every((value) => value == true)),
      'any' => _cast<T>(evaluated.any((value) => value == true)),
      'between' when evaluated.length == 3 =>
        _cast<T>(
          _compare(evaluated[0], evaluated[1]) >= 0 &&
              _compare(evaluated[0], evaluated[2]) <= 0,
        ),
      'in' when evaluated.length >= 2 =>
        _cast<T>(evaluated.skip(1).any((value) => _equals(evaluated[0], value))),
      'parseBoolean' when evaluated.length == 1 =>
        _cast<T>(_parseBoolean(evaluated.first)),
      'not' when evaluated.length == 1 => _cast<T>(evaluated.first != true),
      _ => null,
    };
  };
}

double _interpolationFactor({
  required double input,
  required double lower,
  required double upper,
  required Object? method,
  required double base,
}) {
  if (upper <= lower) return 0.0;
  final linear = ((input - lower) / (upper - lower)).clamp(0.0, 1.0);
  if (method == 'cubic') {
    return linear * linear * (3 - (2 * linear));
  }
  if (method != 'exponential' || base == 1.0) return linear;
  final powered = (base == 0.0 ? linear : ((base * linear) - 1) / (base - 1));
  return powered.clamp(0.0, 1.0);
}

T? _interpolateValue<T>(Object? lower, Object? upper, double t) {
  if (lower is num && upper is num) {
    final value = lower.toDouble() + (upper.toDouble() - lower.toDouble()) * t;
    return _cast<T>(value);
  }
  return _cast<T>(t < 0.5 ? lower : upper);
}

T? _cast<T>(Object? value) {
  if (value is T) return value;
  if (T == double && value is num) return value.toDouble() as T;
  if (T == int && value is num) return value.toInt() as T;
  if (T == String && value != null) return value.toString() as T;
  if (T == bool && value is bool) return value as T;
  return null;
}

num _toNum(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  if (value is bool) return value ? 1 : 0;
  return 0;
}

int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _parseBoolean(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'n':
      case 'off':
        return false;
    }
  }
  return null;
}

String _substring(String value, {required int start, int? end}) {
  final normalizedStart = start.clamp(0, value.length);
  final normalizedEnd = (end ?? value.length).clamp(normalizedStart, value.length);
  return value.substring(normalizedStart, normalizedEnd);
}

String _numberFormat(Object? value, {int? fractionDigits}) {
  final number = _toNum(value);
  if (fractionDigits == null) return '$number';
  return number.toDouble().toStringAsFixed(fractionDigits.clamp(0, 20));
}

bool _equals(Object? a, Object? b) {
  if (a == b) return true;
  final aNum = num.tryParse('$a');
  final bNum = num.tryParse('$b');
  if (aNum != null && bNum != null) return aNum == bNum;
  return '$a' == '$b';
}

int _compare(Object? a, Object? b) {
  final aNum = num.tryParse('$a');
  final bNum = num.tryParse('$b');
  if (aNum != null && bNum != null) return aNum.compareTo(bNum);
  return '$a'.compareTo('$b');
}

final math.Random _random = math.Random(0);
