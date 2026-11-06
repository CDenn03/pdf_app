import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:sefer/core/constants.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/library/state/document_actions.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/reader/presentation/reader_more_sheet.dart';
import 'package:sefer/features/reader/presentation/reader_rename_flow.dart';
import 'package:sefer/features/reader/presentation/reader_rename_host.dart';
import 'package:sefer/features/reader/state/open_document_rename_coordinator.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/features/reader/data/auxiliary_document_loader.dart';
import 'package:sefer/features/reader/data/share_plus_text_sharer.dart';
import 'package:sefer/features/reader/data/url_launcher_external_link_opener.dart';
import 'package:sefer/features/reader/domain/active_page_navigation.dart';
import 'package:sefer/features/reader/domain/active_search_backend.dart';
import 'package:sefer/features/reader/domain/external_link_opener.dart';
import 'package:sefer/features/reader/domain/selected_text_sharer.dart';
import 'package:sefer/features/reader/presentation/annotation_panel.dart';
import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import 'package:sefer/features/reader/presentation/reader_annotation_controller.dart';
import 'package:sefer/features/reader/presentation/reader_bar_controller.dart';
import 'package:sefer/features/reader/presentation/reader_chrome.dart';
import 'package:sefer/features/reader/presentation/reader_dialogs.dart';
import 'package:sefer/features/reader/presentation/reader_document_controller.dart';
import 'package:sefer/features/reader/presentation/reader_find_bar.dart';
import 'package:sefer/features/reader/presentation/reader_overlay_style.dart';
import 'package:sefer/features/reader/presentation/reader_page_scrubber.dart';
import 'package:sefer/features/reader/presentation/reader_overlays.dart';
import 'package:sefer/features/reader/presentation/reader_viewport.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_inset.dart';
import 'package:sefer/features/reader/presentation/toc_panel.dart';
import 'package:sefer/features/reader/state/document_search_controller.dart';
import 'package:sefer/features/reader/state/providers.dart';
import 'package:sefer/features/reader/state/reader_state.dart';

/// The immersive PDF reader page.
///
/// Uses [PdfViewer] from pdfrx, which renders each page as a Flutter widget.
/// Annotation overlays placed via [PdfViewerParams.pageOverlaysBuilder] are
/// children of each page widget and scroll with the content — fixing the
/// highlight drift problem that existed with PlatformView-based viewers.
class ReaderPage extends ConsumerStatefulWidget {
  final String pdfPath;
  final int? initialPage;
  final bool recordOpened;

  const ReaderPage({
    super.key,
    this.pdfPath = kSamplePdfPath,
    this.initialPage,
    this.recordOpened = true,
  });

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  static const _searchTypingDelay = Duration(milliseconds: 500);

  final ActivePageNavigation _pageNavigation = ActivePageNavigation();
  final ActiveSearchBackend _searchBackend = ActiveSearchBackend();
  final ExternalLinkOpener _linkOpener = const UrlLauncherExternalLinkOpener(
    launch: launchInExternalApplication,
  );
  final SelectedTextSharer _textSharer = const SharePlusTextSharer();
  late final DocumentSearchController _search;
  late final ReaderDocumentController _documentController;
  late final ReaderBarController _barController;
  late final ReaderAnnotationController _annotationController;
  late final OpenDocumentRenameCoordinator _renameCoordinator;

  bool _findBarVisible = false;
  bool _viewportSuspended = false;

  bool get _resumeResolved => _readerState.pdfId == widget.pdfPath;

  bool get _isAsset =>
      !widget.pdfPath.startsWith('/') && !widget.pdfPath.contains('://');

  ReaderState get _readerState => ref.read(readerNotifierProvider);
  int get _currentPage => _readerState.currentPage;
  int get _totalPages => _readerState.totalPages;
  sf_pdf.PdfDocument? get _sfDocument => _documentController.sfDocument;
  bool get _barsVisible => _barController.barsVisible;
  bool get _annotating => _annotationController.annotating;
  AnnotationTool get _activeTool => _annotationController.activeTool;

