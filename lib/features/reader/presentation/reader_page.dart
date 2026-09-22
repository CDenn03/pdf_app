import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:sefer/core/constants.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/utils/share_utils.dart';
import 'package:sefer/core/models/annotation.dart' as app;
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/core/theme/scroll_direction.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/features/reader/presentation/annotation_panel.dart';
import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import 'package:sefer/features/reader/presentation/more_panel.dart';
import 'package:sefer/features/reader/presentation/reader_annotation_controller.dart';
import 'package:sefer/features/reader/presentation/reader_bar_controller.dart';
import 'package:sefer/features/reader/presentation/reader_chrome.dart';
import 'package:sefer/features/reader/presentation/reader_dialogs.dart';
import 'package:sefer/features/reader/presentation/reader_document_controller.dart';
import 'package:sefer/features/reader/presentation/reader_overlays.dart';
import 'package:sefer/features/reader/presentation/search_panel.dart';
import 'package:sefer/features/reader/presentation/toc_panel.dart';
import 'package:sefer/features/reader/state/providers.dart';

/// The immersive PDF reader page.
///
/// Uses [PdfViewer] from pdfrx, which renders each page as a Flutter widget.
/// Annotation overlays placed via [PdfViewerParams.pageOverlaysBuilder] are
/// children of each page widget and scroll with the content — fixing the
/// highlight drift problem that existed with PlatformView-based viewers.
class ReaderPage extends ConsumerStatefulWidget {
  final String pdfPath;

  const ReaderPage({super.key, this.pdfPath = kSamplePdfPath});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late final PdfViewerController _pdfController;
  late final ReaderDocumentController _docCtrl;
  late final ReaderBarController _barCtrl;
  late final ReaderAnnotationController _annotCtrl;

  // Bookmark state for current page.
  bool _currentPageBookmarked = false;

  /// False until [onViewerReady] fires — shows a loading overlay.
  bool _documentReady = false;

  bool get _isAsset =>
      !widget.pdfPath.startsWith('/') && !widget.pdfPath.contains('://');

  // Convenience getters delegating to controllers.
  int get _currentPage => _docCtrl.currentPage;
  int get _totalPages => _docCtrl.totalPages;
  sf_pdf.PdfDocument? get _sfDocument => _docCtrl.sfDocument;
  bool get _barsVisible => _barCtrl.barsVisible;
  bool get _annotating => _annotCtrl.annotating;
  AnnotationTool get _activeTool => _annotCtrl.activeTool;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();

    _barCtrl = ReaderBarController(onStateChanged: () => setState(() {}));
    _annotCtrl = ReaderAnnotationController(
      onEnter: _barCtrl.hide,
      onExit: () => _barCtrl.show(annotating: false),
      onStateChanged: () => setState(() {}),
    );
    _docCtrl = ReaderDocumentController(
      pdfPath: widget.pdfPath,
      isAsset: _isAsset,
      ref: ref,
      pdfController: _pdfController,
      onStateChanged: () {
        if (mounted) setState(() => _updateBookmarkState());
      },
    );

