import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/models/relative_rect_model.dart';
import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import 'package:sefer/features/reader/presentation/reader_overlays.dart';
import 'package:sefer/features/reader/presentation/reader_page_geometry.dart';
import 'package:sefer/features/reader/presentation/reader_page_surface.dart';
import 'package:sefer/features/reader/state/providers.dart';
import '../support/fake_annotation_daos.dart';
import '../support/paged_reader_harness.dart';

const _cell = Size(400, 400);
const _rasterKey = Key('raster');
const _searchKey = Key('search');

Annotation _noteAtRightEdge() => const Annotation(
  id: 'note',
  pdfId: 'doc',
  page: 1,
  type: AnnotationType.note,
  rects: [RelativeRectModel(left: 1, top: 0.5, right: 1, bottom: 0.5)],
);

void main() {
  Future<void> pumpSurface(WidgetTester tester, Size pageSize) async {
    final container = ProviderContainer(
      overrides: [
        annotationDaoProvider.overrideWithValue(
          FakeAnnotationDao(stored: [_noteAtRightEdge()]),
        ),
        noteEntryDaoProvider.overrideWithValue(FakeNoteEntryDao()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(annotationNotifierProvider, (_, _) {});
    await container
        .read(annotationNotifierProvider.notifier)
        .loadForPage('doc', 1);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Center(
            child: SizedBox.fromSize(
              size: _cell,
              child: ReaderPageSurface(
                pageNumber: 1,
                pageSize: pageSize,
                raster: const ColoredBox(key: _rasterKey, color: Colors.white),
                searchLayer: (context, geometry) =>
                    const ColoredBox(key: _searchKey, color: Colors.yellow),
                annotationLayer: (context, geometry) => ReaderPageOverlay(
                  geometry: geometry,
                  annotating: false,
                  pdfId: 'doc',
                  activeTool: AnnotationTool.highlight,
                  sfDocument: null,
                  onAddBookmark: () async {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('geometry', () {
    test('fits a portrait page inside a square cell', () {
      final geometry = ReaderPageGeometry.fitted(
        pageNumber: 1,
        pageSize: portraitPage,
        available: _cell,
      );

      expect(geometry.renderedRect.height, _cell.height);
      expect(geometry.renderedRect.width, lessThan(_cell.width));
      expect(geometry.renderedRect.center, _cell.center(Offset.zero));
    });

    test('fits a landscape page inside a square cell', () {
      final geometry = ReaderPageGeometry.fitted(
        pageNumber: 1,
        pageSize: landscapePage,
        available: _cell,
      );

      expect(geometry.renderedRect.width, _cell.width);
      expect(geometry.renderedRect.height, lessThan(_cell.height));
      expect(geometry.renderedRect.center, _cell.center(Offset.zero));
    });

    test('keeps the page aspect ratio', () {
      final geometry = ReaderPageGeometry.fitted(
        pageNumber: 1,
        pageSize: portraitPage,
        available: _cell,
      );

      expect(
        geometry.renderedRect.width / geometry.renderedRect.height,
        closeTo(portraitPage.width / portraitPage.height, 1e-9),
      );
    });
  });

  for (final (label, pageSize) in [
    ('portrait', portraitPage),
    ('landscape', landscapePage),
  ]) {
    group('$label page surface', () {
      testWidgets('the annotation layer covers exactly the raster', (
        tester,
      ) async {
        await pumpSurface(tester, pageSize);

        expect(
          tester.getRect(find.byType(ReaderPageOverlay)),
          tester.getRect(find.byKey(_rasterKey)),
        );
      });

      testWidgets('the search layer covers exactly the raster', (tester) async {
        await pumpSurface(tester, pageSize);

        expect(
          tester.getRect(find.byKey(_searchKey)),
          tester.getRect(find.byKey(_rasterKey)),
        );
      });

      testWidgets('a right-edge note target sits on the raster edge', (
        tester,
      ) async {
        await pumpSurface(tester, pageSize);

        final target = tester.getRect(
          find.descendant(
            of: find.byType(NoteTapTarget),
            matching: find.byType(SizedBox),
          ),
        );
        final raster = tester.getRect(find.byKey(_rasterKey));
        expect(target.right, raster.right);
        expect(target.center.dy, closeTo(raster.center.dy, 0.01));
      });
    });
  }

  testWidgets('shows nothing for a page without a size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPageSurface(
          pageNumber: 1,
          pageSize: Size.zero,
          raster: const ColoredBox(key: _rasterKey, color: Colors.white),
          annotationLayer: (_, _) => const SizedBox(),
        ),
      ),
    );

    expect(find.byKey(_rasterKey), findsNothing);
  });
}
