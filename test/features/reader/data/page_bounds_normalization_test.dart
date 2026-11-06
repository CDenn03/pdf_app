import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/pdfrx_page_bounds.dart';
import '../support/fake_pdfrx_page.dart';

void main() {
  group('normalizePageBounds', () {
    final page = FakePdfrxPage(width: 200, height: 400);

    test('maps PDF points to top-left origin fractions of the page', () {
      const bounds = PdfRect(20, 380, 100, 360);

      final normalized = normalizePageBounds(bounds, page);

      expect(normalized.left, closeTo(0.1, 1e-9));
      expect(normalized.right, closeTo(0.5, 1e-9));
      expect(normalized.top, closeTo(0.05, 1e-9));
      expect(normalized.bottom, closeTo(0.1, 1e-9));
    });

    test('a bound covering the whole page spans 0 to 1', () {
      const bounds = PdfRect(0, 400, 200, 0);

      final normalized = normalizePageBounds(bounds, page);

      expect(normalized.left, 0);
      expect(normalized.top, 0);
      expect(normalized.right, 1);
      expect(normalized.bottom, 1);
    });

    test('text at the bottom of the page lands near the bottom fraction', () {
      const bounds = PdfRect(10, 20, 50, 5);

      final normalized = normalizePageBounds(bounds, page);

      expect(normalized.top, greaterThan(0.9));
      expect(normalized.bottom, lessThan(1.0));
    });
  });

  group('round trip through the page coordinate space', () {
    const bounds = PdfRect(30, 150, 90, 120);

    for (final rotation in PdfPageRotation.values) {
      test('survives a page rotated by $rotation', () {
        final page = FakePdfrxPage(width: 200, height: 300, rotation: rotation);

        final normalized = normalizePageBounds(bounds, page);
        final restored = pageBoundsFromNormalized(normalized, page);

        expect(restored.left, closeTo(bounds.left, 1e-6));
        expect(restored.top, closeTo(bounds.top, 1e-6));
        expect(restored.right, closeTo(bounds.right, 1e-6));
        expect(restored.bottom, closeTo(bounds.bottom, 1e-6));
      });
    }
  });
}
