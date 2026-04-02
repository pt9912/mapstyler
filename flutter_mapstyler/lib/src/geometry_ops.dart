import 'dart:math' as math;

import 'package:mapstyler_style/mapstyler_style.dart';

const double _epsilon = 1e-9;

/// Returns the axis-aligned bounding box of [geometry].
EnvelopeGeometry geometryEnvelope(Geometry geometry) => switch (geometry) {
      PointGeometry(:final x, :final y) =>
        EnvelopeGeometry(minX: x, minY: y, maxX: x, maxY: y),
      EnvelopeGeometry() => geometry,
      LineStringGeometry(:final coordinates) => _envelopeFromCoords(coordinates),
      PolygonGeometry(:final rings) =>
        _envelopeFromCoords(rings.expand((ring) => ring).toList()),
    };

/// Converts arbitrary [Geometry] values into a polygon approximation.
///
/// Envelopes become rectangles, points become degenerate polygons, and line
/// strings become a single ring containing the original coordinates.
PolygonGeometry geometryAsPolygon(Geometry geometry) => switch (geometry) {
      PolygonGeometry() => geometry,
      EnvelopeGeometry() => PolygonGeometry([
          [
            (geometry.minX, geometry.minY),
            (geometry.maxX, geometry.minY),
            (geometry.maxX, geometry.maxY),
            (geometry.minX, geometry.maxY),
            (geometry.minX, geometry.minY),
          ],
        ]),
      PointGeometry(:final x, :final y) => PolygonGeometry([
          [
            (x, y),
            (x, y),
            (x, y),
            (x, y),
          ],
        ]),
      LineStringGeometry(:final coordinates) => PolygonGeometry([coordinates]),
    };

/// Returns `true` when [a] and [b] intersect.
bool intersectsGeometry(Geometry a, Geometry b) {
  if (!_envelopesOverlap(geometryEnvelope(a), geometryEnvelope(b))) {
    return false;
  }

  if (a is PointGeometry) return _pointIntersectsGeometry(a, b);
  if (b is PointGeometry) return _pointIntersectsGeometry(b, a);

  if (a is LineStringGeometry && b is LineStringGeometry) {
    return _lineIntersectsLine(a.coordinates, b.coordinates);
  }

  if (a is LineStringGeometry && b is PolygonGeometry) {
    return _lineIntersectsPolygon(a.coordinates, b);
  }
  if (b is LineStringGeometry && a is PolygonGeometry) {
    return _lineIntersectsPolygon(b.coordinates, a);
  }

  final aPolygon = geometryAsPolygon(a);
  final bPolygon = geometryAsPolygon(b);
  return _polygonIntersectsPolygon(aPolygon, bPolygon);
}

/// Returns `true` when [container] fully contains [candidate].
bool containsGeometry(Geometry container, Geometry candidate) {
  if (!_envelopesContain(
    geometryEnvelope(container),
    geometryEnvelope(candidate),
  )) {
    return false;
  }

  if (container is PointGeometry) {
    return candidate is PointGeometry && _pointsEqual(container, candidate);
  }

  if (container is LineStringGeometry) {
    return switch (candidate) {
      PointGeometry() => _pointOnLine(candidate, container.coordinates),
      LineStringGeometry(:final coordinates) =>
        coordinates.every((point) => _pointOnLineCoord(point, container.coordinates)),
      _ => false,
    };
  }

  final polygon = geometryAsPolygon(container);
  return switch (candidate) {
    PointGeometry() => _pointInPolygon(candidate, polygon),
    EnvelopeGeometry() => _polygonContainsPolygon(
        polygon,
        geometryAsPolygon(candidate),
      ),
    LineStringGeometry(:final coordinates) =>
      _lineWithinPolygon(coordinates, polygon),
    PolygonGeometry() => _polygonContainsPolygon(polygon, candidate),
  };
}

/// Returns `true` when [geometry] is fully inside [container].
bool withinGeometry(Geometry geometry, Geometry container) =>
    containsGeometry(container, geometry);

/// Returns `true` when [a] and [b] do not intersect.
bool disjointGeometry(Geometry a, Geometry b) => !intersectsGeometry(a, b);

