import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/models/annotation.dart' as app;
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/models/note_entry.dart';
import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/core/theme/scroll_direction.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';
import 'package:pdf_app/features/recents/state/recents_notifier.dart';
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

  // Reading mode and scroll direction are derived from the global settings
  // provider in build() — no local fields needed.

  // Bookmark state for current page.
  bool _currentPageBookmarked = false;

  bool get _isAsset =>
      !widget.pdfPath.startsWith('/') && !widget.pdfPath.contains('://');

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _scheduleAutoHide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryEntriesProvider.notifier).recordOpened(widget.pdfPath);
      ref.read(recentsProvider.notifier).recordOpened(widget.pdfPath);
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
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
        .loadForPage(
          widget.pdfPath,
          _currentPage,
          window:
              ref.read(appSettingsProvider).scrollDirection ==
                  ScrollDirection.continuous
              ? 3
              : 1,
        );

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
        .loadForPage(
          widget.pdfPath,
          page,
          window:
              ref.read(appSettingsProvider).scrollDirection ==
                  ScrollDirection.continuous
              ? 3
              : 1,
        );
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
      builder: (ctx) => _MoreMenu(
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
            ? _ReaderAppBar(
                title: _documentTitle,
                isBookmarked: _currentPageBookmarked,
                onBack: _navigateBack,
                onBookmark: _toggleBookmark,
                readingMode: readingMode,
              )
            : null,
        body: _buildBody(readingMode),
      ),
    );
  }

  Widget _buildBody(ReadingMode readingMode) {
    // Floating pill bar height + margin for page indicator clearance.
    const barHeight = 60.0;
    const barMargin = 12.0;
    final barVisible = _barsVisible && !_annotating;
    final indicatorBottom = barVisible ? barHeight + barMargin + 8 : 16.0;

    return Stack(
      children: [
        _ReadingModeFilter(mode: readingMode, child: _buildViewer()),

        Positioned(
          bottom: indicatorBottom,
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

        // Floating annotation toolbar (replaces pill bar while annotating).
        if (_annotating)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
            child: AnnotationToolbar(
              activeTool: _activeTool,
              onToolChanged: (tool) => setState(() => _activeTool = tool),
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
            child: _BottomActionBar(
              onSearch: _openSearch,
              onAnnotate: _enterAnnotationMode,
              onToc: _openToc,
              onMore: _openMore,
              readingMode: readingMode,
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
    final settings = ref.read(appSettingsProvider);
    final bool isPaginated =
        settings.scrollDirection == ScrollDirection.sideBySide ||
        settings.scrollDirection == ScrollDirection.bookFlip;
    final readingMode = settings.readingMode;

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
      // Pre-compensate highlight colors for the reading mode's color filter
      // so search matches remain visible in dark and sepia modes.
      matchTextColor: readingMode.searchMatchColor,
      activeMatchTextColor: readingMode.searchActiveMatchColor,
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
        .watch(annotationNotifierProvider.select((m) => m[pageNumber] ?? []))
        .where((a) => !a.isDeleted)
        .toList();

    final notes = annotations
        .where((a) => a.type == AnnotationType.note && a.rects.isNotEmpty)
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

          if (_annotating)
            Positioned.fill(
              child: GestureHandler(
                pageSize: pageSize,
                currentPage: pageNumber,
                pdfId: widget.pdfPath,
                activeTool: _activeTool,
                pdfPageSize: pdfPageSize,
                sfDocument: _sfDocument,
                onAddBookmark: _addBookmarkWithLabel,
              ),
            ),

          // Note tap targets must sit above GestureHandler so existing
          // note badges intercept taps before the gesture handler does.
          for (final note in notes)
            _NoteTapTarget(annotation: note, pageSize: pageSize),
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

/// Tap target for a note annotation marker on the page edge.
///
/// Positioned to match the tab drawn by [HighlightPainter._paintNote].
class _NoteTapTarget extends StatelessWidget {
  const _NoteTapTarget({required this.annotation, required this.pageSize});

  final app.Annotation annotation;
  final Size pageSize;

  @override
  Widget build(BuildContext context) {
    final pos = annotation.rects.first;
    final isLeftEdge = pos.left < 0.5;
    const tabWidth = 20.0;
    const tabHeight = 28.0;
    final verticalCenter = pos.top * pageSize.height;

    return Positioned(
      left: isLeftEdge ? 0.0 : null,
      right: isLeftEdge ? null : 0.0,
      top: (verticalCenter - tabHeight / 2).clamp(0.0, double.infinity),
      child: GestureDetector(
        onTap: () => _showNoteSheet(context),
        child: const SizedBox(width: tabWidth, height: tabHeight),
      ),
    );
  }

  void _showNoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _NoteMarkerSheet(annotation: annotation),
    );
  }
}

class _NoteMarkerSheet extends ConsumerStatefulWidget {
  const _NoteMarkerSheet({required this.annotation});

  final app.Annotation annotation;

  @override
  ConsumerState<_NoteMarkerSheet> createState() => _NoteMarkerSheetState();
}

class _NoteMarkerSheetState extends ConsumerState<_NoteMarkerSheet> {
  List<NoteEntry>? _entries;
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await ref
        .read(annotationNotifierProvider.notifier)
        .loadNoteEntries(widget.annotation.id);
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _addEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    await ref
        .read(annotationNotifierProvider.notifier)
        .addNoteEntry(widget.annotation.id, text);
    _controller.clear();
    await _load();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.annotation.color;
    final entries = _entries;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color.solid,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('Note', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          if (entries == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator.adaptive(),
              ),
            )
          else if (entries.isEmpty)
            Text(
              'No entries yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (_, i) => _NoteEntryTile(
                  entry: entries[i],
                  color: color,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Add a note…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _saving ? null : _addEntry,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteEntryTile extends StatelessWidget {
  const _NoteEntryTile({required this.entry, required this.color});

  final NoteEntry entry;
  final AnnotationColor color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: color.solid,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.text, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  _formatTime(entry.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}  $h:$m';
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

/// Floating pill-shaped action bar for the reader.
///
/// Mirrors the home shell's nav pill aesthetic while using reading-mode
/// colours so it blends with light, dark, and sepia backgrounds.
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
    final surface = readingMode.controlSurface.withValues(alpha: 0.92);
    final borderColor = readingMode.primaryText.withValues(alpha: 0.08);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
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