  bool get _currentPageBookmarked => ref
      .read(annotationNotifierProvider.notifier)
      .annotationsForPage(_currentPage)
      .any((a) => a.type == AnnotationType.bookmark);

  @override
  void initState() {
    super.initState();
    _search = DocumentSearchController(
      backend: _searchBackend,
      navigation: _pageNavigation,
      typingDelay: _searchTypingDelay,
    );

    _barController = ReaderBarController(onStateChanged: () => setState(() {}));
    _annotationController = ReaderAnnotationController(
      onEnter: _barController.hide,
      onExit: () => _barController.show(annotating: false),
      onStateChanged: () => setState(() {}),
    );
    _documentController = ReaderDocumentController(
      pdfPath: widget.pdfPath,
      isAsset: _isAsset,
      ref: ref,
      auxiliaryLoader: const SyncfusionDocumentLoader(),
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    _renameCoordinator = OpenDocumentRenameCoordinator(
      host: ReaderRenameHost(
        readCurrentPage: () => _currentPage,
        readerNotifier: ref.read(readerNotifierProvider.notifier),
        annotationNotifier: ref.read(annotationNotifierProvider.notifier),
        documentController: _documentController,
        onCancelSearch: _cancelSearch,
        onViewportSuspendedChanged: _setViewportSuspended,
      ),
      rename: ref.read(documentActionsProvider).rename,
    )..addListener(() => setState(() {}));

    ref.listenManual(readerNotifierProvider, (_, _) {});

    _barController.scheduleAutoHide();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  void _onFirstFrame() {
    ref
        .read(readerNotifierProvider.notifier)
        .loadResumePage(widget.pdfPath, initialPage: widget.initialPage);
    if (!widget.recordOpened) return;
    ref.read(libraryEntriesProvider.notifier).recordOpened(widget.pdfPath);
    ref.read(recentsProvider.notifier).recordOpened(widget.pdfPath);
  }

  void _cancelSearch() {
    _search.resetTextSearch();
    if (mounted) setState(() => _findBarVisible = false);
  }

  void _setViewportSuspended(bool suspended) {
    if (mounted) setState(() => _viewportSuspended = suspended);
  }

  @override
  void dispose() {
    _renameCoordinator.dispose();
    _search.dispose();
    _documentController.dispose();
    _barController.dispose();
    super.dispose();
  }

  // Document lifecycle — delegate to ReaderDocumentController (#24)

  Future<void> _onViewerReady(PdfDocument doc) async {
    _search.rerunQuery();
    await _documentController.onViewerReady(
      doc,
      DefaultAssetBundle.of(context),
    );
  }

  void _onPageChanged(int? page) {
    if (page == null) return;
    _documentController.onPageChanged(page);
  }

  // Bar visibility — delegate to ReaderBarController (#24)

  void _toggleBars() => _barController.toggle(annotating: _annotating);
  void _showBars() => _barController.show(annotating: _annotating);
  void _hideBars() => _barController.hide();
  void _scheduleAutoHide() => _barController.scheduleAutoHide();

  // Annotation mode — delegate to ReaderAnnotationController (#24)

  void _enterAnnotationMode() => _annotationController.enter();
  void _exitAnnotationMode() => _annotationController.exit();

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

  void _toggleBookmark() {
    _scheduleAutoHide();
    final notifier = ref.read(annotationNotifierProvider.notifier);
    final bookmark = notifier
        .annotationsForPage(_currentPage)
        .where((a) => a.type == AnnotationType.bookmark)
        .firstOrNull;
    if (bookmark == null) {
      _addBookmarkWithLabel();
    } else {
      notifier.removeAnnotation(bookmark.id);
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
  }

  void _navigateBack() {
    if (_renameCoordinator.busy) return;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  Future<void> _showJumpToPageDialog() async {
    _barController.hide();
    final controller = TextEditingController(text: '$_currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (context) =>
          JumpToPageDialog(controller: controller, totalPages: _totalPages),
    );
    if (page != null) await _pageNavigation.goToPage(page);
    if (mounted) _scheduleAutoHide();
  }

  void _openSearch() {
    if (!_readerState.isLoaded) return;
    _hideBars();
    setState(() => _findBarVisible = true);
  }

  void _closeFindBar() {
    _search.resetTextSearch();
    setState(() => _findBarVisible = false);
    _showBars();
  }

  void _openToc() {
    _hideBars();
    showTocPanel(
      context: context,
      onPageSelected: _pageNavigation.goToPage,
      document: _sfDocument,
      documentStatus: _documentController.auxiliaryStatus,
      pdfId: widget.pdfPath,
    ).then((_) => _showBars());
  }

  void _openAnnotations() {
    _hideBars();
    showAnnotationPanel(
      context: context,
      pdfId: widget.pdfPath,
      onPageSelected: _pageNavigation.goToPage,
    ).then((_) => _showBars());
  }

  void _openMore() {
    _hideBars();
    showReaderMoreSheet(
      context,
      ref,
      pdfPath: widget.pdfPath,
      renameCoordinator: _isAsset ? null : _renameCoordinator,
      onAnnotations: _openAnnotations,
      onPanelClosed: _showBars,
    ).then((_) {
      if (mounted && !_annotating) _showBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(annotationNotifierProvider);
    ref.watch(readerNotifierProvider);
    final settings = ref.watch(appSettingsProvider);
    final readingMode = settings.readingMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: readerOverlayStyle(readingMode),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _navigateBack();
        },
        child: Scaffold(
          backgroundColor: readingMode.background,
          extendBodyBehindAppBar: true,
          appBar: _barsVisible && !_annotating
              ? ReaderAppBar(
                  title: _documentTitle,
                  isBookmarked: _currentPageBookmarked,
                  documentPath: widget.pdfPath,
                  onBack: _navigateBack,
                  onBookmark: _toggleBookmark,
                  readingMode: readingMode,
                )
              : null,
          body: _buildBody(settings, readingMode),
        ),
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
    final appBarShown = barVisible;
    final findBarTop = topPadding + (appBarShown ? kToolbarHeight : 0.0);

    return Stack(
      children: [
        ReaderViewportInset(
          topInset: topPadding,
          child: ReadingModeFilter(
            mode: readingMode,
            child: _resumeResolved && !_viewportSuspended
                ? _buildViewer(settings)
                : const SizedBox.expand(),
          ),
        ),

        if (!_readerState.isLoaded || !_resumeResolved)
          const DocumentLoadingOverlay(),

        if (_findBarVisible)
          Positioned(
            top: findBarTop,
            left: 0,
            right: 0,
            child: ReaderFindBar(
              search: _search,
              readingMode: readingMode,
              onClose: _closeFindBar,
            ),
          ),

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
                  _annotationController.setTool(tool);
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

        if (_totalPages > 1)
          Positioned(
            right: MediaQuery.of(context).padding.right,
            top: findBarTop + (_findBarVisible ? 64 : 8),
            bottom: indicatorBottom + 40,
            child: ReaderPageScrubber(
              currentPage: _currentPage,
              totalPages: _totalPages,
              readingMode: readingMode,
              onPageRequested: (page) =>
                  unawaited(_pageNavigation.goToPage(page)),
            ),
          ),

        if (_renameCoordinator.busy) const RenameProgressOverlay(),
      ],
    );
  }

  Widget _buildViewer(AppSettings settings) {
    return ReaderViewport(
      layoutMode: settings.layoutMode,
      config: ReaderViewportConfig(
        pdfPath: widget.pdfPath,
        isAsset: _isAsset,
        readingMode: settings.readingMode,
        annotating: _annotating,
        activeTool: _activeTool,
        sfDocument: _sfDocument,
        initialPage: _currentPage,
        highlights: _search,
        navigation: _pageNavigation,
        searchBackend: _searchBackend,
        linkOpener: _linkOpener,
        textSharer: _textSharer,
        onViewerReady: _onViewerReady,
        onPageChanged: _onPageChanged,
        onGeneralTap: _toggleBars,
        onAddBookmark: _addBookmarkWithLabel,
      ),
    );
  }

  String get _documentTitle {
    final path = widget.pdfPath;
    final name = path.split('/').last;
    return name.endsWith('.pdf') ? name.substring(0, name.length - 4) : name;
  }
}