/// Returns `true` when [a] and [b] intersect without either containing the other.
bool overlapsGeometry(Geometry a, Geometry b) {
  if (!intersectsGeometry(a, b)) return false;
  if (containsGeometry(a, b) || containsGeometry(b, a)) return false;
  return switch ((a, b)) {
    (PointGeometry(), _) || (_, PointGeometry()) => false,
    (LineStringGeometry(), LineStringGeometry()) => true,
    (PolygonGeometry(), PolygonGeometry()) => true,
    (EnvelopeGeometry(), EnvelopeGeometry()) => true,
    (EnvelopeGeometry(), PolygonGeometry()) ||
    (PolygonGeometry(), EnvelopeGeometry()) =>
      true,
    _ => false,
  };
}

/// Returns `true` when [a] and [b] only meet at their boundary.
///
/// The current implementation follows the package's internal geometry rules and
/// may classify some boundary cases as containment instead of touch.
bool touchesGeometry(Geometry a, Geometry b) {
  if (!intersectsGeometry(a, b)) return false;
  if (overlapsGeometry(a, b) || containsGeometry(a, b) || containsGeometry(b, a)) {
    return false;
  }

  if (a is PointGeometry) return _pointTouchesGeometry(a, b);
  if (b is PointGeometry) return _pointTouchesGeometry(b, a);

  if (a is LineStringGeometry && b is LineStringGeometry) {
    return _lineTouchesLine(a.coordinates, b.coordinates);
  }

  return true;
}

/// Returns `true` when [a] and [b] cross each other.
bool crossesGeometry(Geometry a, Geometry b) {
  if (!intersectsGeometry(a, b)) return false;
  return switch ((a, b)) {
    (LineStringGeometry(), LineStringGeometry()) =>
      _lineCrossesLine(
        (a as LineStringGeometry).coordinates,
        (b as LineStringGeometry).coordinates,
      ),
    (LineStringGeometry(:final coordinates), PolygonGeometry()) =>
      _lineCrossesPolygon(coordinates, b as PolygonGeometry),
    (PolygonGeometry(), LineStringGeometry(:final coordinates)) =>
      _lineCrossesPolygon(coordinates, a as PolygonGeometry),
    _ => false,
  };
}

/// Computes the Euclidean distance between [a] and [b].
double distanceBetweenGeometries(Geometry a, Geometry b) {
  if (intersectsGeometry(a, b)) return 0.0;

  if (a is PointGeometry && b is PointGeometry) {
    return _distance(a.x, a.y, b.x, b.y);
  }

  if (a is PointGeometry && b is LineStringGeometry) {
    return _distancePointToLine(a, b.coordinates);
  }
  if (b is PointGeometry && a is LineStringGeometry) {
    return _distancePointToLine(b, a.coordinates);
  }

  if (a is PointGeometry) return _distancePointToGeometry(a, b);
  if (b is PointGeometry) return _distancePointToGeometry(b, a);

  if (a is LineStringGeometry && b is LineStringGeometry) {
    return _distanceLineToLine(a.coordinates, b.coordinates);
  }

  if (a is LineStringGeometry) return _distanceLineToGeometry(a.coordinates, b);
  if (b is LineStringGeometry) return _distanceLineToGeometry(b.coordinates, a);

  final aPolygon = geometryAsPolygon(a);
  final bPolygon = geometryAsPolygon(b);
  return _distancePolygonToPolygon(aPolygon, bPolygon);
}

