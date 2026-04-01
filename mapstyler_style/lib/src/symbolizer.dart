import 'expression.dart';

/// GeoStyler symbolizer — map-based JSON with "kind" discriminator.
sealed class Symbolizer {
  const Symbolizer();

  String get kind;

  factory Symbolizer.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String;
    return switch (kind) {
      'Fill' => FillSymbolizer.fromJson(json),
      'Line' => LineSymbolizer.fromJson(json),
      'Mark' => MarkSymbolizer.fromJson(json),
      'Icon' => IconSymbolizer.fromJson(json),
      'Text' => TextSymbolizer.fromJson(json),
      _ => throw FormatException('Unknown symbolizer kind: $kind'),
    };
  }

  Map<String, dynamic> toJson();
}

final class FillSymbolizer extends Symbolizer {
  final Expression<String>? color;
  final Expression<double>? opacity;
  final Expression<double>? fillOpacity;
  final Expression<String>? outlineColor;
  final Expression<double>? outlineWidth;

  const FillSymbolizer({
    this.color,
    this.opacity,
    this.fillOpacity,
    this.outlineColor,
    this.outlineWidth,
  });

  @override
  String get kind => 'Fill';

  factory FillSymbolizer.fromJson(Map<String, dynamic> json) => FillSymbolizer(
        color: _optExpr(json, 'color', _str),
        opacity: _optExpr(json, 'opacity', _dbl),
        fillOpacity: _optExpr(json, 'fillOpacity', _dbl),
        outlineColor: _optExpr(json, 'outlineColor', _str),
        outlineWidth: _optExpr(json, 'outlineWidth', _dbl),
      );

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'Fill',
        if (color != null) 'color': color!.toJson(),
        if (opacity != null) 'opacity': opacity!.toJson(),
        if (fillOpacity != null) 'fillOpacity': fillOpacity!.toJson(),
        if (outlineColor != null) 'outlineColor': outlineColor!.toJson(),
        if (outlineWidth != null) 'outlineWidth': outlineWidth!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FillSymbolizer &&
          color == other.color &&
          opacity == other.opacity &&
          fillOpacity == other.fillOpacity &&
          outlineColor == other.outlineColor &&
          outlineWidth == other.outlineWidth;

  @override
  int get hashCode =>
      Object.hash(color, opacity, fillOpacity, outlineColor, outlineWidth);
}

final class LineSymbolizer extends Symbolizer {
  final Expression<String>? color;
  final Expression<double>? width;
  final Expression<double>? opacity;
  final List<double>? dasharray;
  final String? cap;
  final String? join;

  const LineSymbolizer({
    this.color,
    this.width,
    this.opacity,
    this.dasharray,
    this.cap,
    this.join,
  });

  @override
  String get kind => 'Line';

