import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart' show PdfDocument;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:sefer/features/reader/data/auxiliary_document_loader.dart';
import 'package:sefer/features/reader/domain/auxiliary_document_status.dart';
import 'package:sefer/features/reader/state/providers.dart';

class ReaderDocumentController {
  ReaderDocumentController({
    required this.pdfPath,
    required this.isAsset,
    required this.ref,
    required this.auxiliaryLoader,
    required this.onStateChanged,
  });

  final String pdfPath;
  final bool isAsset;
  final WidgetRef ref;
  final AuxiliaryDocumentLoader auxiliaryLoader;
  final VoidCallback onStateChanged;

  sf_pdf.PdfDocument? sfDocument;
  AuxiliaryDocumentStatus auxiliaryStatus = AuxiliaryDocumentStatus.loading;
  bool _disposed = false;
  bool _auxiliaryLoadInFlight = false;

  Future<void> onViewerReady(PdfDocument doc, AssetBundle bundle) async {
    await ref
        .read(readerNotifierProvider.notifier)
        .onDocumentLoaded(pdfId: pdfPath, totalPages: doc.pages.length);
    if (_disposed) return;

    _loadAnnotationsAround(ref.read(readerNotifierProvider).currentPage);
    unawaited(loadAuxiliaryDocument(bundle));
  }

  void onPageChanged(int page) {
    if (_disposed) return;
    ref.read(readerNotifierProvider.notifier).onPageChanged(page);
    _loadAnnotationsAround(ref.read(readerNotifierProvider).currentPage);
  }

  void dispose() {
    _disposed = true;
    sfDocument?.dispose();
  }

  void releaseAuxiliaryDocument() {
    sfDocument?.dispose();
    sfDocument = null;
    auxiliaryStatus = AuxiliaryDocumentStatus.loading;
  }

  void _loadAnnotationsAround(int page) {
    final window = ref
        .read(appSettingsProvider)
        .layoutMode
        .annotationPreloadWindow;
    unawaited(
      ref
          .read(annotationNotifierProvider.notifier)
          .loadForPage(pdfPath, page, window: window),
    );
  }

  Future<void> loadAuxiliaryDocument(AssetBundle bundle) async {
    if (_auxiliaryLoadInFlight || sfDocument != null) return;
    _auxiliaryLoadInFlight = true;
    auxiliaryStatus = AuxiliaryDocumentStatus.loading;
    try {
      final document = await auxiliaryLoader.load(
        path: pdfPath,
        isAsset: isAsset,
        bundle: bundle,
      );
      if (_disposed) {
        document.dispose();
        return;
      }
      sfDocument = document;
      auxiliaryStatus = AuxiliaryDocumentStatus.ready;
    } catch (error, stack) {
      developer.log(
        'Loading auxiliary document failed for $pdfPath; '
        'contents and text tools are unavailable',
        name: 'sefer.reader',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
      auxiliaryStatus = AuxiliaryDocumentStatus.failed;
    } finally {
      _auxiliaryLoadInFlight = false;
    }
    if (!_disposed) onStateChanged();
  }
}
