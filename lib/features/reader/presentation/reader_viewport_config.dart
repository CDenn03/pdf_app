import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart' show PdfDocument;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/domain/active_page_navigation.dart';
import 'package:sefer/features/reader/domain/active_search_backend.dart';
import 'package:sefer/features/reader/domain/external_link_opener.dart';
import 'package:sefer/features/reader/domain/reader_search_highlights.dart';
import 'package:sefer/features/reader/domain/selected_text_sharer.dart';
import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';

class ReaderViewportConfig {
  const ReaderViewportConfig({
    required this.pdfPath,
    required this.isAsset,
    required this.readingMode,
    required this.annotating,
    required this.activeTool,
    required this.sfDocument,
    required this.initialPage,
    required this.highlights,
    required this.navigation,
    required this.searchBackend,
    required this.linkOpener,
    required this.textSharer,
    required this.onViewerReady,
    required this.onPageChanged,
    required this.onGeneralTap,
    required this.onAddBookmark,
  });

  final String pdfPath;
  final bool isAsset;
  final ReadingMode readingMode;
  final bool annotating;
  final AnnotationTool activeTool;
  final sf_pdf.PdfDocument? sfDocument;
  final int initialPage;
  final ReaderSearchHighlights highlights;
  final ActivePageNavigation navigation;
  final ActiveSearchBackend searchBackend;
  final ExternalLinkOpener linkOpener;
  final SelectedTextSharer textSharer;
  final Future<void> Function(PdfDocument) onViewerReady;
  final void Function(int?) onPageChanged;
  final VoidCallback onGeneralTap;
  final Future<void> Function() onAddBookmark;
}