/// Finds a representative midpoint along a line string.
LatLngLike pointOnLineAtMidpoint(LineStringGeometry geometry) {
  if (geometry.coordinates.isEmpty) return const LatLngLike(0, 0);
  if (geometry.coordinates.length == 1) {
    final coordinate = geometry.coordinates.first;
    return LatLngLike(coordinate.$2, coordinate.$1);
  }

  final segmentLengths = <double>[];
  var total = 0.0;
  for (var i = 0; i < geometry.coordinates.length - 1; i++) {
    final a = geometry.coordinates[i];
    final b = geometry.coordinates[i + 1];
    final length = _distance(a.$1, a.$2, b.$1, b.$2);
    segmentLengths.add(length);
    total += length;
  }

  final midpoint = total / 2;
  var walked = 0.0;
  for (var i = 0; i < segmentLengths.length; i++) {
    final length = segmentLengths[i];
    if (walked + length >= midpoint) {
      final t = length == 0 ? 0.0 : (midpoint - walked) / length;
      final start = geometry.coordinates[i];
      final end = geometry.coordinates[i + 1];
      final x = start.$1 + (end.$1 - start.$1) * t;
      final y = start.$2 + (end.$2 - start.$2) * t;
      return LatLngLike(y, x);
    }
    walked += length;
  }

  final last = geometry.coordinates.last;
  return LatLngLike(last.$2, last.$1);
}

/// Computes the centroid of the outer ring of a polygon.
///
/// Degenerate polygons fall back to the first ring coordinate.
LatLngLike centroidOfPolygon(PolygonGeometry geometry) {
  final ring = geometry.rings.firstOrNull;
  if (ring == null || ring.isEmpty) return const LatLngLike(0, 0);

  var twiceArea = 0.0;
  var centroidX = 0.0;
  var centroidY = 0.0;

  for (var i = 0; i < ring.length; i++) {
    final current = ring[i];
    final next = ring[(i + 1) % ring.length];
    final cross = current.$1 * next.$2 - next.$1 * current.$2;
    twiceArea += cross;
    centroidX += (current.$1 + next.$1) * cross;
    centroidY += (current.$2 + next.$2) * cross;
  }

  if (twiceArea.abs() < _epsilon) {
    final first = ring.first;
    return LatLngLike(first.$2, first.$1);
  }

  final factor = 1 / (3 * twiceArea);
  return LatLngLike(centroidY * factor, centroidX * factor);
}

/// Returns `true` when [point] lies inside or on the boundary of [geometry].
bool pointInGeometry(PointGeometry point, Geometry geometry) =>
    containsGeometry(geometry, point) || touchesGeometry(point, geometry);

/// Lightweight latitude/longitude pair used internally for label placement.
final class LatLngLike {
  /// Creates a geographic coordinate in latitude/longitude order.
  const LatLngLike(this.latitude, this.longitude);

  /// Latitude component.
  final double latitude;

  /// Longitude component.
  final double longitude;
}

