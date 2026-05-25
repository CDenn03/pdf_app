import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/models/annotation.dart' as app;
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/services/app_settings_service.dart';
import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/core/theme/scroll_direction.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';
import 'package:pdf_app/features/reader/presentation/annotation_panel.dart';
import 'package:pdf_app/features/reader/presentation/annotation_toolbar.dart';
import 'package:pdf_app/features/reader/presentation/gesture_handler.dart';
import 'package:pdf_app/features/reader/presentation/highlight_painter.dart';
import 'package:pdf_app/features/reader/presentation/more_panel.dart';
import 'package:pdf_app/features/reader/presentation/search_panel.dart';
import 'package:pdf_app/features/reader/presentation/toc_panel.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

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

  int _currentPage = 1;
  int _totalPages = 1;
  sf_pdf.PdfDocument? _sfDocument;

  // UI chrome visibility.
  bool _barsVisible = true;
  Timer? _autoHideTimer;

  // Annotation mode.
  bool _annotating = false;
  AnnotationTool _activeTool = AnnotationTool.highlight;

  // Reading mode.
  ReadingMode _readingMode = ReadingMode.light;

  // Scroll direction.
  ScrollDirection _scrollDirection = ScrollDirection.paginated;

  // Bookmark state for current page.
  bool _currentPageBookmarked = false;

  bool get _isAsset =>
      !widget.pdfPath.startsWith('/') && !widget.pdfPath.contains('://');

  bool get _isContinuous => _scrollDirection == ScrollDirection.continuous;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _scheduleAutoHide();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(libraryEntriesProvider.notifier).recordOpened(widget.pdfPath);
      await _loadSettings();
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Settings persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadSettings() async {
    final store = ref.read(appSettingsServiceProvider);
    final settings = await store.load();
    if (mounted) {
      setState(() {
        _readingMode = settings.readingMode;
        _scrollDirection = settings.scrollDirection;
      });
    }
  }

  Future<void> _saveSettings() async {
    final store = ref.read(appSettingsServiceProvider);
    await store.save(
      AppSettings(readingMode: _readingMode, scrollDirection: _scrollDirection),
    );
  }

  // ---------------------------------------------------------------------------
  // Document lifecycle
  // ---------------------------------------------------------------------------

  void _onViewerReady(PdfDocument doc, PdfViewerController controller) async {
    final total = doc.pages.length;
    setState(() => _totalPages = total);

    await ref
        .read(readerNotifierProvider.notifier)
        .onDocumentLoaded(pdfId: widget.pdfPath, totalPages: total);

    final resumePage = ref.read(readerNotifierProvider).resumePage;
    if (resumePage > 1 && mounted) {
      await _pdfController.goToPage(pageNumber: resumePage);
    }

    ref
        .read(annotationNotifierProvider.notifier)
        .loadForPage(widget.pdfPath, _currentPage, window: _isContinuous ? 3 : 1);

    _loadSfDocument();
  }

  Future<void> _loadSfDocument() async {
    try {
      if (_isAsset) {
        final bytes = await DefaultAssetBundle.of(
          // ignore: use_build_context_synchronously
          context,
        ).load(widget.pdfPath);
        if (mounted) {
          setState(() {
            _sfDocument = sf_pdf.PdfDocument(
              inputBytes: bytes.buffer.asUint8List(),
            );
          });
        }
      } else {
        final bytes = await File(widget.pdfPath).readAsBytes();
        if (mounted) {
          setState(() => _sfDocument = sf_pdf.PdfDocument(inputBytes: bytes));
        }
      }
    } catch (_) {
      // TOC/text extraction is best-effort — failure is non-fatal.
    }
  }

  void _onPageChanged(int? page) {
    if (page == null) return;
    setState(() {
      _currentPage = page;
      _updateBookmarkState();
    });
    ref.read(readerNotifierProvider.notifier).onPageChanged(page);
    ref
        .read(annotationNotifierProvider.notifier)
        .loadForPage(widget.pdfPath, page, window: _isContinuous ? 3 : 1);
  }

  // ---------------------------------------------------------------------------
  // Bar visibility
  // ---------------------------------------------------------------------------

  void _toggleBars() {
    if (_annotating) return;
    setState(() => _barsVisible = !_barsVisible);
    if (_barsVisible) {
      _scheduleAutoHide();
    } else {
      _autoHideTimer?.cancel();
    }
  }

  void _showBars() {
    if (_annotating) return;
    setState(() => _barsVisible = true);
    _scheduleAutoHide();
  }

  void _hideBars() {
    _autoHideTimer?.cancel();
    if (mounted) setState(() => _barsVisible = false);
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 4), _hideBars);
  }

  // ---------------------------------------------------------------------------
  // Annotation mode
  // ---------------------------------------------------------------------------

  void _enterAnnotationMode() {
    _hideBars();
    setState(() {
      _annotating = true;
      _activeTool = AnnotationTool.highlight;
    });
  }

  void _exitAnnotationMode() {
    setState(() => _annotating = false);
    _showBars();
  }

  Future<void> _performUndo() async {
    final message = await ref.read(annotationNotifierProvider.notifier).undo();
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Bookmark
  // ---------------------------------------------------------------------------

  void _updateBookmarkState() {
    final annotations = ref.read(annotationNotifierProvider);
    _currentPageBookmarked = annotations.any(
      (a) =>
          a.page == _currentPage &&
          a.type == AnnotationType.bookmark &&
          !a.isDeleted,
    );
  }

  void _toggleBookmark() {
    _scheduleAutoHide();
    if (_currentPageBookmarked) {
      final annotations = ref.read(annotationNotifierProvider);
      final bookmark = annotations.firstWhere(
        (a) =>
            a.page == _currentPage &&
            a.type == AnnotationType.bookmark &&
            !a.isDeleted,
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
      builder: (ctx) =>
          _BookmarkLabelDialog(defaultLabel: 'Page $_currentPage'),
    );
    if (label == null) return;
    ref
        .read(annotationNotifierProvider.notifier)
        .addBookmark(
          page: _currentPage,
          label: label.trim().isEmpty ? null : label.trim(),
        );
    setState(() => _currentPageBookmarked = true);
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _navigateBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  Future<void> _showJumpToPageDialog() async {
    _autoHideTimer?.cancel();
    final controller = TextEditingController(text: '$_currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (context) =>
          _JumpToPageDialog(controller: controller, totalPages: _totalPages),
    );
    if (page != null) await _pdfController.goToPage(pageNumber: page);
    if (mounted) _scheduleAutoHide();
  }

  // ---------------------------------------------------------------------------
  // Panels
  // ---------------------------------------------------------------------------

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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _MoreMenu(
        onAnnotations: () {
          Navigator.of(ctx).pop();
          _openAnnotations();
        },
        onReadingMode: () {
          Navigator.of(ctx).pop();
          showMorePanel(
            context: context,
            currentMode: _readingMode,
            onModeChanged: (mode) {
              setState(() => _readingMode = mode);
              _saveSettings();
            },
            currentScrollDirection: _scrollDirection,
            onScrollDirectionChanged: (dir) {
              setState(() => _scrollDirection = dir);
              _saveSettings();
            },
          ).then((_) => _showBars());
        },
      ),
    ).then((_) {
      if (mounted && !_annotating) _showBars();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(annotationNotifierProvider);

    final Widget? bottomBar;
    if (_annotating) {
      bottomBar = AnnotationToolbar(
        activeTool: _activeTool,
        onToolChanged: (tool) => setState(() => _activeTool = tool),
        onExit: _exitAnnotationMode,
        onUndo: _performUndo,
        readingMode: _readingMode,
      );
    } else if (_barsVisible) {
      bottomBar = _BottomActionBar(
        onSearch: _openSearch,
        onAnnotate: _enterAnnotationMode,
        onToc: _openToc,
        onMore: _openMore,
        readingMode: _readingMode,
      );
    } else {
      bottomBar = null;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navigateBack();
      },
      child: Scaffold(
        backgroundColor: _readingMode.background,
        appBar: _barsVisible && !_annotating
            ? _ReaderAppBar(
                title: _documentTitle,
                isBookmarked: _currentPageBookmarked,
                onBack: _navigateBack,
                onBookmark: _toggleBookmark,
                readingMode: _readingMode,
              )
            : null,
        bottomNavigationBar: bottomBar,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _ReadingModeFilter(mode: _readingMode, child: _buildViewer()),

        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: _PageIndicator(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onTap: _showJumpToPageDialog,
            ),
          ),
        ),

        if (_totalPages > 1)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _SideScrollThumb(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageRequested: (page) =>
                  _pdfController.goToPage(pageNumber: page),
            ),
          ),
      ],
    );
  }

  Widget _buildViewer() {
    final bool isPaginated = _scrollDirection == ScrollDirection.paginated;

    final params = PdfViewerParams(
      layoutPages: isPaginated ? _horizontalPageLayout : null,
      margin: 8,
      onViewerReady: _onViewerReady,
      onPageChanged: _onPageChanged,
      onGeneralTap: (context, controller, details) {
        _toggleBars();
        return false;
      },
      textSelectionParams: PdfTextSelectionParams(enabled: !_annotating),
      pageOverlaysBuilder: (context, pageRectInViewer, page) {
        return [_buildPageOverlay(context, pageRectInViewer, page)];
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

  Widget _buildPageOverlay(
    BuildContext context,
    Rect pageRectInViewer,
    PdfPage page,
  ) {
    final pageSize = pageRectInViewer.size;
    final pageNumber = page.pageNumber;
    final pdfPageSize = Size(page.width, page.height);

    final annotations = ref
        .read(annotationNotifierProvider)
        .where((a) => a.page == pageNumber && !a.isDeleted)
        .toList();

    final notes = annotations
        .where((a) => a.type == AnnotationType.note && a.rect != null)
        .toList();

    return SizedBox(
      width: pageSize.width,
      height: pageSize.height,
      child: Stack(
        children: [
          if (annotations.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HighlightPainter(
                    annotations: annotations,
                    pageSize: pageSize,
                  ),
                ),
              ),
            ),

          for (final note in notes)
            _NoteTapTarget(annotation: note, pageSize: pageSize),

          if (_annotating)
            Positioned.fill(
              child: GestureHandler(
                pageSize: pageSize,
                currentPage: pageNumber,
                pdfId: widget.pdfPath,
                activeTool: _activeTool,
                pdfPageSize: pdfPageSize,
                sfDocument: _sfDocument,
              ),
            ),
        ],
      ),
    );
  }

  String get _documentTitle {
    final path = widget.pdfPath;
    final name = path.split('/').last;
    return name.endsWith('.pdf') ? name.substring(0, name.length - 4) : name;
  }
}

