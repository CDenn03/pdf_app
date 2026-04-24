import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/models/annotation.dart' as app;
import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/features/reader/presentation/gesture_handler.dart';
import 'package:pdf_app/features/reader/presentation/highlight_painter.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

/// The main reader page that renders a PDF with an annotation overlay.
///
/// Layers (bottom to top):
/// - [SfPdfViewer] renders the PDF
/// - [GestureHandler] captures drag/tap/long-press for annotation creation
/// - [HighlightPainter] renders annotation overlays via [IgnorePointer]
class ReaderPage extends ConsumerStatefulWidget {
  final String pdfPath;

  const ReaderPage({super.key, this.pdfPath = kSamplePdfPath});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late final PdfViewerController _pdfController;
  late final String _pdfId;
  Size _pageSize = Size.zero;
  int _currentPage = 1;
  bool _annotating = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _pdfId = widget.pdfPath;
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load PDF: ${details.error}')),
    );
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    final size = details.document.pages[0].size;
    final totalPages = details.document.pages.count;

    setState(() {
      _pageSize = Size(size.width, size.height);
    });

    ref
        .read(readerNotifierProvider.notifier)
        .onDocumentLoaded(pdfId: _pdfId, totalPages: totalPages);

    ref
        .read(annotationNotifierProvider.notifier)
        .loadForPage(_pdfId, _currentPage);
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    final page = details.newPageNumber;
    setState(() => _currentPage = page);
    ref.read(readerNotifierProvider.notifier).onPageChanged(page);
    ref.read(annotationNotifierProvider.notifier).loadForPage(_pdfId, page);
  }

  List<RelativeRectModel> _currentHighlights(List<app.Annotation> annotations) {
    return annotations
        .where((a) => a.page == _currentPage && !a.isDeleted && a.rect != null)
        .map((a) => a.rect!)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final highlights = _currentHighlights(
      ref.watch(annotationNotifierProvider),
    );
    final pageReady = _pageSize != Size.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Navigator'),
        actions: [
          IconButton(
            icon: Icon(_annotating ? Icons.edit_off : Icons.edit),
            tooltip: _annotating ? 'Exit annotation mode' : 'Annotate',
            isSelected: _annotating,
            onPressed: () => setState(() => _annotating = !_annotating),
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.asset(
            widget.pdfPath,
            controller: _pdfController,
            onDocumentLoaded: _onDocumentLoaded,
            onDocumentLoadFailed: _onDocumentLoadFailed,
            onPageChanged: _onPageChanged,
          ),
          if (pageReady)
            Positioned.fill(
              child: GestureHandler(
                pageSize: _pageSize,
                currentPage: _currentPage,
                pdfId: _pdfId,
                annotating: _annotating,
              ),
            ),
          if (pageReady && highlights.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HighlightPainter(
                    highlights: highlights,
                    pageSize: _pageSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
