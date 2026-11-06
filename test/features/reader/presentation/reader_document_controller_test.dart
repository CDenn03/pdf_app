import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/core/theme/reader_layout_mode.dart';
import 'package:sefer/features/reader/data/auxiliary_document_loader.dart';
import 'package:sefer/features/reader/domain/auxiliary_document_status.dart';
import 'package:sefer/features/reader/presentation/reader_document_controller.dart';
import 'package:sefer/features/reader/state/providers.dart';
import '../support/fake_annotation_daos.dart';

class _FakeProgressStore implements ReadingProgressStore {
  @override
  Future<int> getLastPage(String pdfId) async => 1;

  @override
  Future<void> saveLastPage(String pdfId, int page) async {}

  @override
  Future<void> movePage(String oldPdfId, String newPdfId) async {}

  @override
  Future<void> clear(String pdfId) async {}
}

class _FixedModeStore implements AppSettingsStore {
  _FixedModeStore(this.layoutMode);

  final ReaderLayoutMode layoutMode;

  @override
  Future<AppSettings> load() async => AppSettings(layoutMode: layoutMode);

  @override
  Future<void> save(AppSettings settings) async {}
}

class _FakeAuxiliaryLoader implements AuxiliaryDocumentLoader {
  _FakeAuxiliaryLoader({this.failure});

  final Object? failure;
  int loadCount = 0;

  @override
  Future<sf_pdf.PdfDocument> load({
    required String path,
    required bool isAsset,
    required AssetBundle bundle,
  }) async {
    loadCount++;
    final error = failure;
    if (error != null) throw error;
    return sf_pdf.PdfDocument();
  }
}

Annotation _bookmarkOn(int page) => Annotation(
  id: 'bookmark-$page',
  pdfId: 'doc.pdf',
  page: page,
  type: AnnotationType.bookmark,
);

void main() {
  late FakeAnnotationDao dao;
  late ReaderDocumentController controller;
  late _FakeAuxiliaryLoader loader;
  var stateChanges = 0;
  late ProviderContainer container;

  Future<void> pumpController(
    WidgetTester tester, {
    required ReaderLayoutMode layoutMode,
    _FakeAuxiliaryLoader? auxiliaryLoader,
  }) async {
    loader = auxiliaryLoader ?? _FakeAuxiliaryLoader();
    stateChanges = 0;
    dao = FakeAnnotationDao(
      stored: [for (var p = 1; p <= 20; p++) _bookmarkOn(p)],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          annotationDaoProvider.overrideWithValue(dao),
          noteEntryDaoProvider.overrideWithValue(FakeNoteEntryDao()),
          readingProgressProvider.overrideWithValue(_FakeProgressStore()),
          appSettingsServiceProvider.overrideWithValue(
            _FixedModeStore(layoutMode),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            controller = ReaderDocumentController(
              pdfPath: 'doc.pdf',
              isAsset: false,
              ref: ref,
              auxiliaryLoader: loader,
              onStateChanged: () => stateChanges++,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    container.listen(readerNotifierProvider, (_, _) {});
    container.listen(annotationNotifierProvider, (_, _) {});
    await container.read(appSettingsProvider.notifier).ready;
    await container
        .read(readerNotifierProvider.notifier)
        .onDocumentLoaded(pdfId: 'doc.pdf', totalPages: 20);
  }

  testWidgets('a settled page change is stored in reader state only', (
    tester,
  ) async {
    await pumpController(tester, layoutMode: ReaderLayoutMode.paged);

    controller.onPageChanged(9);

    expect(container.read(readerNotifierProvider).currentPage, 9);
  });

  testWidgets('paged mode preloads annotations one page either side', (
    tester,
  ) async {
    await pumpController(tester, layoutMode: ReaderLayoutMode.paged);

    controller.onPageChanged(9);

    expect(dao.requestedRanges.last, (8, 10));
  });

  testWidgets('continuous mode preloads a three page window', (tester) async {
    await pumpController(tester, layoutMode: ReaderLayoutMode.continuous);

    controller.onPageChanged(9);

    expect(dao.requestedRanges.last, (6, 12));
  });

  testWidgets('page reports after dispose are ignored', (tester) async {
    await pumpController(tester, layoutMode: ReaderLayoutMode.paged);

    controller.dispose();
    controller.onPageChanged(9);

    expect(container.read(readerNotifierProvider).currentPage, 1);
  });

  group('auxiliary document', () {
    testWidgets('starts out loading', (tester) async {
      await pumpController(tester, layoutMode: ReaderLayoutMode.paged);

      expect(controller.auxiliaryStatus, AuxiliaryDocumentStatus.loading);
      expect(controller.sfDocument, isNull);
    });

    testWidgets('a successful load makes the document available', (
      tester,
    ) async {
      await pumpController(tester, layoutMode: ReaderLayoutMode.paged);

      await controller.loadAuxiliaryDocument(rootBundle);

      expect(controller.auxiliaryStatus, AuxiliaryDocumentStatus.ready);
      expect(controller.sfDocument, isNotNull);
      expect(stateChanges, 1);
    });

    testWidgets('a failed load is recorded as failed and reported', (
      tester,
    ) async {
      await pumpController(
        tester,
        layoutMode: ReaderLayoutMode.paged,
        auxiliaryLoader: _FakeAuxiliaryLoader(failure: StateError('corrupt')),
      );

      await controller.loadAuxiliaryDocument(rootBundle);

      expect(controller.auxiliaryStatus, AuxiliaryDocumentStatus.failed);
      expect(controller.sfDocument, isNull);
      expect(stateChanges, 1);
    });

    testWidgets('an already loaded document is not loaded again', (
      tester,
    ) async {
      await pumpController(tester, layoutMode: ReaderLayoutMode.paged);

      await controller.loadAuxiliaryDocument(rootBundle);
      await controller.loadAuxiliaryDocument(rootBundle);

      expect(loader.loadCount, 1);
    });

    testWidgets('a failed load can be retried', (tester) async {
      await pumpController(
        tester,
        layoutMode: ReaderLayoutMode.paged,
        auxiliaryLoader: _FakeAuxiliaryLoader(failure: StateError('corrupt')),
      );

      await controller.loadAuxiliaryDocument(rootBundle);
      await controller.loadAuxiliaryDocument(rootBundle);

      expect(loader.loadCount, 2);
    });

    testWidgets('a load finishing after dispose is discarded', (tester) async {
      await pumpController(tester, layoutMode: ReaderLayoutMode.paged);

      final loading = controller.loadAuxiliaryDocument(rootBundle);
      controller.dispose();
      await loading;

      expect(controller.sfDocument, isNull);
      expect(stateChanges, 0);
    });
  });
}
