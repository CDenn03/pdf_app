import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/core/utils/coordinate_mapper.dart';

void main() {
  group('toAbsolute', () {
    test('full page rect maps to full page size', () {
      const rel = RelativeRectModel(top: 0, left: 0, bottom: 1, right: 1);
      const pageSize = Size(800, 1200);

      final result = toAbsolute(rel, pageSize);

      expect(result, const Rect.fromLTRB(0, 0, 800, 1200));
    });

    test('mid-page rect maps correctly', () {
      const rel = RelativeRectModel(
        top: 0.25,
        left: 0.1,
        bottom: 0.75,
        right: 0.9,
      );
      const pageSize = Size(1000, 2000);

      final result = toAbsolute(rel, pageSize);

      expect(result.left, closeTo(100, 0.001));
      expect(result.top, closeTo(500, 0.001));
      expect(result.right, closeTo(900, 0.001));
      expect(result.bottom, closeTo(1500, 0.001));
    });

    test('zero-size rect produces zero-size absolute rect', () {
      const rel = RelativeRectModel(
        top: 0.5,
        left: 0.5,
        bottom: 0.5,
        right: 0.5,
      );
      const pageSize = Size(600, 800);

      final result = toAbsolute(rel, pageSize);

      expect(result.width, 0);
      expect(result.height, 0);
    });

    test('works with non-standard page sizes', () {
      const rel = RelativeRectModel(
        top: 0.0,
        left: 0.0,
        bottom: 0.5,
        right: 0.5,
      );
      const pageSize = Size(333, 777);

      final result = toAbsolute(rel, pageSize);

      expect(result.left, closeTo(0, 0.001));
      expect(result.top, closeTo(0, 0.001));
      expect(result.right, closeTo(166.5, 0.001));
      expect(result.bottom, closeTo(388.5, 0.001));
    });
  });

  group('toRelative', () {
    test('full page absolute rect maps to 0-1 range', () {
      const absoluteRect = Rect.fromLTRB(0, 0, 800, 1200);
      const pageSize = Size(800, 1200);

      final result = toRelative(absoluteRect, pageSize);

      expect(result.left, closeTo(0, 0.001));
      expect(result.top, closeTo(0, 0.001));
      expect(result.right, closeTo(1, 0.001));
      expect(result.bottom, closeTo(1, 0.001));
    });

    test('round-trip: toAbsolute then toRelative returns original', () {
      const original = RelativeRectModel(
        top: 0.3,
        left: 0.2,
        bottom: 0.7,
        right: 0.8,
      );
      const pageSize = Size(1024, 768);

      final absolute = toAbsolute(original, pageSize);
      final roundTrip = toRelative(absolute, pageSize);

      expect(roundTrip.left, closeTo(original.left, 0.0001));
      expect(roundTrip.top, closeTo(original.top, 0.0001));
      expect(roundTrip.right, closeTo(original.right, 0.0001));
      expect(roundTrip.bottom, closeTo(original.bottom, 0.0001));
    });
  });
}
