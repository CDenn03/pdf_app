import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/book_curl_frame.dart';
import 'package:sefer/features/reader/presentation/book_curl_geometry.dart';
import 'package:sefer/features/reader/presentation/book_flip_interaction.dart';
import 'package:sefer/features/reader/presentation/book_page_curl_painter.dart';
import 'package:sefer/features/reader/presentation/book_page_shadow_painter.dart';

const _size = Size(200, 300);

BookCurlFrame _frame(BookCurlEdge edge, {double turn = 0.6}) {
  final grabX = edge == BookCurlEdge.right ? 0.9 : 0.1;
  final pull = edge == BookCurlEdge.right ? -turn : turn;
  return BookCurlGeometry.build(
    size: _size,
    edge: edge,
    pose: BookFlipPose(
      start: Offset(grabX, 0.2),
      current: Offset(grabX + pull, 0.5),
      velocity: Offset.zero,
      turnFraction: turn,
    ),
  );
}

void _paint(CustomPainter painter) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), _size);
  recorder.endRecording().dispose();
}

void main() {
  late ui.Image image;

  setUp(() async {
    image = (await TestWidgetsFlutterBinding.ensureInitialized().runAsync(
      () => createTestImage(width: 4, height: 6),
    ))!;
  });

  tearDown(() => image.dispose());

  group('BookPageCurlPainter', () {
    for (final edge in BookCurlEdge.values) {
      test('paints front and back faces on the ${edge.name} edge', () {
        final frame = _frame(edge);
        expect(frame.frontIndices, isNotEmpty);
        expect(frame.backIndices, isNotEmpty);

        _paint(BookPageCurlPainter(image: image, frame: frame));
      });
    }

    test('repaints only when the frame, image or style changes', () {
      final frame = _frame(BookCurlEdge.right);
      final painter = BookPageCurlPainter(image: image, frame: frame);

      expect(
        painter.shouldRepaint(BookPageCurlPainter(image: image, frame: frame)),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          BookPageCurlPainter(image: image, frame: _frame(BookCurlEdge.right)),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          BookPageCurlPainter(
            image: image,
            frame: frame,
            style: const BookCurlStyle(backBase: 0.5),
          ),
        ),
        isTrue,
      );
    });
  });

  group('BookPageShadowPainter', () {
    test('paints the shadow of a curl on either edge', () {
      for (final edge in BookCurlEdge.values) {
        _paint(BookPageShadowPainter(shadow: _frame(edge).shadow));
      }
    });

    test('paints nothing for a flat page', () {
      _paint(const BookPageShadowPainter(shadow: BookCurlShadow.none));
    });

    test('repaints only for a different shadow', () {
      final shadow = _frame(BookCurlEdge.right).shadow;
      final painter = BookPageShadowPainter(shadow: shadow);

      expect(
        painter.shouldRepaint(BookPageShadowPainter(shadow: shadow)),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          BookPageShadowPainter(shadow: _frame(BookCurlEdge.left).shadow),
        ),
        isTrue,
      );
    });
  });
}
