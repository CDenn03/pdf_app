import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' show PdfDocument;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/models/annotation.dart' as app;
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
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
/// ## Why bars live in Scaffold slots, not inside the body Stack
///
/// [SfPdfViewer] renders as a PlatformView on Android/iOS. PlatformViews
/// swallow all touch events at the OS level before Flutter's gesture arena
/// sees them. Any [GestureDetector] or [Listener] placed *inside* the same
/// Stack as the viewer will never receive taps or drags over the PDF area.
///
/// Solution: the top bar and bottom action bar are placed in
/// [Scaffold.appBar] and [Scaffold.bottomNavigationBar] respectively.
/// These slots are laid out *outside* the PlatformView's bounds by the
/// Scaffold, so they always receive input correctly. They animate their
/// opacity to show/hide without leaving the widget tree.
///
/// The [GestureHandler] for annotations is placed *above* the viewer in
/// the body Stack. It works because in annotation mode we set
/// [SfPdfViewer]'s `interactionMode` to `none`, which disables the
/// PlatformView's own touch handling and lets Flutter's gesture arena
/// take over.
class ReaderPage extends ConsumerStatefulWidget {
  final String pdfPath;

  const ReaderPage({super.key, this.pdfPath = kSamplePdfPath});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late final PdfViewerController _pdfController;

  Size _pageSize = Size.zero;
  int _currentPage = 1;
  int _totalPages = 1;
  PdfDocument? _pdfDocument;

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

  bool get _pageReady => _pageSize != Size.zero;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    // Start with bars visible so the user knows they exist.
    _scheduleAutoHide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryEntriesProvider.notifier).recordOpened(widget.pdfPath);
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _pdfController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Document lifecycle
  // ---------------------------------------------------------------------------

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    final size = details.document.pages[0].size;
    final total = details.document.pages.count;

    setState(() {
      _pageSize = Size(size.width, size.height);
      _totalPages = total;
      _pdfDocument = details.document;
    });

    ref
        .read(readerNotifierProvider.notifier)
        .onDocumentLoaded(pdfId: widget.pdfPath, totalPages: total)
        .then((_) {
          final resumePage = ref.read(readerNotifierProvider).resumePage;
          if (resumePage > 1) _pdfController.jumpToPage(resumePage);
        });

    ref
        .read(annotationNotifierProvider.notifier)
        .loadForPage(widget.pdfPath, _currentPage);
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load PDF: ${details.error}')),
    );
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    final page = details.newPageNumber;
    setState(() {
      _currentPage = page;
      _updateBookmarkState();
    });
    ref.read(readerNotifierProvider.notifier).onPageChanged(page);
    ref
        .read(annotationNotifierProvider.notifier)
        .loadForPage(widget.pdfPath, page);
  }

  // ---------------------------------------------------------------------------
  // Bar visibility — toggled by tapping the PDF area via SfPdfViewer callback
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
    // null = cancelled, empty string = use default
    if (label == null) return; // user cancelled
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
    if (page != null) _pdfController.jumpToPage(page);
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
      document: _pdfDocument,
    ).then((_) => _showBars());
  }

  void _openAnnotations() {
    _hideBars();
    showAnnotationPanel(
      context: context,
      pdfId: widget.pdfPath,
      onNavigate: (page) => _pdfController.jumpToPage(page),
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
            onModeChanged: (mode) => setState(() => _readingMode = mode),
            currentScrollDirection: _scrollDirection,
            onScrollDirectionChanged: (dir) =>
                setState(() => _scrollDirection = dir),
          ).then((_) => _showBars());
        },
      ),
    ).then((_) {
      // Only show bars if no sub-panel was opened.
      if (mounted && !_annotating) _showBars();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  List<app.Annotation> _visibleAnnotations(List<app.Annotation> all) =>
      all.where((a) => a.page == _currentPage && !a.isDeleted).toList();

  @override
  Widget build(BuildContext context) {
    final annotations = ref.watch(annotationNotifierProvider);
    final visible = _visibleAnnotations(annotations);

    // bottomNavigationBar is set to null when hidden so Scaffold reclaims
    // the space entirely — an invisible-but-present bar still occupies height.
    // The annotation toolbar is always shown when annotating (no auto-hide).
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
        body: _buildBody(visible),
      ),
    );
  }

  Widget _buildBody(List<app.Annotation> visibleAnnotations) {
    return Stack(
      children: [
        // Layer 1: PDF viewer, wrapped in a color filter for reading mode.
        // _ScrollAmplifier is only active in paginated mode — in continuous
        // mode SfPdfViewer handles its own scroll physics natively.
        _ScrollAmplifier(
          controller: _pdfController,
          enabled:
              !_annotating && _scrollDirection == ScrollDirection.paginated,
          child: _ReadingModeFilter(mode: _readingMode, child: _buildViewer()),
        ),

        // Layer 2: Annotation gesture capture.
        // Only active in annotation mode. SfPdfViewer's interactionMode is
        // set to PdfInteractionMode.none in that state, which disables the
        // PlatformView's touch handling and lets this GestureDetector win.
        if (_pageReady && _annotating)
          Positioned.fill(
            child: GestureHandler(
              pageSize: _pageSize,
              currentPage: _currentPage,
              pdfId: widget.pdfPath,
              activeTool: _activeTool,
            ),
          ),

        // Layer 3: Annotation overlays.
        // Notes get a tap-through layer so tapping a note anchor shows
        // the note text in a non-invasive tooltip.
        // Highlights and bookmarks are purely visual (IgnorePointer).
        if (_pageReady && visibleAnnotations.isNotEmpty)
          Positioned.fill(
            child: _AnnotationOverlay(
              annotations: visibleAnnotations,
              pageSize: _pageSize,
            ),
          ),

        // Layer 4: Page indicator pill.
        if (_pageReady)
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

        // Layer 5: Side scroll thumb — right edge, always visible.
        if (_pageReady && _totalPages > 1)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _SideScrollThumb(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageRequested: (page) => _pdfController.jumpToPage(page),
            ),
          ),
      ],
    );
  }

  Widget _buildViewer() {
    // In annotation mode use pan mode — this disables the viewer's text
    // selection gesture recognizer so the GestureHandler above it can
    // receive drag events uncontested.
    final interactionMode = _annotating
        ? PdfInteractionMode.pan
        : PdfInteractionMode.selection;

    // Paginated = single page, swipe left/right.
    // Continuous = all pages in a vertical scroll.
    final layoutMode = _scrollDirection == ScrollDirection.continuous
        ? PdfPageLayoutMode.continuous
        : PdfPageLayoutMode.single;

    if (_isAsset) {
      return SfPdfViewer.asset(
        widget.pdfPath,
        controller: _pdfController,
        interactionMode: interactionMode,
        pageLayoutMode: layoutMode,
        pageSpacing: 4,
        onDocumentLoaded: _onDocumentLoaded,
        onDocumentLoadFailed: _onDocumentLoadFailed,
        onPageChanged: _onPageChanged,
        onTap: (_) => _toggleBars(),
        canShowScrollHead: false,
        canShowScrollStatus: false,
        canShowPaginationDialog: false,
      );
    }
    return SfPdfViewer.file(
      File(widget.pdfPath),
      controller: _pdfController,
      interactionMode: interactionMode,
      pageLayoutMode: layoutMode,
      pageSpacing: 4,
      onDocumentLoaded: _onDocumentLoaded,
      onDocumentLoadFailed: _onDocumentLoadFailed,
      onPageChanged: _onPageChanged,
      onTap: (_) => _toggleBars(),
      canShowScrollHead: false,
      canShowScrollStatus: false,
      canShowPaginationDialog: false,
    );
  }

  String get _documentTitle {
    final path = widget.pdfPath;
    final name = path.split('/').last;
    return name.endsWith('.pdf') ? name.substring(0, name.length - 4) : name;
  }
}

