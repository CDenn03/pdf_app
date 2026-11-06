import 'package:flutter/widgets.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';
import 'package:sefer/features/reader/presentation/page_link_layer.dart';
import 'package:sefer/features/reader/presentation/page_text_selection_layer.dart';
import 'package:sefer/features/reader/presentation/reader_overlays.dart';
import 'package:sefer/features/reader/presentation/reader_page_geometry.dart';
import 'package:sefer/features/reader/presentation/reader_page_surface.dart';
import 'package:sefer/features/reader/presentation/reader_text_selection_controller.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';
import 'package:sefer/features/reader/presentation/search_match_overlay.dart';

/// One PDF page with its margin and every interaction layer, shared by the
/// reading modes that show a single page at a time.
class ReaderPageCell extends StatelessWidget {
  const ReaderPageCell({
    super.key,
    required this.pageNumber,
    required this.pageSize,
    required this.raster,
    required this.config,
    required this.linkSource,
    required this.textSource,
    required this.selection,
  });

  static const pageMargin = 8.0;

  /// Where the page's raster lands inside a cell laid out in [viewport].
  static Rect rectIn(Size viewport, Size pageSize, int pageNumber) {
    final geometry = ReaderPageGeometry.fitted(
      pageNumber: pageNumber,
      pageSize: pageSize,
      available: (Offset.zero & viewport).deflate(pageMargin).size,
    );
    return geometry.renderedRect.shift(const Offset(pageMargin, pageMargin));
  }

  final int pageNumber;
  final Size pageSize;
  final Widget raster;
  final ReaderViewportConfig config;
  final ReaderPageLinkSource linkSource;
  final ReaderPageTextSource textSource;
  final ReaderTextSelectionController selection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(pageMargin),
      child: ReaderPageSurface(
        pageNumber: pageNumber,
        pageSize: pageSize,
        raster: raster,
        searchLayer: (context, geometry) => SearchMatchOverlay(
          geometry: geometry,
          highlights: config.highlights,
          matchColor: config.readingMode.searchMatchColor,
          activeMatchColor: config.readingMode.searchActiveMatchColor,
        ),
        selectionLayer: (context, geometry) => PageTextSelectionLayer(
          geometry: geometry,
          source: textSource,
          controller: selection,
          enabled: !config.annotating,
          sharer: config.textSharer,
          highlightColor: config.readingMode.selectionColor,
          handleColor: config.readingMode.selectionHandleColor,
        ),
        linkLayer: (context, geometry) => PageLinkLayer(
          geometry: geometry,
          source: linkSource,
          navigation: config.navigation,
          linkOpener: config.linkOpener,
        ),
        annotationLayer: (context, geometry) => ReaderPageOverlay(
          geometry: geometry,
          annotating: config.annotating,
          pdfId: config.pdfPath,
          activeTool: config.activeTool,
          sfDocument: config.sfDocument,
          onAddBookmark: config.onAddBookmark,
        ),
      ),
    );
  }
}
