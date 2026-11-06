import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:sefer/features/reader/presentation/book_curl_frame.dart';
import 'package:sefer/features/reader/presentation/book_curl_math.dart';
import 'package:sefer/features/reader/presentation/book_curl_shadow.dart';
import 'package:sefer/features/reader/presentation/book_flip_interaction.dart';

/// Curls a page around the touch that grabbed it. The page is folded along a
/// line perpendicular to the grab-to-finger vector and wrapped half way round
/// a cylinder there, so the grabbed material point lands under the finger.
abstract final class BookCurlGeometry {
  static BookCurlFrame build({
    required Size size,
    required BookCurlEdge edge,
    required BookFlipPose pose,
    BookCurlStyle style = const BookCurlStyle(),
  }) {
    final fold = _Fold.tryCreate(size, edge, pose, style);
    final grid = _Grid.sample(size, style, fold);
    final triangles = _Triangles.classify(grid, style);
    final mirror = edge == BookCurlEdge.left;
    final flip = mirror ? size.width : null;
    final normals = triangles.normals;
    return BookCurlFrame(
      vertices: [
        for (var i = 0; i < grid.count; i++)
          BookCurlVertex(
            position: _mirrored(grid.screen[i], flip),
            texturePosition: _mirrored(grid.source[i], flip),
            depth: grid.depth[i],
            normal: mirror
                ? BookCurlNormal(-normals[i].x, normals[i].y, normals[i].z)
                : normals[i],
          ),
      ],
      frontIndices: triangles.front,
      backIndices: triangles.back,
      shadow: _shadow(grid, pose, style, flip),
    );
  }

  static Offset _mirrored(Offset point, double? width) =>
      width == null ? point : Offset(width - point.dx, point.dy);

  static BookCurlShadow _shadow(
    _Grid grid,
    BookFlipPose pose,
    BookCurlStyle style,
    double? flip,
  ) {
    final shadow = BookCurlShadows.cast(
      screen: grid.screen,
      depths: grid.depth,
      turnFraction: pose.turnFraction,
      style: style,
    );
    return flip == null ? shadow : shadow.mirroredIn(flip);
  }
}

class _Fold {
  _Fold._({
    required this.grab,
    required this.finger,
    required this.along,
    required this.across,
    required this.radius,
    required this.offset,
    required this.bias,
    required this.spineBand,
    required this.perspective,
  });

  static const _epsilon = 1e-4;
  static const _speedScale = 3.0;
  static const _fastRadius = 0.8;
  static const _engageSpan = 0.12;
  static const _maxBias = 0.45;
  static const _minimumScale = 0.2;
  static const _maxTilt = 0.6;
  static const _tiltRampFraction = 0.2;

  // A short pull is mostly finger jitter, so its vertical part may only tilt
  // the fold gently, and only once the page has travelled some way.
  static Offset _steadied(Offset grab, Offset finger, double width) {
    final pull = grab - finger;
    final ramp = smoothstep(0, _tiltRampFraction * width, pull.dx);
    final limit = pull.dx * math.tan(_maxTilt) * ramp;
    return grab - Offset(pull.dx, pull.dy.clamp(-limit, limit));
  }

  final Offset grab;
  final Offset finger;
  final Offset along;
  final Offset across;
  final double radius;
  final double offset;
  final double bias;
  final double spineBand;
  final double perspective;

  static _Fold? tryCreate(
    Size size,
    BookCurlEdge edge,
    BookFlipPose pose,
    BookCurlStyle style,
  ) {
    final width = size.width;
    final height = size.height;
    if (width <= _epsilon || height <= _epsilon) return null;
    Offset canonical(Offset normalized) => Offset(
      (edge == BookCurlEdge.right ? normalized.dx : 1 - normalized.dx) * width,
      normalized.dy * height,
    );
    final start = canonical(pose.start);
    final grab = Offset(
      start.dx.clamp(0.0, width),
      start.dy.clamp(0.0, height),
    );
    final reach = canonical(pose.current);
    final finger = _steadied(
      grab,
      Offset(reach.dx.clamp(-2 * width, grab.dx), rubberBand(reach.dy, height)),
      width,
    );
    final pull = grab - finger;
    final distance = pull.distance;
    if (distance < _epsilon) return null;
    final turn = pose.turnFraction;
    final speed = (pose.velocity.distance / _speedScale).clamp(0.0, 1.0);
    final radius = math.min(
      width *
          style.radiusFraction *
          math.sin(math.pi * turn / 2) *
          (1 + (_fastRadius - 1) * speed),
      distance / math.pi,
    );
    if (radius < _epsilon) return null;
    final along = pull / distance;
    final across = Offset(-along.dy, along.dx);
    final engagement = smoothstep(0, _engageSpan, turn);
    return _Fold._(
      grab: grab,
      finger: finger,
      along: along,
      across: across,
      radius: radius,
      offset: (dot(grab, along) + dot(finger, along) - math.pi * radius) / 2,
      bias: (style.touchBiasStrength * (1 - 2 * grab.dy / height) * engagement)
          .clamp(-_maxBias, _maxBias),
      spineBand: style.spineBand * width,
      perspective: style.perspective,
    );
  }