EnvelopeGeometry _envelopeFromCoords(List<(double, double)> coordinates) {
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (final coordinate in coordinates) {
    minX = math.min(minX, coordinate.$1);
    minY = math.min(minY, coordinate.$2);
    maxX = math.max(maxX, coordinate.$1);
    maxY = math.max(maxY, coordinate.$2);
  }
  return EnvelopeGeometry(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
}

bool _envelopesOverlap(EnvelopeGeometry a, EnvelopeGeometry b) =>
    a.minX <= b.maxX + _epsilon &&
    a.maxX + _epsilon >= b.minX &&
    a.minY <= b.maxY + _epsilon &&
    a.maxY + _epsilon >= b.minY;

bool _envelopesContain(EnvelopeGeometry a, EnvelopeGeometry b) =>
    a.minX <= b.minX + _epsilon &&
    a.maxX + _epsilon >= b.maxX &&
    a.minY <= b.minY + _epsilon &&
    a.maxY + _epsilon >= b.maxY;

bool _pointIntersectsGeometry(PointGeometry point, Geometry geometry) => switch (geometry) {
      PointGeometry() => _pointsEqual(point, geometry),
      EnvelopeGeometry() =>
        point.x >= geometry.minX - _epsilon &&
        point.x <= geometry.maxX + _epsilon &&
        point.y >= geometry.minY - _epsilon &&
        point.y <= geometry.maxY + _epsilon,
      LineStringGeometry(:final coordinates) => _pointOnLine(point, coordinates),
      PolygonGeometry() => _pointInPolygon(point, geometry),
    };

bool _pointTouchesGeometry(PointGeometry point, Geometry geometry) => switch (geometry) {
      PointGeometry() => _pointsEqual(point, geometry),
      EnvelopeGeometry() =>
        _pointIntersectsGeometry(point, geometry) &&
        (point.x == geometry.minX ||
            point.x == geometry.maxX ||
            point.y == geometry.minY ||
            point.y == geometry.maxY),
      LineStringGeometry(:final coordinates) => _pointOnLine(point, coordinates),
      PolygonGeometry() => _pointOnPolygonBoundary(point, geometry),
    };

bool _pointsEqual(PointGeometry a, PointGeometry b) =>
    (a.x - b.x).abs() < _epsilon && (a.y - b.y).abs() < _epsilon;

bool _pointOnLine(PointGeometry point, List<(double, double)> line) =>
    _pointOnLineCoord((point.x, point.y), line);

bool _pointOnLineCoord((double, double) point, List<(double, double)> line) {
  for (var i = 0; i < line.length - 1; i++) {
    if (_pointOnSegment(point, line[i], line[i + 1])) return true;
  }
  return false;
}

bool _pointOnPolygonBoundary(PointGeometry point, PolygonGeometry polygon) {
  for (final ring in polygon.rings) {
    if (_pointOnLineCoord((point.x, point.y), ring)) return true;
  }
  return false;
}

bool _pointInPolygon(PointGeometry point, PolygonGeometry polygon) {
  final outer = _pointInRing((point.x, point.y), polygon.rings.first);
  if (!outer) return false;
  for (final hole in polygon.rings.skip(1)) {
    if (_pointInRing((point.x, point.y), hole)) return false;
  }
  return true;
}

bool _pointInRing((double, double) point, List<(double, double)> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = ring[i].$1;
    final yi = ring[i].$2;
    final xj = ring[j].$1;
    final yj = ring[j].$2;

    final intersects = ((yi > point.$2) != (yj > point.$2)) &&
        (point.$1 <
            (xj - xi) * (point.$2 - yi) / ((yj - yi) == 0 ? _epsilon : (yj - yi)) +
                xi);
    if (intersects) inside = !inside;
  }
  return inside || _pointOnLineCoord(point, ring);
}

bool _lineIntersectsLine(
  List<(double, double)> a,
  List<(double, double)> b,
) {
  for (var i = 0; i < a.length - 1; i++) {
    for (var j = 0; j < b.length - 1; j++) {
      if (_segmentsIntersect(a[i], a[i + 1], b[j], b[j + 1])) return true;
    }
  }
  return false;
}

bool _lineTouchesLine(
  List<(double, double)> a,
  List<(double, double)> b,
) {
  for (var i = 0; i < a.length - 1; i++) {
    for (var j = 0; j < b.length - 1; j++) {
      if (_segmentsTouch(a[i], a[i + 1], b[j], b[j + 1])) return true;
    }
  }
  return false;
}

bool _lineCrossesLine(
  List<(double, double)> a,
  List<(double, double)> b,
) {
  for (var i = 0; i < a.length - 1; i++) {
    for (var j = 0; j < b.length - 1; j++) {
      if (_segmentsCross(a[i], a[i + 1], b[j], b[j + 1])) return true;
    }
  }
  return false;
}

bool _lineIntersectsPolygon(
  List<(double, double)> line,
  PolygonGeometry polygon,
) {
  if (line.any((point) => _pointInPolygon(PointGeometry(point.$1, point.$2), polygon))) {
    return true;
  }

  for (final ring in polygon.rings) {
    if (_lineIntersectsLine(line, ring)) return true;
  }
  return false;
}

bool _lineWithinPolygon(
  List<(double, double)> line,
  PolygonGeometry polygon,
) {
  if (line.isEmpty) return false;
  if (line.any((point) => !_pointInPolygon(PointGeometry(point.$1, point.$2), polygon))) {
    return false;
  }

  for (final ring in polygon.rings) {
    if (_lineCrossesLine(line, ring)) return false;
  }
  return true;
}

