import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/domain/page_range.dart';

typedef PagedPageBuilder =
    Widget Function(BuildContext context, int pageNumber);

/// One page per screen, swiped horizontally. Reports one-based page numbers.
class PagedReaderGallery extends StatelessWidget {
  const PagedReaderGallery({
    super.key,
    required this.controller,
    required this.totalPages,
    required this.swipeEnabled,
    required this.pageBuilder,
    required this.onPageChanged,
    required this.onTap,
  });

  final PageController controller;
  final int totalPages;
  final bool swipeEnabled;
  final PagedPageBuilder pageBuilder;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final range = PageRange(totalPages);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: PageView.builder(
        controller: controller,
        physics: swipeEnabled
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        allowImplicitScrolling: false,
        itemCount: totalPages,
        onPageChanged: (index) => onPageChanged(range.pageNumberAt(index)),
        itemBuilder: (context, index) {
          final pageNumber = range.pageNumberAt(index);
          return KeyedSubtree(
            key: ValueKey(pageNumber),
            child: pageBuilder(context, pageNumber),
          );
        },
      ),
    );
  }
}
