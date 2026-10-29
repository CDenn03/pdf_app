import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/core/theme/scroll_direction.dart';
import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import 'package:sefer/features/reader/presentation/reader_overlays.dart';
import 'package:sefer/features/reader/presentation/reader_search_controller.dart';

/// Builds the pdfrx [PdfViewer] with the reader's params.
///
/// Settings are passed in (rather than read with ref) so a change to scroll
/// direction or reading mode rebuilds the viewer (#8).
class ReaderViewport extends StatelessWidget {
  const ReaderViewport({
    super.key,
    required this.pdfPath,
    required this.isAsset,
    required this.controller,
    required this.settings,
    required this.annotating,
    required this.activeTool,
    required this.sfDocument,
    required this.resumePage,
    required this.search,
    required this.onViewerReady,
    required this.onPageChanged,
    required this.onGeneralTap,
    required this.onAddBookmark,
  });

  final String pdfPath;
  final bool isAsset;
  final PdfViewerController controller;
  final AppSettings settings;
  final bool annotating;
  final AnnotationTool activeTool;
  final sf_pdf.PdfDocument? sfDocument;
  final int resumePage;
  final ReaderSearchController? search;

  final Future<void> Function(PdfDocument, PdfViewerController) onViewerReady;
  final void Function(int?) onPageChanged;
  final VoidCallback onGeneralTap;
  final Future<void> Function() onAddBookmark;

  bool get _isPaginated =>
      settings.scrollDirection == ScrollDirection.sideBySide ||
      settings.scrollDirection == ScrollDirection.bookFlip;

  @override
  Widget build(BuildContext context) {
    final readingMode = settings.readingMode;

    final params = PdfViewerParams(
      layoutPages: _isPaginated ? _horizontalPageLayout : null,
      margin: 8,
      calculateInitialPageNumber: (document, _) =>
          resumePage.clamp(1, document.pages.length),
      onViewerReady: (doc, ctrl) {
        onViewerReady(doc, ctrl).catchError((Object e, StackTrace s) {
          developer.log(
            'onViewerReady failed',
            name: 'sefer.reader',
            level: 1000,
            error: e,
            stackTrace: s,
          );
        });
      },
      onPageChanged: onPageChanged,
      linkHandlerParams: PdfLinkHandlerParams(
        onLinkTap: (link) {
          final dest = link.dest;
          if (dest != null) {
            controller.goToPage(pageNumber: dest.pageNumber);
          }
        },
      ),
      onGeneralTap: (context, controller, details) {
        onGeneralTap();
        return false;
      },
      textSelectionParams: PdfTextSelectionParams(enabled: !annotating),
      // Pre-compensate highlight colors for the reading mode's color filter
      // so search matches remain visible in dark and sepia modes.
      matchTextColor: readingMode.searchMatchColor,
      activeMatchTextColor: readingMode.searchActiveMatchColor,
      // pdfrx draws search matches ONLY from this callback — without it the
      // match colours above are never applied.
      pagePaintCallbacks: readerPagePaintCallbacks(search),
      pageOverlaysBuilder: (context, pageRectInViewer, page) {
        return [
          ReaderPageOverlay(
            pageRectInViewer: pageRectInViewer,
            page: page,
            annotating: annotating,
            pdfId: pdfPath,
            activeTool: activeTool,
            sfDocument: sfDocument,
            onAddBookmark: onAddBookmark,
          ),
        ];
      },
    );

    if (isAsset) {
      return PdfViewer.asset(pdfPath, controller: controller, params: params);
    }
    return PdfViewer.file(pdfPath, controller: controller, params: params);
  }

  static PdfPageLayout _horizontalPageLayout(
    List<PdfPage> pages,
    PdfViewerParams params,
  ) {
    final margin = params.margin;
    final maxH =
        pages.fold(0.0, (h, p) => h > p.height ? h : p.height) + margin * 2;
    final rects = <Rect>[];
    var x = margin;
    for (final page in pages) {
      rects.add(
        Rect.fromLTWH(x, (maxH - page.height) / 2, page.width, page.height),
      );
      x += page.width + margin;
    }
    return PdfPageLayout(pageLayouts: rects, documentSize: Size(x, maxH));
  }
}
