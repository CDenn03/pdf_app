class InitialPageReportFilter {
  InitialPageReportFilter({required this.initialPage});

  final int initialPage;
  bool _viewerReported = false;

  bool shouldForward(int? reportedPage) {
    if (reportedPage == null) return true;
    final isSpuriousFirstPage =
        !_viewerReported && reportedPage == 1 && initialPage > 1;
    if (isSpuriousFirstPage) return false;
    _viewerReported = true;
    return true;
  }
}
