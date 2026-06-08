import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:pdf_app/core/theme/scroll_direction.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

/// Owns the document load lifecycle: resume-page navigation, page tracking,
/// and Syncfusion document construction (#24).
///
/// Callers must call [dispose] when the page is removed from the tree.
class ReaderDocumentController {
  ReaderDocumentController({
    required this.pdfPath,
    required this.isAsset,
    required this.ref,
    required this.pdfController,
    required this.onStateChanged,
  });

  final String pdfPath;
  final bool isAsset;
  final WidgetRef ref;
  final PdfViewerController pdfController;

  /// Called whenever [currentPage], [totalPages], or [sfDocument] changes.
  final VoidCallback onStateChanged;

  int currentPage = 1;
  int totalPages = 1;
  sf_pdf.PdfDocument? sfDocument;

  Future<void> onViewerReady(PdfDocument doc, BuildContext context) async {
    final bundle = DefaultAssetBundle.of(context);
    totalPages = doc.pages.length;
    onStateChanged();

    await ref
        .read(readerNotifierProvider.notifier)
        .onDocumentLoaded(pdfId: pdfPath, totalPages: totalPages);

    final resumePage = ref.read(readerNotifierProvider).resumePage;
    if (resumePage > 1) {
      await pdfController.goToPage(pageNumber: resumePage);
    }

    final window =
        ref.read(appSettingsProvider).scrollDirection ==
            ScrollDirection.continuous
        ? 3
        : 1;
    unawaited(
      ref
          .read(annotationNotifierProvider.notifier)
          .loadForPage(pdfPath, currentPage, window: window),
    );

    unawaited(_loadSfDocument(bundle));
  }

  Future<void> _loadSfDocument(AssetBundle bundle) async {
    try {
      final Uint8List bytes;
      if (isAsset) {
        final data = await bundle.load(pdfPath);
        bytes = data.buffer.asUint8List();
      } else {
        bytes = await File(pdfPath).readAsBytes();
      }
      final doc = await compute(
        (Uint8List b) => sf_pdf.PdfDocument(inputBytes: b),
        bytes,
      );
      sfDocument = doc;
      onStateChanged();
    } catch (_) {
      // TOC / text extraction is best-effort — failure is non-fatal.
    }
  }

  void onPageChanged(int page) {
    currentPage = page;
    onStateChanged();

    ref.read(readerNotifierProvider.notifier).onPageChanged(page);

    final window =
        ref.read(appSettingsProvider).scrollDirection ==
            ScrollDirection.continuous
        ? 3
        : 1;
    unawaited(
      ref
          .read(annotationNotifierProvider.notifier)
          .loadForPage(pdfPath, page, window: window),
    );
  }

  void dispose() {
    sfDocument?.dispose();
  }
}