// ---------------------------------------------------------------------------
// Annotation overlay helpers
// ---------------------------------------------------------------------------

/// Tap target for a note annotation, positioned at the badge drawn by
/// [HighlightPainter] — the top-right corner of the highlight rect.
class _NoteTapTarget extends StatelessWidget {
  const _NoteTapTarget({required this.annotation, required this.pageSize});

  final app.Annotation annotation;
  final Size pageSize;

  @override
  Widget build(BuildContext context) {
    final rect = annotation.rect!;
    // Badge is drawn at the top-right corner of the highlight band.
    final left = rect.right * pageSize.width - 16;
    final top = rect.top * pageSize.height - 16;

    return Positioned(
      left: left.clamp(0.0, pageSize.width - 32),
      top: top.clamp(0.0, double.infinity),
      child: GestureDetector(
        onTap: () => _showNoteTooltip(context),
        child: const SizedBox(width: 32, height: 32),
      ),
    );
  }

  void _showNoteTooltip(BuildContext context) {
    final text = annotation.text ?? '';
    if (text.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      builder: (ctx) => _NoteTooltipSheet(
        text: text,
        color: annotation.color,
        selectedText: annotation.selectedText,
      ),
    );
  }
}

class _NoteTooltipSheet extends StatelessWidget {
  const _NoteTooltipSheet({
    required this.text,
    required this.color,
    this.selectedText,
  });

