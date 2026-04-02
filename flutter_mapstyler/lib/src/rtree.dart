import 'dart:math' as math;

import 'package:mapstyler_style/mapstyler_style.dart';

import 'geometry_ops.dart';

/// R-Tree mit STR (Sort-Tile-Recursive) Bulk-Loading fuer raeumliche Abfragen.
///
/// Jedes Feature wird mit seiner BBox indiziert. [search] liefert alle
/// Feature-Indizes deren BBox den Suchbereich schneidet — O(log n) statt O(n).
///
/// Der Baum ist immutable nach dem Aufbau. Fuer Aenderungen an der
/// Feature-Liste muss ein neuer Baum erstellt werden.
class RTree {
  RTree._(this._root, this._length);

  /// Baut einen R-Tree aus den BBoxen der gegebenen Geometrien.
  ///
  /// [geometries] wird per Index referenziert — die zurueckgegebenen Indizes
  /// aus [search] entsprechen den Positionen in dieser Liste.
  factory RTree.bulk(List<Geometry> geometries, {int maxEntries = 9}) {
    if (geometries.isEmpty) return RTree._(null, 0);

    final items = List<_RNode>.generate(geometries.length, (i) {
      final env = geometryEnvelope(geometries[i]);
      return _RLeaf(env.minX, env.minY, env.maxX, env.maxY, i);
    });

    return RTree._(_buildSTR(items, maxEntries), geometries.length);
  }

  final _RNode? _root;
  final int _length;

  /// Gibt alle Feature-Indizes zurueck deren BBox [envelope] schneidet.
  List<int> search(EnvelopeGeometry envelope) {
    if (_root == null) return const [];
    final results = <int>[];
    _search(_root, envelope, results);
    return results;
  }

  /// Gibt `true` zurueck wenn mindestens ein Feature [envelope] schneidet.
  bool any(EnvelopeGeometry envelope) {
    if (_root == null) return false;
    return _any(_root, envelope);
  }

  /// Anzahl der indizierten Features (O(1)).
  int get length => _length;

  static void _search(_RNode? node, EnvelopeGeometry env, List<int> results) {
    if (node == null) return;
    if (!_intersects(node, env)) return;

    if (node is _RLeaf) {
      results.add(node.featureIndex);
      return;
    }

    final branch = node as _RBranch;
    for (final child in branch.children) {
      _search(child, env, results);
    }
  }

  static bool _any(_RNode? node, EnvelopeGeometry env) {
    if (node == null) return false;
    if (!_intersects(node, env)) return false;
    if (node is _RLeaf) return true;
    final branch = node as _RBranch;
    for (final child in branch.children) {
      if (_any(child, env)) return true;
    }
    return false;
  }

  static bool _intersects(_RNode node, EnvelopeGeometry env) =>
      node.minX <= env.maxX &&
      node.maxX >= env.minX &&
      node.minY <= env.maxY &&
      node.maxY >= env.minY;
}

/// STR Bulk-Loading: sortiert Items abwechselnd nach X und Y,
/// gruppiert in Knoten mit maximal [maxEntries] Kindern, bottom-up.
///
/// Sortiert auf einer Kopie um die Eingabeliste nicht zu mutieren.
_RNode _buildSTR(List<_RNode> items, int maxEntries) {
  if (items.length <= maxEntries) {
    if (items.length == 1) return items.first;
    return _makeBranch(items);
  }

  // Anzahl Slices: ceil(sqrt(n / M))
  final sliceCount = math.max(1, (math.sqrt(items.length / maxEntries)).ceil());
  final sliceSize = (items.length / sliceCount).ceil();

  // Nach X-Zentrum sortieren (Kopie, damit die Eingabe stabil bleibt).
  final sorted = items.toList()
    ..sort((a, b) =>
        ((a.minX + a.maxX) * 0.5).compareTo((b.minX + b.maxX) * 0.5));

  final parents = <_RNode>[];

  for (var i = 0; i < sorted.length; i += sliceSize) {
    final sliceEnd = math.min(i + sliceSize, sorted.length);
    final slice = sorted.sublist(i, sliceEnd);

    // Innerhalb des Slices nach Y-Zentrum sortieren.
    slice.sort((a, b) =>
        ((a.minY + a.maxY) * 0.5).compareTo((b.minY + b.maxY) * 0.5));

    // Gruppen mit max maxEntries bilden → Parent-Knoten.
    for (var j = 0; j < slice.length; j += maxEntries) {
      final groupEnd = math.min(j + maxEntries, slice.length);
      parents.add(_makeBranch(slice.sublist(j, groupEnd)));
    }
  }

  // Rekursiv: naechste Ebene bauen.
  return _buildSTR(parents, maxEntries);
}

/// Erstellt einen Branch-Knoten aus seinen Kindern mit berechneter BBox.
_RBranch _makeBranch(List<_RNode> children) {
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (final child in children) {
    minX = math.min(minX, child.minX);
    minY = math.min(minY, child.minY);
    maxX = math.max(maxX, child.maxX);
    maxY = math.max(maxY, child.maxY);
  }
  return _RBranch(minX, minY, maxX, maxY, children);
}

/// Basis-Klasse fuer R-Tree-Knoten.
sealed class _RNode {
  const _RNode(this.minX, this.minY, this.maxX, this.maxY);
  final double minX, minY, maxX, maxY;
}

/// Blatt-Knoten: speichert den Feature-Index.
final class _RLeaf extends _RNode {
  const _RLeaf(super.minX, super.minY, super.maxX, super.maxY, this.featureIndex);
  final int featureIndex;
}

/// Innerer Knoten: speichert eine Liste von Kind-Knoten.
final class _RBranch extends _RNode {
  const _RBranch(
    super.minX,
    super.minY,
    super.maxX,
    super.maxY,
    this.children,
  );
  final List<_RNode> children;
}