// ---------------------------------------------------------------------------
// Annotation overlay — highlights (non-interactive) + note tap targets
// ---------------------------------------------------------------------------

/// Renders annotation overlays and handles taps on note anchors.
///
/// Highlights and bookmarks are wrapped in [IgnorePointer] so touches
/// pass through to the PDF viewer. Note anchors are tappable — a tap
/// shows the note text in a non-invasive bottom tooltip.
class _AnnotationOverlay extends StatelessWidget {
  const _AnnotationOverlay({required this.annotations, required this.pageSize});

  final List<app.Annotation> annotations;
  final Size pageSize;

  @override
  Widget build(BuildContext context) {
    final notes = annotations
        .where((a) => a.type == AnnotationType.note && a.rect != null)
        .toList();

    return Stack(
      children: [
        // Non-interactive paint layer for highlights + note anchors.
        IgnorePointer(
          child: CustomPaint(
            painter: HighlightPainter(
              annotations: annotations,
              pageSize: pageSize,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        // Tap targets for notes — positioned over each note anchor.
        for (final note in notes)
          _NoteTapTarget(annotation: note, pageSize: pageSize),
      ],
    );
  }
}

/// A transparent tap target positioned over a note anchor circle.
///
/// On tap, shows the note text in a small bottom sheet tooltip.
class _NoteTapTarget extends StatelessWidget {
  const _NoteTapTarget({required this.annotation, required this.pageSize});

  final app.Annotation annotation;
  final Size pageSize;

  @override
  Widget build(BuildContext context) {
    final rect = annotation.rect!;
    // Convert relative coords to absolute, then position a tap target.
    final left = rect.left * pageSize.width - 16;
    final top = rect.top * pageSize.height - 16;

    return Positioned(
      left: left.clamp(0.0, double.infinity),
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
      builder: (ctx) => _NoteTooltipSheet(text: text, color: annotation.color),
    );
  }
}

/// A compact, non-invasive bottom sheet that shows a note's text.
class _NoteTooltipSheet extends StatelessWidget {
  const _NoteTooltipSheet({required this.text, required this.color});

  final String text;
  final AnnotationColor color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Row(
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
    // Derive a high-contrast text style directly from the reading mode colors
    // rather than relying on AppBarTheme, which may apply the wrong color.
    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: readingMode.primaryText,
    );

    return AppBar(
      backgroundColor: readingMode.controlSurface,
      foregroundColor: readingMode.primaryText,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
        tooltip: 'Back',
      ),
      title: Text(title, overflow: TextOverflow.ellipsis, style: titleStyle),
      actions: [
        IconButton(
          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
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

/// Applies a color filter to the PDF viewer to implement reading modes.
///
/// [SfPdfViewer] is a PlatformView — its internal background cannot be
/// changed via Flutter properties. A [ColorFiltered] widget is the only
/// way to affect its rendered output.
///
/// - Light: no filter (pass-through)
/// - Dark: invert colors then rotate hue 180° to restore natural hues
///   (standard "dark mode PDF" technique — text becomes white, background
///   becomes dark, images look natural)
/// - Sepia: warm matrix that shifts whites toward amber and blacks toward
///   dark brown
class _ReadingModeFilter extends StatelessWidget {
  const _ReadingModeFilter({required this.mode, required this.child});

  final ReadingMode mode;
  final Widget child;

  // Standard invert + hue-rotate matrix for dark mode.
  static const _darkMatrix = ColorFilter.matrix(<double>[
    -1,
    0,
    0,
    0,
    255,
    0,
    -1,
    0,
    0,
    255,
    0,
    0,
    -1,
    0,
    255,
    0,
    0,
    0,
    1,
    0,
  ]);

  // Sepia matrix: warm amber tones.
  static const _sepiaMatrix = ColorFilter.matrix(<double>[
    0.393,
    0.769,
    0.189,
    0,
    0,
    0.349,
    0.686,
    0.168,
    0,
    0,
    0.272,
    0.534,
    0.131,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      ReadingMode.light => child,
      ReadingMode.dark => ColorFiltered(colorFilter: _darkMatrix, child: child),
      ReadingMode.sepia => ColorFiltered(
        colorFilter: _sepiaMatrix,
        child: child,
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Scroll amplifier
// ---------------------------------------------------------------------------

class _ScrollAmplifier extends StatefulWidget {
  const _ScrollAmplifier({
    required this.controller,
    required this.enabled,
    required this.child,
  });

  final PdfViewerController controller;
  final bool enabled;
  final Widget child;

  static const double amplification = 0.05;

  @override
  State<_ScrollAmplifier> createState() => _ScrollAmplifierState();
}

class _ScrollAmplifierState extends State<_ScrollAmplifier> {
  int? _activePointer;
  double _lastY = 0;

  void _onPointerDown(PointerDownEvent e) {
    _activePointer = e.pointer;
    _lastY = e.position.dy;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!widget.enabled || e.pointer != _activePointer) return;
    final dy = e.position.dy - _lastY;
    _lastY = e.position.dy;
    if (dy == 0) return;
    final extra = -dy * _ScrollAmplifier.amplification;
    final current = widget.controller.scrollOffset;
    widget.controller.jumpTo(xOffset: current.dx, yOffset: current.dy + extra);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer == _activePointer) _activePointer = null;
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer == _activePointer) _activePointer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Side scroll thumb
// ---------------------------------------------------------------------------

/// A draggable right-edge scroll indicator.
///
/// Shows the current position within the document and lets the user drag
/// to jump to any page. The thumb is always visible but unobtrusive —
/// 4px wide at rest, expanding to a pill with page number on drag.
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
        // Thumb height: at least 32px, proportional to 1/totalPages.
        final thumbH = (trackHeight / widget.totalPages).clamp(32.0, 80.0);
        final maxTop = trackHeight - thumbH;
        final top = (_fraction * maxTop).clamp(0.0, maxTop);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (d) {
            setState(() {
              _dragging = true;
              _dragFraction = (d.localPosition.dy / trackHeight).clamp(
                0.0,
                1.0,
              );
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
                // Track line.
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                // Thumb.
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

/// Asks the user for an optional bookmark name.
///
/// Pressing Save with an empty field uses the default label.
/// Pressing Cancel returns null (no bookmark created).
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
          onPressed: () => Navigator.pop(context), // null = cancelled
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