  final String text;
  final AnnotationColor color;
  final String? selectedText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedText != null && selectedText!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: color.overlay,
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    left: BorderSide(color: color.solid, width: 3),
                  ),
                ),
                child: Text(
                  selectedText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: color.solid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reader app bar
// ---------------------------------------------------------------------------

class _ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ReaderAppBar({
    required this.title,
    required this.isBookmarked,
    required this.onBack,
    required this.onBookmark,
    required this.readingMode,
  });

  final String title;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final ReadingMode readingMode;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: readingMode.primaryText,
    );

    return AppBar(
      backgroundColor: readingMode.controlSurface,
      foregroundColor: readingMode.primaryText,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: readingMode.primaryText),
        onPressed: onBack,
        tooltip: 'Back',
      ),
      title: Text(title, overflow: TextOverflow.ellipsis, style: titleStyle),
      actions: [
        IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
            color: readingMode.primaryText,
          ),
          onPressed: onBookmark,
          tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark page',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onSearch,
    required this.onAnnotate,
    required this.onToc,
    required this.onMore,
    required this.readingMode,
  });

  final VoidCallback onSearch;
  final VoidCallback onAnnotate;
  final VoidCallback onToc;
  final VoidCallback onMore;
  final ReadingMode readingMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: readingMode.controlSurface,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ActionButton(
              icon: Icons.search,
              label: 'Search',
              color: readingMode.primaryText,
              onTap: onSearch,
            ),
            _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Annotate',
              color: readingMode.primaryText,
              onTap: onAnnotate,
            ),
            _ActionButton(
              icon: Icons.list_outlined,
              label: 'Contents',
              color: readingMode.primaryText,
              onTap: onToc,
            ),
            _ActionButton(
              icon: Icons.more_horiz,
              label: 'More',
              color: readingMode.primaryText,
              onTap: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reading mode color filter
// ---------------------------------------------------------------------------

class _ReadingModeFilter extends StatelessWidget {
  const _ReadingModeFilter({required this.mode, required this.child});

  final ReadingMode mode;
  final Widget child;

  static const _darkMatrix = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]);

  static const _sepiaMatrix = ColorFilter.matrix(<double>[
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) => switch (mode) {
    ReadingMode.light => child,
    ReadingMode.dark => ColorFiltered(colorFilter: _darkMatrix, child: child),
    ReadingMode.sepia => ColorFiltered(colorFilter: _sepiaMatrix, child: child),
  };
}

