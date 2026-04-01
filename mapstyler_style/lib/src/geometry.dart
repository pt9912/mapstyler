/// Minimal geometry model for mapstyler spatial filters.
/// Kept independent from gml4dart — mapping happens in the SLD adapter.
sealed class Geometry {
  const Geometry();

  factory Geometry.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'Point' => PointGeometry._fromJson(json),
      'Envelope' => EnvelopeGeometry._fromJson(json),
      'LineString' => LineStringGeometry._fromJson(json),
      'Polygon' => PolygonGeometry._fromJson(json),
      _ => throw FormatException('Unknown geometry type: $type'),
    };
  }

  Map<String, dynamic> toJson();
}

final class PointGeometry extends Geometry {
  final double x;
  final double y;

  const PointGeometry(this.x, this.y);

  factory PointGeometry._fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List<dynamic>;
    return PointGeometry(
      (coords[0] as num).toDouble(),
      (coords[1] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Point',
        'coordinates': [x, y],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointGeometry && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class EnvelopeGeometry extends Geometry {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const EnvelopeGeometry({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  factory EnvelopeGeometry._fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'] as List<dynamic>;
    return EnvelopeGeometry(
      minX: (bbox[0] as num).toDouble(),
      minY: (bbox[1] as num).toDouble(),
      maxX: (bbox[2] as num).toDouble(),
      maxY: (bbox[3] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Envelope',
        'bbox': [minX, minY, maxX, maxY],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvelopeGeometry &&
          minX == other.minX &&
          minY == other.minY &&
          maxX == other.maxX &&
          maxY == other.maxY;

  @override
  int get hashCode => Object.hash(minX, minY, maxX, maxY);
}

final class LineStringGeometry extends Geometry {
  final List<(double, double)> coordinates;

  const LineStringGeometry(this.coordinates);

  factory LineStringGeometry._fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List<dynamic>;
    return LineStringGeometry(
      coords.map((c) => _parseCoord(c as List<dynamic>)).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'LineString',
        'coordinates': coordinates.map((c) => [c.$1, c.$2]).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineStringGeometry && _coordsEqual(coordinates, other.coordinates);

  @override
  int get hashCode => Object.hashAll(coordinates);
}

final class PolygonGeometry extends Geometry {
  final List<List<(double, double)>> rings;

  const PolygonGeometry(this.rings);

  factory PolygonGeometry._fromJson(Map<String, dynamic> json) {
    final rings = json['coordinates'] as List<dynamic>;
    return PolygonGeometry([
      for (final ring in rings)
        (ring as List<dynamic>)
            .map((c) => _parseCoord(c as List<dynamic>))
            .toList(),
    ]);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'Polygon',
        'coordinates':
            rings.map((r) => r.map((c) => [c.$1, c.$2]).toList()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolygonGeometry && _ringsEqual(rings, other.rings);

  @override
  int get hashCode => Object.hashAll(rings.map(Object.hashAll));
}

(double, double) _parseCoord(List<dynamic> c) =>
    ((c[0] as num).toDouble(), (c[1] as num).toDouble());

bool _coordsEqual(List<(double, double)> a, List<(double, double)> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _ringsEqual(
    List<List<(double, double)>> a, List<List<(double, double)>> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_coordsEqual(a[i], b[i])) return false;
  }
  return true;
}
