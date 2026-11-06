import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/domain/page_range.dart';
import 'package:sefer/features/reader/domain/reader_page_navigation.dart';

/// Converts between the one-based page numbers the reader works in and the
/// zero-based indices [PageController] expects. This is the only place in
/// the paged viewport that performs that conversion. Moves of more than one
/// page jump, so pages in between are never built or reported.
class PageControllerNavigation implements ReaderPageNavigation {
  PageControllerNavigation({
    required PageController controller,
    required int totalPages,
  }) : _controller = controller,
       _range = PageRange(totalPages);

  static const _animationDuration = Duration(milliseconds: 250);
  static const _animationCurve = Curves.easeOutCubic;

  final PageController _controller;
  final PageRange _range;

  bool get _attached => _controller.hasClients;

  bool _isAdjacent(int index) =>
      (index - _range.indexOf(currentPage)).abs() <= 1;

  @override
  int get currentPage {
    if (!_attached) return _range.pageNumberAt(0);
    final page = _controller.page ?? _controller.initialPage.toDouble();
    return _range.pageNumberAt(page.round());
  }

  @override
  Future<void> goToPage(int pageNumber) async {
    if (!_attached) return;
    final index = _range.indexOf(pageNumber);
    if (_isAdjacent(index)) {
      await _controller.animateToPage(
        index,
        duration: _animationDuration,
        curve: _animationCurve,
      );
    } else {
      _controller.jumpToPage(index);
    }
  }
}