// ---------------------------------------------------------------------------
// Side scroll thumb
// ---------------------------------------------------------------------------

class _SideScrollThumb extends StatefulWidget {
  const _SideScrollThumb({
    required this.currentPage,
    required this.totalPages,
    required this.onPageRequested,
  });

  final int currentPage;
  final int totalPages;
  final void Function(int page) onPageRequested;

  @override
  State<_SideScrollThumb> createState() => _SideScrollThumbState();
}

class _SideScrollThumbState extends State<_SideScrollThumb> {
  bool _dragging = false;
  double _dragFraction = 0;

  double get _fraction => _dragging
      ? _dragFraction
      : (widget.currentPage - 1) /
            (widget.totalPages - 1).clamp(1, double.infinity);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;
        final thumbH = (trackHeight / widget.totalPages).clamp(32.0, 80.0);
        final maxTop = trackHeight - thumbH;
        final top = (_fraction * maxTop).clamp(0.0, maxTop);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (d) {
            setState(() {
              _dragging = true;
              _dragFraction =
                  (d.localPosition.dy / trackHeight).clamp(0.0, 1.0);
            });
          },
          onVerticalDragUpdate: (d) {
            final f = (d.localPosition.dy / trackHeight).clamp(0.0, 1.0);
            setState(() => _dragFraction = f);
            final page = (f * (widget.totalPages - 1)).round() + 1;
            widget.onPageRequested(page.clamp(1, widget.totalPages));
          },
          onVerticalDragEnd: (_) => setState(() => _dragging = false),
          child: SizedBox(
            width: _dragging ? 48 : 20,
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: top,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _dragging ? 44 : 4,
                    height: thumbH,
                    decoration: BoxDecoration(
                      color: _dragging
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(_dragging ? 8 : 2),
                    ),
                    alignment: Alignment.center,
                    child: _dragging
                        ? Text(
                            '${((_dragFraction * (widget.totalPages - 1)).round() + 1).clamp(1, widget.totalPages)}',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Page indicator
// ---------------------------------------------------------------------------

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onTap,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$currentPage / $totalPages',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Jump-to-page dialog
// ---------------------------------------------------------------------------

class _JumpToPageDialog extends StatelessWidget {
  const _JumpToPageDialog({required this.controller, required this.totalPages});

  final TextEditingController controller;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to page'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: '1 – $totalPages',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: const Text('Go'),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final value = int.tryParse(controller.text);
    if (value != null && value >= 1 && value <= totalPages) {
      Navigator.pop(context, value);
    }
  }
}

// ---------------------------------------------------------------------------
// Bookmark label dialog
// ---------------------------------------------------------------------------

class _BookmarkLabelDialog extends StatefulWidget {
  const _BookmarkLabelDialog({required this.defaultLabel});

  final String defaultLabel;

  @override
  State<_BookmarkLabelDialog> createState() => _BookmarkLabelDialogState();
}

class _BookmarkLabelDialogState extends State<_BookmarkLabelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add bookmark'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.defaultLabel,
          helperText: 'Leave blank to use default name',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// More menu
// ---------------------------------------------------------------------------

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onAnnotations, required this.onReadingMode});

  final VoidCallback onAnnotations;
  final VoidCallback onReadingMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text('Annotations', style: theme.textTheme.bodyMedium),
            onTap: onAnnotations,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_medium_outlined),
            title: Text('Reading mode', style: theme.textTheme.bodyMedium),
            onTap: onReadingMode,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
