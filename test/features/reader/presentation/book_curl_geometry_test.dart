import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/book_curl_frame.dart';
import 'package:sefer/features/reader/presentation/book_curl_geometry.dart';
import 'package:sefer/features/reader/presentation/book_flip_interaction.dart';

const _size = Size(320, 480);
const _style = BookCurlStyle();

BookFlipPose _pose({
  Offset start = const Offset(0.9375, 0.5),
  Offset current = const Offset(0.4, 0.5),
  Offset velocity = Offset.zero,
  double turnFraction = 0.5,
}) => BookFlipPose(
  start: start,
  current: current,
  velocity: velocity,
  turnFraction: turnFraction,
);

BookCurlFrame _build(
  BookFlipPose pose, {
  Size size = _size,
  BookCurlEdge edge = BookCurlEdge.right,
}) => BookCurlGeometry.build(size: size, edge: edge, pose: pose);

BookCurlVertex _at(BookCurlFrame frame, int row, int column) =>
    frame.vertices[row * (_style.columns + 1) + column];

Iterable<BookCurlVertex> _spine(BookCurlFrame frame) sync* {
  for (var row = 0; row <= _style.rows; row++) {
    yield _at(frame, row, 0);
  }
}

void _expectSane(BookCurlFrame frame) {
  final count = frame.vertices.length;
  for (final vertex in frame.vertices) {
    expect(vertex.position.isFinite, isTrue);
    expect(vertex.depth.isFinite, isTrue);
    final n = vertex.normal;
    expect(math.sqrt(n.x * n.x + n.y * n.y + n.z * n.z), closeTo(1, 1e-9));
  }
  for (final index in [...frame.frontIndices, ...frame.backIndices]) {
    expect(index, inInclusiveRange(0, count - 1));
  }
  expect(frame.frontIndices.length % 3, 0);
  expect(frame.backIndices.length % 3, 0);
  final shadow = frame.shadow;
  expect(shadow.opacity.isFinite && shadow.blurSigma.isFinite, isTrue);
  expect(shadow.foldPoint.isFinite && shadow.castPoint.isFinite, isTrue);
  expect(shadow.footprint.every((point) => point.isFinite), isTrue);
}