  factory LineSymbolizer.fromJson(Map<String, dynamic> json) => LineSymbolizer(
        color: _optExpr(json, 'color', _str),
        width: _optExpr(json, 'width', _dbl),
        opacity: _optExpr(json, 'opacity', _dbl),
        dasharray: (json['dasharray'] as List?)?.cast<double>(),
        cap: json['cap'] as String?,
        join: json['join'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'Line',
        if (color != null) 'color': color!.toJson(),
        if (width != null) 'width': width!.toJson(),
        if (opacity != null) 'opacity': opacity!.toJson(),
        if (dasharray != null) 'dasharray': dasharray,
        if (cap != null) 'cap': cap,
        if (join != null) 'join': join,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineSymbolizer &&
          color == other.color &&
          width == other.width &&
          opacity == other.opacity &&
          cap == other.cap &&
          join == other.join;

  @override
  int get hashCode => Object.hash(color, width, opacity, cap, join);
}

final class MarkSymbolizer extends Symbolizer {
  final String wellKnownName;
  final Expression<double>? radius;
  final Expression<String>? color;
  final Expression<double>? opacity;
  final Expression<String>? strokeColor;
  final Expression<double>? strokeWidth;
  final Expression<double>? rotate;

  const MarkSymbolizer({
    required this.wellKnownName,
    this.radius,
    this.color,
    this.opacity,
    this.strokeColor,
    this.strokeWidth,
    this.rotate,
  });

  @override
  String get kind => 'Mark';

  factory MarkSymbolizer.fromJson(Map<String, dynamic> json) => MarkSymbolizer(
        wellKnownName: json['wellKnownName'] as String,
        radius: _optExpr(json, 'radius', _dbl),
        color: _optExpr(json, 'color', _str),
        opacity: _optExpr(json, 'opacity', _dbl),
        strokeColor: _optExpr(json, 'strokeColor', _str),
        strokeWidth: _optExpr(json, 'strokeWidth', _dbl),
        rotate: _optExpr(json, 'rotate', _dbl),
      );

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'Mark',
        'wellKnownName': wellKnownName,
        if (radius != null) 'radius': radius!.toJson(),
        if (color != null) 'color': color!.toJson(),
        if (opacity != null) 'opacity': opacity!.toJson(),
        if (strokeColor != null) 'strokeColor': strokeColor!.toJson(),
        if (strokeWidth != null) 'strokeWidth': strokeWidth!.toJson(),
        if (rotate != null) 'rotate': rotate!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkSymbolizer &&
          wellKnownName == other.wellKnownName &&
          radius == other.radius &&
          color == other.color &&
          opacity == other.opacity &&
          strokeColor == other.strokeColor &&
          strokeWidth == other.strokeWidth &&
          rotate == other.rotate;

  @override
  int get hashCode => Object.hash(
      wellKnownName, radius, color, opacity, strokeColor, strokeWidth, rotate);
}

final class IconSymbolizer extends Symbolizer {
  final Expression<String> image;
  final String? format;
  final Expression<double>? size;
  final Expression<double>? opacity;
  final Expression<double>? rotate;

  const IconSymbolizer({
    required this.image,
    this.format,
    this.size,
    this.opacity,
    this.rotate,
  });

  @override
  String get kind => 'Icon';

  factory IconSymbolizer.fromJson(Map<String, dynamic> json) => IconSymbolizer(
        image: Expression.fromJson<String>(json['image'], _str),
        format: json['format'] as String?,
        size: _optExpr(json, 'size', _dbl),
        opacity: _optExpr(json, 'opacity', _dbl),
        rotate: _optExpr(json, 'rotate', _dbl),
      );

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'Icon',
        'image': image.toJson(),
        if (format != null) 'format': format,
        if (size != null) 'size': size!.toJson(),
        if (opacity != null) 'opacity': opacity!.toJson(),
        if (rotate != null) 'rotate': rotate!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconSymbolizer &&
          image == other.image &&
          format == other.format &&
          size == other.size &&
          opacity == other.opacity &&
          rotate == other.rotate;

  @override
  int get hashCode => Object.hash(image, format, size, opacity, rotate);
}

final class TextSymbolizer extends Symbolizer {
  final Expression<String> label;
  final Expression<String>? color;
  final Expression<double>? size;
  final String? font;
  final Expression<double>? opacity;
  final Expression<double>? rotate;
  final Expression<String>? haloColor;
  final Expression<double>? haloWidth;
  final String? placement;

  const TextSymbolizer({
    required this.label,
    this.color,
    this.size,
    this.font,
    this.opacity,
    this.rotate,
    this.haloColor,
    this.haloWidth,
    this.placement,
  });

  @override
  String get kind => 'Text';

  factory TextSymbolizer.fromJson(Map<String, dynamic> json) => TextSymbolizer(
        label: Expression.fromJson<String>(json['label'], _str),
        color: _optExpr(json, 'color', _str),
        size: _optExpr(json, 'size', _dbl),
        font: json['font'] as String?,
        opacity: _optExpr(json, 'opacity', _dbl),
        rotate: _optExpr(json, 'rotate', _dbl),
        haloColor: _optExpr(json, 'haloColor', _str),
        haloWidth: _optExpr(json, 'haloWidth', _dbl),
        placement: json['placement'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'Text',
        'label': label.toJson(),
        if (color != null) 'color': color!.toJson(),
        if (size != null) 'size': size!.toJson(),
        if (font != null) 'font': font,
        if (opacity != null) 'opacity': opacity!.toJson(),
        if (rotate != null) 'rotate': rotate!.toJson(),
        if (haloColor != null) 'haloColor': haloColor!.toJson(),
        if (haloWidth != null) 'haloWidth': haloWidth!.toJson(),
        if (placement != null) 'placement': placement,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSymbolizer &&
          label == other.label &&
          color == other.color &&
          size == other.size &&
          font == other.font &&
          opacity == other.opacity &&
          rotate == other.rotate &&
          haloColor == other.haloColor &&
          haloWidth == other.haloWidth &&
          placement == other.placement;

  @override
  int get hashCode => Object.hash(
      label, color, size, font, opacity, rotate, haloColor, haloWidth, placement);
}

// -- Helpers --

String _str(Object? v) => v as String;
double _dbl(Object? v) => (v as num).toDouble();

Expression<T>? _optExpr<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Object?) fromJsonT,
) =>
    json[key] != null ? Expression.fromJson<T>(json[key], fromJsonT) : null;
