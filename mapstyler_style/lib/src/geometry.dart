/// Minimal geometry model for mapstyler spatial filters.
/// Kept independent from gml4dart — mapping happens in the SLD adapter.
sealed class Geometry {
  const Geometry();

  Map<String, dynamic> toJson();
}

final class PointGeometry extends Geometry {
  final double x;
  final double y;

  const PointGeometry(this.x, this.y);

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
