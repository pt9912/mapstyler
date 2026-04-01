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
      'Raster' => RasterSymbolizer.fromJson(json),
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

// -- Raster supporting types --

final class ColorMapEntry {
  final String color;
  final double quantity;
  final String? label;
  final double? opacity;

  const ColorMapEntry({
    required this.color,
    required this.quantity,
    this.label,
    this.opacity,
  });

  factory ColorMapEntry.fromJson(Map<String, dynamic> json) => ColorMapEntry(
        color: json['color'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        label: json['label'] as String?,
        opacity: (json['opacity'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'color': color,
        'quantity': quantity,
        if (label != null) 'label': label,
        if (opacity != null) 'opacity': opacity,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorMapEntry &&
          color == other.color &&
          quantity == other.quantity &&
          label == other.label &&
          opacity == other.opacity;

  @override
  int get hashCode => Object.hash(color, quantity, label, opacity);
}

final class ColorMap {
  final String type; // 'ramp', 'intervals', 'values'
  final List<ColorMapEntry> colorMapEntries;
  final bool? extended;

  const ColorMap({
    required this.type,
    this.colorMapEntries = const [],
    this.extended,
  });

  factory ColorMap.fromJson(Map<String, dynamic> json) => ColorMap(
        type: json['type'] as String,
        colorMapEntries: (json['colorMapEntries'] as List<dynamic>? ?? [])
            .map((e) => ColorMapEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        extended: json['extended'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'colorMapEntries': colorMapEntries.map((e) => e.toJson()).toList(),
        if (extended != null) 'extended': extended,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorMap &&
          type == other.type &&
          _listEquals(colorMapEntries, other.colorMapEntries) &&
          extended == other.extended;

  @override
  int get hashCode =>
      Object.hash(type, Object.hashAll(colorMapEntries), extended);
}

final class ContrastEnhancement {
  final String? enhancementType; // 'normalize', 'histogram', 'none'
  final double? gammaValue;

  const ContrastEnhancement({this.enhancementType, this.gammaValue});

  factory ContrastEnhancement.fromJson(Map<String, dynamic> json) =>
      ContrastEnhancement(
        enhancementType: json['enhancementType'] as String?,
        gammaValue: (json['gammaValue'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (enhancementType != null) 'enhancementType': enhancementType,
        if (gammaValue != null) 'gammaValue': gammaValue,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContrastEnhancement &&
          enhancementType == other.enhancementType &&
          gammaValue == other.gammaValue;

  @override
  int get hashCode => Object.hash(enhancementType, gammaValue);
}

final class Channel {
  final String sourceChannelName;
  final ContrastEnhancement? contrastEnhancement;

  const Channel({required this.sourceChannelName, this.contrastEnhancement});

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        sourceChannelName: json['sourceChannelName'] as String,
        contrastEnhancement: json['contrastEnhancement'] != null
            ? ContrastEnhancement.fromJson(
                json['contrastEnhancement'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'sourceChannelName': sourceChannelName,
        if (contrastEnhancement != null)
          'contrastEnhancement': contrastEnhancement!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
          sourceChannelName == other.sourceChannelName &&
          contrastEnhancement == other.contrastEnhancement;

  @override
  int get hashCode => Object.hash(sourceChannelName, contrastEnhancement);
}

final class ChannelSelection {
  final Channel? redChannel;
  final Channel? greenChannel;
  final Channel? blueChannel;
  final Channel? grayChannel;

  const ChannelSelection({
    this.redChannel,
    this.greenChannel,
    this.blueChannel,
    this.grayChannel,
  });

  factory ChannelSelection.fromJson(Map<String, dynamic> json) =>
      ChannelSelection(
        redChannel: json['redChannel'] != null
            ? Channel.fromJson(json['redChannel'] as Map<String, dynamic>)
            : null,
        greenChannel: json['greenChannel'] != null
            ? Channel.fromJson(json['greenChannel'] as Map<String, dynamic>)
            : null,
        blueChannel: json['blueChannel'] != null
            ? Channel.fromJson(json['blueChannel'] as Map<String, dynamic>)
            : null,
        grayChannel: json['grayChannel'] != null
            ? Channel.fromJson(json['grayChannel'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (redChannel != null) 'redChannel': redChannel!.toJson(),
        if (greenChannel != null) 'greenChannel': greenChannel!.toJson(),
        if (blueChannel != null) 'blueChannel': blueChannel!.toJson(),
        if (grayChannel != null) 'grayChannel': grayChannel!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelSelection &&
          redChannel == other.redChannel &&
          greenChannel == other.greenChannel &&
          blueChannel == other.blueChannel &&
          grayChannel == other.grayChannel;

  @override
  int get hashCode =>
      Object.hash(redChannel, greenChannel, blueChannel, grayChannel);
}

// -- RasterSymbolizer --

final class RasterSymbolizer extends Symbolizer {
  final Expression<double>? opacity;
  final ColorMap? colorMap;
  final ChannelSelection? channelSelection;
  final ContrastEnhancement? contrastEnhancement;
  final Expression<double>? hueRotate;
  final Expression<double>? brightnessMin;
  final Expression<double>? brightnessMax;
  final Expression<double>? saturation;
  final Expression<double>? contrast;

  const RasterSymbolizer({
    this.opacity,
    this.colorMap,
    this.channelSelection,
    this.contrastEnhancement,
    this.hueRotate,
    this.brightnessMin,
    this.brightnessMax,
    this.saturation,
    this.contrast,
  });

  @override
  String get kind => 'Raster';

  factory RasterSymbolizer.fromJson(Map<String, dynamic> json) =>
      RasterSymbolizer(
        opacity: _optExpr(json, 'opacity', _dbl),
        colorMap: json['colorMap'] != null
            ? ColorMap.fromJson(json['colorMap'] as Map<String, dynamic>)
            : null,
        channelSelection: json['channelSelection'] != null
            ? ChannelSelection.fromJson(
                json['channelSelection'] as Map<String, dynamic>)
            : null,
        contrastEnhancement: json['contrastEnhancement'] != null
            ? ContrastEnhancement.fromJson(
                json['contrastEnhancement'] as Map<String, dynamic>)
            : null,
        hueRotate: _optExpr(json, 'hueRotate', _dbl),
        brightnessMin: _optExpr(json, 'brightnessMin', _dbl),
        brightnessMax: _optExpr(json, 'brightnessMax', _dbl),
        saturation: _optExpr(json, 'saturation', _dbl),
        contrast: _optExpr(json, 'contrast', _dbl),
      );

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'Raster',
        if (opacity != null) 'opacity': opacity!.toJson(),
        if (colorMap != null) 'colorMap': colorMap!.toJson(),
        if (channelSelection != null)
          'channelSelection': channelSelection!.toJson(),
        if (contrastEnhancement != null)
          'contrastEnhancement': contrastEnhancement!.toJson(),
        if (hueRotate != null) 'hueRotate': hueRotate!.toJson(),
        if (brightnessMin != null) 'brightnessMin': brightnessMin!.toJson(),
        if (brightnessMax != null) 'brightnessMax': brightnessMax!.toJson(),
        if (saturation != null) 'saturation': saturation!.toJson(),
        if (contrast != null) 'contrast': contrast!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RasterSymbolizer &&
          opacity == other.opacity &&
          colorMap == other.colorMap &&
          channelSelection == other.channelSelection &&
          contrastEnhancement == other.contrastEnhancement &&
          hueRotate == other.hueRotate &&
          brightnessMin == other.brightnessMin &&
          brightnessMax == other.brightnessMax &&
          saturation == other.saturation &&
          contrast == other.contrast;

  @override
  int get hashCode => Object.hash(opacity, colorMap, channelSelection,
      contrastEnhancement, hueRotate, brightnessMin, brightnessMax, saturation, contrast);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
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