bool _lineCrossesPolygon(
  List<(double, double)> line,
  PolygonGeometry polygon,
) {
  final insideCount = line
      .where((point) => _pointInPolygon(PointGeometry(point.$1, point.$2), polygon))
      .length;
  return insideCount > 0 &&
      insideCount < line.length &&
      _lineIntersectsPolygon(line, polygon);
}

bool _polygonIntersectsPolygon(PolygonGeometry a, PolygonGeometry b) {
  for (final ringA in a.rings) {
    for (final ringB in b.rings) {
      if (_lineIntersectsLine(ringA, ringB)) return true;
    }
  }

  final aPoint = a.rings.first.first;
  final bPoint = b.rings.first.first;
  return _pointInPolygon(PointGeometry(aPoint.$1, aPoint.$2), b) ||
      _pointInPolygon(PointGeometry(bPoint.$1, bPoint.$2), a);
}

bool _polygonContainsPolygon(PolygonGeometry a, PolygonGeometry b) {
  for (final ring in b.rings) {
    for (final point in ring) {
      if (!_pointInPolygon(PointGeometry(point.$1, point.$2), a)) return false;
    }
  }

  for (final ringA in a.rings) {
    for (final ringB in b.rings) {
      if (_lineCrossesLine(ringA, ringB)) return false;
    }
  }
  return true;
}

double _distancePointToGeometry(PointGeometry point, Geometry geometry) => switch (geometry) {
      EnvelopeGeometry() => _distancePointToPolygon(point, geometryAsPolygon(geometry)),
      LineStringGeometry(:final coordinates) => _distancePointToLine(point, coordinates),
      PolygonGeometry() => _distancePointToPolygon(point, geometry),
      PointGeometry() => _distance(point.x, point.y, geometry.x, geometry.y),
    };

double _distancePointToLine(PointGeometry point, List<(double, double)> line) {
  var minDistance = double.infinity;
  for (var i = 0; i < line.length - 1; i++) {
    minDistance = math.min(
      minDistance,
      _distancePointToSegment((point.x, point.y), line[i], line[i + 1]),
    );
  }
  return minDistance;
}

double _distancePointToPolygon(PointGeometry point, PolygonGeometry polygon) {
  if (_pointInPolygon(point, polygon)) return 0.0;
  var minDistance = double.infinity;
  for (final ring in polygon.rings) {
    minDistance = math.min(
      minDistance,
      _distancePointToLine(point, ring),
    );
  }
  return minDistance;
}

double _distanceLineToGeometry(
  List<(double, double)> line,
  Geometry geometry,
) {
  if (geometry is PolygonGeometry) {
    return _distanceLineToPolygon(line, geometry);
  }

  final otherLine = geometry is LineStringGeometry
      ? geometry.coordinates
      : geometryAsPolygon(geometry).rings.first;
  return _distanceLineToLine(line, otherLine);
}

double _distanceLineToPolygon(
  List<(double, double)> line,
  PolygonGeometry polygon,
) {
  if (_lineIntersectsPolygon(line, polygon)) return 0.0;
  var minDistance = double.infinity;
  for (final point in line) {
    minDistance = math.min(
      minDistance,
      _distancePointToPolygon(PointGeometry(point.$1, point.$2), polygon),
    );
  }
  for (final ring in polygon.rings) {
    minDistance = math.min(minDistance, _distanceLineToLine(line, ring));
  }
  return minDistance;
}

double _distancePolygonToPolygon(PolygonGeometry a, PolygonGeometry b) {
  if (_polygonIntersectsPolygon(a, b)) return 0.0;
  var minDistance = double.infinity;
  for (final point in a.rings.first) {
    minDistance = math.min(
      minDistance,
      _distancePointToPolygon(PointGeometry(point.$1, point.$2), b),
    );
  }
  for (final point in b.rings.first) {
    minDistance = math.min(
      minDistance,
      _distancePointToPolygon(PointGeometry(point.$1, point.$2), a),
    );
  }
  return minDistance;
}

