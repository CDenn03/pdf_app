import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

double smoothstep(double edge0, double edge1, double value) {
  if (edge1 <= edge0) return value >= edge1 ? 1 : 0;
  final t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

/// Pulls a value that left `[0, max]` back so it can only overshoot a little.
double rubberBand(double value, double max) {
  final limit = max * 0.25;
  if (value < 0) return -limit * (1 - math.exp(value / limit));
  if (value > max) return max + limit * (1 - math.exp((max - value) / limit));
  return value;
}

/// The triangles of a regular grid of vertices, row by row.
class GridTopology {
  GridTopology._(this.rows, this.columns, this.triangles);

  static GridTopology? _cached;

  final int rows;
  final int columns;
  final Uint16List triangles;

  factory GridTopology.of(int rows, int columns) {
    final cached = _cached;
    if (cached != null && cached.rows == rows && cached.columns == columns) {
      return cached;
    }
    final stride = columns + 1;
    final triangles = Uint16List(rows * columns * 6);
    var next = 0;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final topLeft = row * stride + column;
        final bottomLeft = topLeft + stride;
        triangles
          ..[next++] = topLeft
          ..[next++] = topLeft + 1
          ..[next++] = bottomLeft
          ..[next++] = topLeft + 1
          ..[next++] = bottomLeft + 1
          ..[next++] = bottomLeft;
      }
    }
    return _cached = GridTopology._(rows, columns, triangles);
  }
}

List<Offset> convexHull(List<Offset> points) {
  if (points.length < 3) return List.of(points);
  final sorted = List.of(
    points,
  )..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  final lower = _halfHull(sorted);
  final upper = _halfHull(sorted.reversed.toList());
  return [...lower..removeLast(), ...upper..removeLast()];
}

List<Offset> _halfHull(List<Offset> sorted) {
  final hull = <Offset>[];
  for (final point in sorted) {
    while (hull.length >= 2 &&
        _turn(hull[hull.length - 2], hull.last, point) <= 0) {
      hull.removeLast();
    }
    hull.add(point);
  }
  return hull;
}

double _turn(Offset a, Offset b, Offset c) =>
    (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
