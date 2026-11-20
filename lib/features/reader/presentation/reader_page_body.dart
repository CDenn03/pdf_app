import 'package:flutter/material.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/domain/reader_search_controller.dart';
import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import 'package:sefer/features/reader/presentation/reader_chrome.dart';
import 'package:sefer/features/reader/presentation/reader_find_bar.dart';
import 'package:sefer/features/reader/presentation/reader_overlays.dart';
import 'package:sefer/features/reader/presentation/reader_page_scrubber.dart';
import 'package:sefer/features/reader/presentation/reader_rename_flow.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_inset.dart';

class ReaderPageBody extends StatelessWidget {
  const ReaderPageBody({
    super.key,
    required this.readingMode,
    required this.barVisible,
    required this.annotating,
    required this.activeTool,
    required this.findBarVisible,
    required this.showLoading,
    required this.showViewer,
    required this.currentPage,
    required this.totalPages,
    required this.renameBusy,
    required this.search,
    required this.viewer,
    required this.onJumpToPage,
    required this.onToolChanged,
    required this.onExitAnnotation,
    required this.onUndo,
    required this.onSearch,
    required this.onAnnotate,
    required this.onToc,
    required this.onMore,
    required this.onCloseFindBar,
    required this.onPageRequested,
  });

  final ReadingMode readingMode;
  final bool barVisible;
  final bool annotating;
  final AnnotationTool activeTool;
  final bool findBarVisible;
  final bool showLoading;
  final bool showViewer;
  final int currentPage;
  final int totalPages;
  final bool renameBusy;
  final ReaderSearchController search;
  final Widget viewer;
  final VoidCallback onJumpToPage;
  final ValueChanged<AnnotationTool> onToolChanged;
  final VoidCallback onExitAnnotation;
  final VoidCallback onUndo;
  final VoidCallback onSearch;
  final VoidCallback onAnnotate;
  final VoidCallback onToc;
  final VoidCallback onMore;
  final VoidCallback onCloseFindBar;
  final ValueChanged<int> onPageRequested;

  static const _barHeight = 60.0;
  static const _barMargin = 12.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final indicatorBottom = barVisible
        ? _barHeight + _barMargin + media.padding.bottom + 12
        : 16.0;
    final findBarTop = media.padding.top + (barVisible ? kToolbarHeight : 0.0);

    return Stack(
      children: [
        ReaderViewportInset(
          topInset: media.padding.top,
          child: ReadingModeFilter(
            mode: readingMode,
            child: showViewer ? viewer : const SizedBox.expand(),
          ),
        ),
        if (showLoading) const DocumentLoadingOverlay(),
        if (findBarVisible)
          Positioned(
            top: findBarTop,
            left: 0,
            right: 0,
            child: ReaderFindBar(
              search: search,
              readingMode: readingMode,
              onClose: onCloseFindBar,
            ),
          ),
        Positioned(
          bottom: indicatorBottom,
          left: 0,
          right: 0,
          child: Center(
            child: PageIndicator(
              currentPage: currentPage,
              totalPages: totalPages,
              onTap: onJumpToPage,
            ),
          ),
        ),
        if (annotating)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + media.padding.bottom,
            child: AnnotationToolbar(
              activeTool: activeTool,
              onToolChanged: onToolChanged,
              onExit: onExitAnnotation,
              onUndo: onUndo,
              readingMode: readingMode,
            ),
          ),
        if (barVisible)
          Positioned(
            left: 16,
            right: 16,
            bottom: _barMargin + media.padding.bottom,
            child: BottomActionBar(
              onSearch: onSearch,
              onAnnotate: onAnnotate,
              onToc: onToc,
              onMore: onMore,
              readingMode: readingMode,
            ),
          ),
        if (totalPages > 1)
          Positioned(
            right: media.padding.right,
            top: findBarTop + (findBarVisible ? 64 : 8),
            bottom: indicatorBottom + 40,
            child: ReaderPageScrubber(
              currentPage: currentPage,
              totalPages: totalPages,
              readingMode: readingMode,
              onPageRequested: onPageRequested,
            ),
          ),
        if (renameBusy) const RenameProgressOverlay(),
      ],
    );
  }
}