double _distanceLineToLine(
  List<(double, double)> a,
  List<(double, double)> b,
) {
  if (_lineIntersectsLine(a, b)) return 0.0;
  var minDistance = double.infinity;
  for (var i = 0; i < a.length - 1; i++) {
    for (var j = 0; j < b.length - 1; j++) {
      minDistance = math.min(
        minDistance,
        _distanceSegmentToSegment(a[i], a[i + 1], b[j], b[j + 1]),
      );
    }
  }
  return minDistance;
}

double _distanceSegmentToSegment(
  (double, double) a1,
  (double, double) a2,
  (double, double) b1,
  (double, double) b2,
) {
  if (_segmentsIntersect(a1, a2, b1, b2)) return 0.0;
  return [
    _distancePointToSegment(a1, b1, b2),
    _distancePointToSegment(a2, b1, b2),
    _distancePointToSegment(b1, a1, a2),
    _distancePointToSegment(b2, a1, a2),
  ].reduce(math.min);
}

double _distancePointToSegment(
  (double, double) point,
  (double, double) a,
  (double, double) b,
) {
  final dx = b.$1 - a.$1;
  final dy = b.$2 - a.$2;
  if (dx.abs() < _epsilon && dy.abs() < _epsilon) {
    return _distance(point.$1, point.$2, a.$1, a.$2);
  }

  final t =
      (((point.$1 - a.$1) * dx) + ((point.$2 - a.$2) * dy)) / ((dx * dx) + (dy * dy));
  final clamped = t.clamp(0.0, 1.0);
  final projection = (a.$1 + dx * clamped, a.$2 + dy * clamped);
  return _distance(point.$1, point.$2, projection.$1, projection.$2);
}

bool _pointOnSegment(
  (double, double) p,
  (double, double) a,
  (double, double) b,
) {
  final cross = ((b.$1 - a.$1) * (p.$2 - a.$2)) - ((b.$2 - a.$2) * (p.$1 - a.$1));
  if (cross.abs() > _epsilon) return false;

  final dot = ((p.$1 - a.$1) * (b.$1 - a.$1)) + ((p.$2 - a.$2) * (b.$2 - a.$2));
  if (dot < -_epsilon) return false;

  final squaredLength =
      ((b.$1 - a.$1) * (b.$1 - a.$1)) + ((b.$2 - a.$2) * (b.$2 - a.$2));
  return dot <= squaredLength + _epsilon;
}

bool _segmentsIntersect(
  (double, double) a1,
  (double, double) a2,
  (double, double) b1,
  (double, double) b2,
) {
  final o1 = _orientation(a1, a2, b1);
  final o2 = _orientation(a1, a2, b2);
  final o3 = _orientation(b1, b2, a1);
  final o4 = _orientation(b1, b2, a2);

  if (o1 != o2 && o3 != o4) return true;
  if (o1 == 0 && _pointOnSegment(b1, a1, a2)) return true;
  if (o2 == 0 && _pointOnSegment(b2, a1, a2)) return true;
  if (o3 == 0 && _pointOnSegment(a1, b1, b2)) return true;
  if (o4 == 0 && _pointOnSegment(a2, b1, b2)) return true;
  return false;
}

bool _segmentsTouch(
  (double, double) a1,
  (double, double) a2,
  (double, double) b1,
  (double, double) b2,
) {
  if (!_segmentsIntersect(a1, a2, b1, b2)) return false;
  return _pointOnSegment(a1, b1, b2) ||
      _pointOnSegment(a2, b1, b2) ||
      _pointOnSegment(b1, a1, a2) ||
      _pointOnSegment(b2, a1, a2);
}

bool _segmentsCross(
  (double, double) a1,
  (double, double) a2,
  (double, double) b1,
  (double, double) b2,
) {
  if (!_segmentsIntersect(a1, a2, b1, b2)) return false;
  return !_segmentsTouch(a1, a2, b1, b2);
}

int _orientation(
  (double, double) a,
  (double, double) b,
  (double, double) c,
) {
  final value = (b.$2 - a.$2) * (c.$1 - b.$1) -
      (b.$1 - a.$1) * (c.$2 - b.$2);
  if (value.abs() < _epsilon) return 0;
  return value > 0 ? 1 : 2;
}

double _distance(double x1, double y1, double x2, double y2) =>
    math.sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)));

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