    _barCtrl.scheduleAutoHide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryEntriesProvider.notifier).recordOpened(widget.pdfPath);
      ref.read(recentsProvider.notifier).recordOpened(widget.pdfPath);
    });
  }

  @override
  void dispose() {
    _docCtrl.dispose(); // disposes _sfDocument (#10)
    _barCtrl.dispose();
    super.dispose();
  }

  // Document lifecycle — delegate to ReaderDocumentController (#24)

  Future<void> _onViewerReady(
    PdfDocument doc,
    PdfViewerController controller,
  ) async {
    await _docCtrl.onViewerReady(doc, context);
    if (mounted) setState(() => _documentReady = true);
  }

  void _onPageChanged(int? page) {
    if (page == null) return;
    _docCtrl.onPageChanged(page);
  }

  // Bar visibility — delegate to ReaderBarController (#24)

  void _toggleBars() => _barCtrl.toggle(annotating: _annotating);
  void _showBars() => _barCtrl.show(annotating: _annotating);
  void _hideBars() => _barCtrl.hide();
  void _scheduleAutoHide() => _barCtrl.scheduleAutoHide();

  // Annotation mode — delegate to ReaderAnnotationController (#24)

  void _enterAnnotationMode() => _annotCtrl.enter();
  void _exitAnnotationMode() => _annotCtrl.exit();

  Future<void> _performUndo() async {
    final message = await ref.read(annotationNotifierProvider.notifier).undo();
    if (message != null && mounted) {
      _showToast(message);
    }
  }

  void _showToast(String message) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 60 + 12 + bottomInset + 8,
        ),
      ),
    );
  }

  void _updateBookmarkState() {
    final annotations = ref
        .read(annotationNotifierProvider.notifier)
        .annotationsForPage(_currentPage);
    _currentPageBookmarked = annotations.any(
      (a) => a.type == AnnotationType.bookmark,
    );
  }

  void _toggleBookmark() {
    _scheduleAutoHide();
    if (_currentPageBookmarked) {
      final annotations = ref
          .read(annotationNotifierProvider.notifier)
          .annotationsForPage(_currentPage);
      final bookmark = annotations.firstWhere(
        (a) => a.type == AnnotationType.bookmark,
        orElse: () => const app.Annotation(
          id: '',
          pdfId: '',
          page: 0,
          type: AnnotationType.bookmark,
        ),
      );
      if (bookmark.id.isNotEmpty) {
        ref
            .read(annotationNotifierProvider.notifier)
            .removeAnnotation(bookmark.id);
      }
      setState(() => _currentPageBookmarked = false);
    } else {
      _addBookmarkWithLabel();
    }
  }

  Future<void> _addBookmarkWithLabel() async {
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => BookmarkLabelDialog(defaultLabel: 'Page $_currentPage'),
    );
    if (label == null) return;
    final color = ref.read(activeAnnotationColorProvider);
    ref
        .read(annotationNotifierProvider.notifier)
        .addBookmark(
          page: _currentPage,
          pdfId: widget.pdfPath,
          label: label.trim().isEmpty ? null : label.trim(),
          color: color,
        );
    setState(() => _currentPageBookmarked = true);
  }

  void _navigateBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  Future<void> _showJumpToPageDialog() async {
    _barCtrl.hide();
    final controller = TextEditingController(text: '$_currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (context) =>
          JumpToPageDialog(controller: controller, totalPages: _totalPages),
    );
    if (page != null) await _pdfController.goToPage(pageNumber: page);
    if (mounted) _scheduleAutoHide();
  }

  void _openSearch() {
    _hideBars();
    showSearchPanel(
      context: context,
      pdfController: _pdfController,
    ).then((_) => _showBars());
  }

  void _openToc() {
    _hideBars();
    showTocPanel(
      context: context,
      pdfController: _pdfController,
      document: _sfDocument,
      pdfId: widget.pdfPath,
    ).then((_) => _showBars());
  }

  void _openAnnotations() {
    _hideBars();
    showAnnotationPanel(
      context: context,
      pdfId: widget.pdfPath,
      onNavigate: (page) => _pdfController.goToPage(pageNumber: page),
    ).then((_) => _showBars());
  }

  void _openMore() {
    _hideBars();
    final settings = ref.read(appSettingsProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ReaderMoreMenu(
        onAnnotations: () {
          Navigator.of(ctx).pop();
          _openAnnotations();
        },
        onReadingMode: () {
          Navigator.of(ctx).pop();
          showMorePanel(
            context: context,
            currentMode: settings.readingMode,
            onModeChanged: (mode) =>
                ref.read(appSettingsProvider.notifier).setReadingMode(mode),
            currentScrollDirection: settings.scrollDirection,
            onScrollDirectionChanged: (dir) =>
                ref.read(appSettingsProvider.notifier).setScrollDirection(dir),
          ).then((_) => _showBars());
        },
        onShare: () {
          Navigator.of(ctx).pop();
          sharePdf(context, widget.pdfPath);
        },
      ),
    ).then((_) {
      if (mounted && !_annotating) _showBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(annotationNotifierProvider);
    final settings = ref.watch(appSettingsProvider);
    final readingMode = settings.readingMode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navigateBack();
      },
      child: Scaffold(
        backgroundColor: readingMode.background,
        appBar: _barsVisible && !_annotating
            ? ReaderAppBar(
                title: _documentTitle,
                isBookmarked: _currentPageBookmarked,
                onBack: _navigateBack,
                onBookmark: _toggleBookmark,
                readingMode: readingMode,
              )
            : null,
        body: _buildBody(settings, readingMode),
      ),
    );
  }

  Widget _buildBody(AppSettings settings, ReadingMode readingMode) {
    const barHeight = 60.0;
    const barMargin = 12.0;
    final barVisible = _barsVisible && !_annotating;
    // Keep the indicator above the floating bar with a comfortable gap.
    final indicatorBottom = barVisible
        ? barHeight + barMargin + MediaQuery.of(context).padding.bottom + 12
        : 16.0;

    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: ReadingModeFilter(mode: readingMode, child: _buildViewer(settings)),
        ),

        if (!_documentReady) const DocumentLoadingOverlay(),

        Positioned(
          bottom: indicatorBottom,
          left: 0,
          right: 0,
          child: Center(
            child: PageIndicator(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onTap: _showJumpToPageDialog,
            ),
          ),
        ),

        // Floating annotation toolbar (replaces pill bar while annotating).
        if (_annotating)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
            child: AnnotationToolbar(
              activeTool: _activeTool,
              onToolChanged: (tool) {
                if (tool == AnnotationTool.bookmark) {
                  _addBookmarkWithLabel();
                } else {
                  _annotCtrl.setTool(tool);
                }
              },
              onExit: _exitAnnotationMode,
              onUndo: _performUndo,
              readingMode: readingMode,
            ),
          ),

        // Floating pill action bar.
        if (barVisible)
          Positioned(
            left: 16,
            right: 16,
            bottom: barMargin + MediaQuery.of(context).padding.bottom,
            child: BottomActionBar(
              onSearch: _openSearch,
              onAnnotate: _enterAnnotationMode,
              onToc: _openToc,
              onMore: _openMore,
              readingMode: readingMode,
            ),
          ),

        // Long-press-activated scrollbar on the right edge.
        if (_totalPages > 1)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SideScrollThumb(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageRequested: (page) =>
                  _pdfController.goToPage(pageNumber: page),
            ),
          ),
      ],
    );
  }

  // Settings are passed in from build() (which uses ref.watch) so changes to
  // scroll direction or reading mode trigger a viewer rebuild (#8).
  Widget _buildViewer(AppSettings settings) {
    final bool isPaginated =
        settings.scrollDirection == ScrollDirection.sideBySide ||
        settings.scrollDirection == ScrollDirection.bookFlip;
    final readingMode = settings.readingMode;

    final params = PdfViewerParams(
      layoutPages: isPaginated ? _horizontalPageLayout : null,
      margin: 8,
      // Wrap the async callback so errors are logged rather than swallowed
      // (async void fire-and-forget would discard exceptions silently) (#3).
      onViewerReady: (doc, ctrl) {
        _onViewerReady(doc, ctrl).catchError((Object e, StackTrace s) {
          developer.log(
            'onViewerReady failed',
            name: 'sefer.reader',
            level: 1000,
            error: e,
            stackTrace: s,
          );
        });
      },
      onPageChanged: _onPageChanged,
      linkHandlerParams: PdfLinkHandlerParams(
        onLinkTap: (link) {
          if (link.dest != null) {
            _pdfController.goToPage(pageNumber: link.dest!.pageNumber);
          } else if (link.url != null) {
            // External URLs are ignored — only internal navigation is handled.
          }
        },
      ),
      onGeneralTap: (context, controller, details) {
        _toggleBars();
        return false;
      },
      textSelectionParams: PdfTextSelectionParams(enabled: !_annotating),
      // Pre-compensate highlight colors for the reading mode's color filter
      // so search matches remain visible in dark and sepia modes.
      matchTextColor: readingMode.searchMatchColor,
      activeMatchTextColor: readingMode.searchActiveMatchColor,
      pageOverlaysBuilder: (context, pageRectInViewer, page) {
        return [
          ReaderPageOverlay(
            pageRectInViewer: pageRectInViewer,
            page: page,
            annotating: _annotating,
            pdfId: widget.pdfPath,
            activeTool: _activeTool,
            sfDocument: _sfDocument,
            onAddBookmark: _addBookmarkWithLabel,
          ),
        ];
      },
    );

    if (_isAsset) {
      return PdfViewer.asset(
        widget.pdfPath,
        controller: _pdfController,
        params: params,
      );
    }
    return PdfViewer.file(
      widget.pdfPath,
      controller: _pdfController,
      params: params,
    );
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

  String get _documentTitle {
    final path = widget.pdfPath;
    final name = path.split('/').last;
    return name.endsWith('.pdf') ? name.substring(0, name.length - 4) : name;
  }
}