void main() {
  steadinessTests();

  group('rest', () {
    test('zero displacement is the flat page', () {
      final frame = _build(_pose(current: const Offset(0.9375, 0.5)));

      for (final vertex in frame.vertices) {
        expect(vertex.position, vertex.texturePosition);
        expect(vertex.depth, 0);
        expect(vertex.normal.z, 1);
      }
      expect(frame.backIndices, isEmpty);
      expect(frame.shadow.opacity, 0);
    });

    test('a tiny displacement stays flat', () {
      final frame = _build(_pose(current: const Offset(0.9375, 0.50000001)));

      expect(frame.backIndices, isEmpty);
    });

    test('turn fraction zero is flat', () {
      final frame = _build(_pose(turnFraction: 0));

      expect(frame.backIndices, isEmpty);
      _expectSane(frame);
    });

    test('mesh density follows the style', () {
      final frame = BookCurlGeometry.build(
        size: _size,
        edge: BookCurlEdge.right,
        pose: _pose(),
        style: const BookCurlStyle(rows: 6, columns: 9),
      );

      expect(frame.vertices.length, 7 * 10);
      expect(
        frame.frontIndices.length + frame.backIndices.length,
        lessThanOrEqualTo(6 * 9 * 6),
      );
    });
  });

  group('touch', () {
    test('the grabbed material point lands under the finger', () {
      final pose = _pose();
      final frame = _build(pose);

      final grabbed = _at(frame, 10, 30);

      expect(grabbed.texturePosition, const Offset(300, 240));
      expect(grabbed.position.dx, closeTo(pose.current.dx * 320, 1e-6));
      expect(grabbed.position.dy, closeTo(pose.current.dy * 480, 1e-6));
    });

    test('the grabbed point follows an off-axis finger', () {
      final pose = _pose(current: const Offset(0.3, 0.7), turnFraction: 0.6);
      final grabbed = _at(_build(pose), 10, 30);

      expect(grabbed.position.dx, closeTo(0.3 * 320, 1e-6));
      expect(grabbed.position.dy, closeTo(0.7 * 480, 1e-6));
    });

    test('a centre touch is symmetric about the middle row', () {
      final frame = _build(_pose());

      for (var row = 0; row <= 10; row++) {
        final top = _at(frame, row, 20);
        final bottom = _at(frame, 20 - row, 20);
        expect(top.position.dx, closeTo(bottom.position.dx, 1e-9));
        expect(top.position.dy + bottom.position.dy, closeTo(480, 1e-9));
      }
    });

    test('top and bottom grabs are mirrored and differ from the middle', () {
      final top = _build(_pose(start: const Offset(0.9375, 0.125)));
      final bottom = _build(_pose(start: const Offset(0.9375, 0.875)));
      final middle = _build(_pose());

      double foldColumn(BookCurlFrame frame, int row) {
        var column = 0;
        while (column < _style.columns &&
            _at(frame, row, column + 1).depth == 0) {
          column++;
        }
        return column.toDouble();
      }

      expect(foldColumn(top, 0), isNot(foldColumn(top, _style.rows)));
      expect(
        foldColumn(top, 0) - foldColumn(top, _style.rows),
        closeTo(-(foldColumn(bottom, 0) - foldColumn(bottom, _style.rows)), 1),
      );
      expect(foldColumn(middle, 0), closeTo(foldColumn(middle, 20), 0));
    });

    test('a diagonal finger tilts the fold', () {
      final straight = _build(_pose());
      final tilted = _build(
        _pose(current: const Offset(0.4, 0.8), turnFraction: 0.5),
      );

      double lift(BookCurlFrame frame, int row) => _at(frame, row, 20).depth;

      expect((lift(straight, 0) - lift(straight, 20)).abs(), lessThan(1e-9));
      expect((lift(tilted, 0) - lift(tilted, 20)).abs(), greaterThan(1));
    });

    test('the left edge mirrors the right edge', () {
      final right = _build(_pose());
      final left = _build(
        _pose(
          start: const Offset(0.0625, 0.5),
          current: const Offset(0.6, 0.5),
        ),
        edge: BookCurlEdge.left,
      );

      for (var i = 0; i < right.vertices.length; i++) {
        expect(
          left.vertices[i].position.dx,
          closeTo(320 - right.vertices[i].position.dx, 1e-9),
        );
        expect(
          left.vertices[i].position.dy,
          closeTo(right.vertices[i].position.dy, 1e-9),
        );
        expect(
          left.vertices[i].texturePosition.dx,
          closeTo(320 - right.vertices[i].texturePosition.dx, 1e-9),
        );
        expect(
          left.vertices[i].normal.x,
          closeTo(-right.vertices[i].normal.x, 1e-9),
        );
      }
    });
  });

  group('invariants', () {
    test('the spine never moves, corners included', () {
      for (final pose in [
        _pose(),
        _pose(current: const Offset(-0.5, 0.9), turnFraction: 1),
        _pose(start: const Offset(1, 1), current: const Offset(0.2, 0.1)),
      ]) {
        final frame = _build(pose);
        for (final vertex in _spine(frame)) {
          expect(vertex.position, vertex.texturePosition);
          expect(vertex.depth, 0);
        }
      }
    });

    test('the spine is fixed on the left edge too', () {
      final frame = _build(
        _pose(
          start: const Offset(0.0625, 0.5),
          current: const Offset(0.6, 0.5),
        ),
        edge: BookCurlEdge.left,
      );

      for (final vertex in _spine(frame)) {
        expect(vertex.position.dx, 320);
        expect(vertex.position, vertex.texturePosition);
      }
    });

    test('texture coordinates stay within the page', () {
      final frame = _build(_pose(current: const Offset(-0.5, 0.2)));

      for (final vertex in frame.vertices) {
        expect(vertex.texturePosition.dx, inInclusiveRange(0, 320));
        expect(vertex.texturePosition.dy, inInclusiveRange(0, 480));
      }
    });

    test('a folded page has a back and a shadow', () {
      final frame = _build(_pose());

      expect(frame.backIndices, isNotEmpty);
      expect(frame.frontIndices, isNotEmpty);
      expect(frame.shadow.opacity, greaterThan(0));
      expect(frame.shadow.footprint.length, greaterThanOrEqualTo(3));
    });

    test('the shadow follows the fold', () {
      final straight = _build(_pose()).shadow;
      final tilted = _build(_pose(current: const Offset(0.4, 0.9))).shadow;

      expect(tilted.foldPoint.dy, greaterThan(straight.foldPoint.dy));
    });

    test('back triangles run from furthest to nearest', () {
      final frame = _build(_pose());
      final indices = frame.backIndices;
      double lift(int at) => indices
          .sublist(at, at + 3)
          .fold(0.0, (sum, i) => sum + frame.vertices[i].depth);

      for (var at = 3; at < indices.length; at += 3) {
        expect(lift(at), greaterThanOrEqualTo(lift(at - 3) - 1e-9));
      }
    });
  });

  group('robustness', () {
    final poses = <String, BookFlipPose>{
      'turn zero': _pose(turnFraction: 0),
      'turn one': _pose(turnFraction: 1),
      'corner touch': _pose(start: const Offset(1, 1), turnFraction: 0.4),
      'top corner': _pose(start: const Offset(1, 0), turnFraction: 0.4),
      'off page': _pose(current: const Offset(-3, 4), turnFraction: 0.7),
      'far right': _pose(current: const Offset(5, -2)),
      'fast': _pose(velocity: const Offset(-40, 25)),
      'settled': _pose(current: const Offset(-0.9375, 0.5), turnFraction: 1),
    };

    for (final entry in poses.entries) {
      test('${entry.key} gives a finite mesh', () {
        for (final edge in BookCurlEdge.values) {
          _expectSane(_build(entry.value, edge: edge));
        }
      });
    }

    for (final size in [
      const Size(1, 1000),
      const Size(1000, 1),
      const Size(0, 100),
      const Size(300, 0),
    ]) {
      test('size $size gives a finite mesh', () {
        _expectSane(_build(_pose(), size: size));
      });
    }
  });
}

void steadinessTests() {
  const size = Size(200, 300);

  BookCurlFrame curl(Offset current) => BookCurlGeometry.build(
    size: size,
    edge: BookCurlEdge.right,
    pose: BookFlipPose(
      start: const Offset(0.9, 0.5),
      current: current,
      velocity: Offset.zero,
      turnFraction: 0.3,
    ),
  );

  bool isFlat(BookCurlFrame frame) =>
      frame.vertices.every((vertex) => vertex.depth == 0);

  group('steadiness', () {
    test('a purely vertical pull leaves the page flat', () {
      expect(isFlat(curl(const Offset(0.9, 0.9))), isTrue);
    });

    test('a short pull barely tilts the fold however far it drifts', () {
      final frame = curl(const Offset(0.88, 0.95));
      final depths = [for (final vertex in frame.vertices) vertex.depth];

      expect(depths.reduce(math.max), lessThan(size.width * 0.05));
    });
  });
}