  (Offset, double) map(Offset point) {
    final distance =
        dot(point, along) -
        (offset + bias * (dot(point, across) - dot(grab, across)));
    final (shift, lift) = _wrap(distance);
    final pin = smoothstep(0, spineBand, point.dx);
    final lifted = Offset.lerp(point, point + along * shift, pin)!;
    final depth = lift * pin;
    if (depth <= 0) return (lifted, 0);
    final scale = 1 / math.max(_minimumScale, 1 + perspective * depth);
    return (finger + (lifted - finger) * scale, depth);
  }

  (double, double) _wrap(double distance) {
    if (distance <= 0) return (0, 0);
    if (distance >= math.pi * radius) {
      return (math.pi * radius - 2 * distance, 2 * radius);
    }
    final angle = distance / radius;
    return (
      radius * math.sin(angle) - distance,
      radius * (1 - math.cos(angle)),
    );
  }
}

class _Grid {
  _Grid._(this.count)
    : source = List.filled(count, Offset.zero),
      screen = List.filled(count, Offset.zero),
      depth = Float64List(count);

  factory _Grid.sample(Size size, BookCurlStyle style, _Fold? fold) {
    final stride = style.columns + 1;
    final grid = _Grid._(stride * (style.rows + 1));
    for (var row = 0; row <= style.rows; row++) {
      for (var column = 0; column < stride; column++) {
        final index = row * stride + column;
        final point = Offset(
          size.width * column / style.columns,
          size.height * row / style.rows,
        );
        final (mapped, lift) = fold?.map(point) ?? (point, 0.0);
        grid.source[index] = point;
        grid.screen[index] = mapped;
        grid.depth[index] = lift;
      }
    }
    return grid;
  }

  final int count;
  final List<Offset> source;
  final List<Offset> screen;
  final Float64List depth;
}

class _Triangles {
  _Triangles._(this.front, this.back, this.normals);

  static const _degenerateArea = 1e-12;

  final Uint16List front;
  final Uint16List back;
  final List<BookCurlNormal> normals;

  factory _Triangles.classify(_Grid grid, BookCurlStyle style) {
    final topology = GridTopology.of(style.rows, style.columns);
    final indices = topology.triangles;
    final sums = List.filled(grid.count * 3, 0.0);
    final minimumArea =
        _degenerateArea * (grid.source.last.dx * grid.source.last.dy).abs();
    final front = <int>[];
    final back = <(double, int)>[];
    for (var at = 0; at < indices.length; at += 3) {
      final corners = [indices[at], indices[at + 1], indices[at + 2]];
      final cross = _faceNormal(grid, corners);
      for (final corner in corners) {
        sums[corner * 3] += cross.x;
        sums[corner * 3 + 1] += cross.y;
        sums[corner * 3 + 2] += cross.z;
      }
      if (_projectedArea(grid, corners) <= minimumArea) continue;
      if (cross.z > 0) {
        front.add(at);
      } else {
        final lift = corners.fold(0.0, (sum, i) => sum + grid.depth[i]);
        back.add((lift, at));
      }
    }
    back.sort((a, b) => a.$1.compareTo(b.$1));
    return _Triangles._(
      _gather(indices, front),
      _gather(indices, [for (final (_, at) in back) at]),
      [
        for (var i = 0; i < grid.count; i++)
          _unit(sums[i * 3], sums[i * 3 + 1], sums[i * 3 + 2]),
      ],
    );
  }

  static BookCurlNormal _faceNormal(_Grid grid, List<int> corners) {
    final a = grid.screen[corners[0]];
    final b = grid.screen[corners[1]];
    final c = grid.screen[corners[2]];
    final za = grid.depth[corners[0]];
    final ux = b.dx - a.dx, uy = b.dy - a.dy, uz = grid.depth[corners[1]] - za;
    final vx = c.dx - a.dx, vy = c.dy - a.dy, vz = grid.depth[corners[2]] - za;
    return BookCurlNormal(
      uy * vz - uz * vy,
      uz * vx - ux * vz,
      ux * vy - uy * vx,
    );
  }

  static double _projectedArea(_Grid grid, List<int> corners) {
    final a = grid.screen[corners[0]];
    final b = grid.screen[corners[1]];
    final c = grid.screen[corners[2]];
    return ((b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx))
            .abs() /
        2;
  }

  static Uint16List _gather(Uint16List indices, List<int> starts) {
    final gathered = Uint16List(starts.length * 3);
    for (var i = 0; i < starts.length; i++) {
      gathered.setRange(i * 3, i * 3 + 3, indices, starts[i]);
    }
    return gathered;
  }

  static BookCurlNormal _unit(double x, double y, double z) {
    final length = math.sqrt(x * x + y * y + z * z);
    if (length < 1e-12) return BookCurlNormal.flat;
    return BookCurlNormal(x / length, y / length, z / length);
  }
}
