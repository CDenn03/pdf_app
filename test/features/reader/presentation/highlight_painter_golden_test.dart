import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_color.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/models/relative_rect_model.dart';
import 'package:sefer/features/reader/presentation/highlight_painter.dart';

const _painterKey = ValueKey('highlight_painter');

Annotation _highlight(
  RelativeRectModel rect, {
  AnnotationColor color = AnnotationColor.yellow,
}) {
  return Annotation(
    id: 'test',
    pdfId: 'pdf',
    page: 1,
    type: AnnotationType.highlight,
    rects: [rect],
    color: color,
  );
}

Widget _buildPainter({
  required List<Annotation> annotations,
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
          painter: HighlightPainter(
            annotations: annotations,
            pageSize: pageSize,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('HighlightPainter golden tests', () {
    testWidgets('renders nothing when annotations list is empty', (tester) async {
      await tester.pumpWidget(_buildPainter(annotations: const []));
      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('goldens/highlight_painter_empty.png'),
      );
    });

    testWidgets('renders a single highlight', (tester) async {
      await tester.pumpWidget(
        _buildPainter(
          annotations: [
            _highlight(const RelativeRectModel(
              left: 0.1, top: 0.1, right: 0.9, bottom: 0.2,
            )),
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
          annotations: [
            _highlight(const RelativeRectModel(
              left: 0.1, top: 0.1, right: 0.9, bottom: 0.18,
            )),
            _highlight(
              const RelativeRectModel(
                left: 0.1, top: 0.3, right: 0.7, bottom: 0.38,
              ),
              color: AnnotationColor.green,
            ),
            _highlight(
              const RelativeRectModel(
                left: 0.2, top: 0.5, right: 0.8, bottom: 0.58,
              ),
              color: AnnotationColor.blue,
            ),
          ],
        ),
      );
      await expectLater(
        find.byKey(_painterKey),
        matchesGoldenFile('goldens/highlight_painter_multiple.png'),
      );
    });

    testWidgets('renders overlapping highlights', (tester) async {
      await tester.pumpWidget(
        _buildPainter(
          annotations: [
            _highlight(const RelativeRectModel(
              left: 0.1, top: 0.1, right: 0.6, bottom: 0.3,
            )),
            _highlight(
              const RelativeRectModel(
                left: 0.4, top: 0.2, right: 0.9, bottom: 0.4,
              ),
              color: AnnotationColor.pink,
            ),
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
          annotations: [
            _highlight(const RelativeRectModel(
              left: 0.0, top: 0.45, right: 1.0, bottom: 0.55,
            )),
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
