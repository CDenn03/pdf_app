import 'package:sefer/features/reader/domain/page_range.dart';
import 'package:sefer/features/reader/domain/reader_page_navigation.dart';
import 'package:sefer/features/reader/presentation/book_flip_controller.dart';

class BookFlipPageNavigation implements ReaderPageNavigation {
  BookFlipPageNavigation({
    required BookFlipController controller,
    required int totalPages,
  }) : _controller = controller,
       _range = PageRange(totalPages);

  final BookFlipController _controller;
  final PageRange _range;

  @override
  int get currentPage => _controller.currentPage;

  @override
  Future<void> goToPage(int pageNumber) async {
    if (!_controller.isActive) return;
    final target = _range.clamp(pageNumber);
    if (target == currentPage) return;
    await _controller.goTo(target);
  }
}
