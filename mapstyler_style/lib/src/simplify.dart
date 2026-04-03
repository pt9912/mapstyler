/// Geometry simplification for coordinate lists.
///
/// Provides [simplifyLine] for open polylines and [simplifyRing] for
/// closed polygon rings.  Both use a two-stage approach:
///
/// 1. **Radial pre-filter** — removes points closer than [tolerance]
///    to the previous kept point.  O(n), single pass.
/// 2. **Douglas-Peucker** — recursive shape-preserving simplification.
///    O(n log n) average case.
///
/// All distance comparisons use squared values to avoid `sqrt` calls.

/// Simplifies an open polyline.
///
/// Start and end points are always preserved.  Returns the original
/// list unchanged when [tolerance] is not positive or the line has
/// two or fewer points.
///
/// [tolerance] is in the same unit as the coordinates (degrees for
/// EPSG:4326, metres for projected CRS).
List<(double, double)> simplifyLine(
  List<(double, double)> coords,
  double tolerance,
) {
  if (tolerance <= 0 || coords.length <= 2) return coords;
  return _douglasPeucker(_radialFilter(coords, tolerance), tolerance);
}

/// Simplifies a closed polygon ring.
///
/// Temporarily removes the closing point, simplifies, and restores
/// the closure.  If the result has fewer than 3 unique points the
/// original ring is returned unchanged — callers can rely on the
/// output being a valid ring or the unmodified input.
///
/// [tolerance] is in the same unit as the coordinates.
List<(double, double)> simplifyRing(
  List<(double, double)> coords,
  double tolerance,
) {
  if (tolerance <= 0 || coords.length <= 4) return coords;

  final closed = coords.first == coords.last;
  var open = closed ? coords.sublist(0, coords.length - 1) : coords;

  open = _radialFilter(open, tolerance);
  open = _douglasPeucker(open, tolerance);

  if (open.length < 3) return coords; // degenerate → return original
  if (closed) open = [...open, open.first];
  return open;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Removes points that are closer than [tolerance] to the previously
/// kept point.  Start and end points are always kept.
List<(double, double)> _radialFilter(
  List<(double, double)> coords,
  double tolerance,
) {
  if (coords.length <= 2) return coords;
  final tolSq = tolerance * tolerance;
  final result = [coords.first];

  for (var i = 1; i < coords.length - 1; i++) {
    final (px, py) = result.last;
    final (cx, cy) = coords[i];
    final dx = cx - px;
    final dy = cy - py;
    if (dx * dx + dy * dy >= tolSq) {
      result.add(coords[i]);
    }
  }

  result.add(coords.last);
  return result;
}

/// Recursive Douglas-Peucker simplification.
///
/// Finds the point with the largest perpendicular distance to the
/// line between first and last point.  If it exceeds [tolerance],
/// the line is split and both halves are simplified recursively.
List<(double, double)> _douglasPeucker(
  List<(double, double)> coords,
  double tolerance,
) {
  if (coords.length <= 2) return coords;

  final (sx, sy) = coords.first;
  final (ex, ey) = coords.last;
  final dx = ex - sx;
  final dy = ey - sy;
  final lenSq = dx * dx + dy * dy;
  final tolSq = tolerance * tolerance;

  var maxDistSq = 0.0;
  var maxIdx = 0;

  for (var i = 1; i < coords.length - 1; i++) {
    final (px, py) = coords[i];
    double distSq;
    if (lenSq == 0) {
      // Start == end → distance to point.
      final dpx = px - sx;
      final dpy = py - sy;
      distSq = dpx * dpx + dpy * dpy;
    } else {
      final t = (((px - sx) * dx + (py - sy) * dy) / lenSq).clamp(0.0, 1.0);
      final projX = sx + t * dx;
      final projY = sy + t * dy;
      final dpx = px - projX;
      final dpy = py - projY;
      distSq = dpx * dpx + dpy * dpy;
    }
    if (distSq > maxDistSq) {
      maxDistSq = distSq;
      maxIdx = i;
    }
  }

  if (maxDistSq < tolSq) {
    return [coords.first, coords.last];
  }

  final left = _douglasPeucker(coords.sublist(0, maxIdx + 1), tolerance);
  final right = _douglasPeucker(coords.sublist(maxIdx), tolerance);
  return [...left, ...right.skip(1)];
}
