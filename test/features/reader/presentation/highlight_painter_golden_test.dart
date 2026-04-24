import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/features/reader/presentation/highlight_painter.dart';

const _painterKey = ValueKey('highlight_painter');

/// Renders [HighlightPainter] in isolation at a fixed size on a white canvas.
Widget _buildPainter({
  required List<RelativeRectModel> highlights,
  Size pageSize = const Size(400, 600),
}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: pageSize.width,
        height: pageSize.height,
        child: CustomPaint(
          key: _painterKey,
          painter: HighlightPainter(highlights: highlights, pageSize: pageSize),
        ),
      ),
    ),
  );
}

void main() {
  group('HighlightPainter golden tests', () {
    testWidgets('renders nothing when highlights list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildPainter(highlights: const []));

      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('goldens/highlight_painter_empty.png'),
      );
    });

    testWidgets('renders a single highlight', (tester) async {
      await tester.pumpWidget(
        _buildPainter(
          highlights: const [
            RelativeRectModel(left: 0.1, top: 0.1, right: 0.9, bottom: 0.2),
          ],
        ),
      );

      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('goldens/highlight_painter_single.png'),
      );
    });

    testWidgets('renders multiple non-overlapping highlights', (tester) async {
      await tester.pumpWidget(
        _buildPainter(
          highlights: const [
            RelativeRectModel(left: 0.1, top: 0.1, right: 0.9, bottom: 0.18),
            RelativeRectModel(left: 0.1, top: 0.3, right: 0.7, bottom: 0.38),
            RelativeRectModel(left: 0.2, top: 0.5, right: 0.8, bottom: 0.58),
          ],
        ),
      );

      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('goldens/highlight_painter_multiple.png'),
      );
    });

    testWidgets('renders overlapping highlights with additive alpha', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildPainter(
          highlights: const [
            RelativeRectModel(left: 0.1, top: 0.1, right: 0.6, bottom: 0.3),
            RelativeRectModel(left: 0.4, top: 0.2, right: 0.9, bottom: 0.4),
          ],
        ),
      );

      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('goldens/highlight_painter_overlapping.png'),
      );
    });

    testWidgets('renders highlight spanning full page width', (tester) async {
      await tester.pumpWidget(
        _buildPainter(
          highlights: const [
            RelativeRectModel(left: 0.0, top: 0.45, right: 1.0, bottom: 0.55),
          ],
        ),
      );

      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('goldens/highlight_painter_full_width.png'),
      );
    });
  });
}
