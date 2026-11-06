import 'package:sefer/features/reader/domain/reader_page_navigation.dart';

class RecordingPageNavigation implements ReaderPageNavigation {
  final List<int> requestedPages = [];

  @override
  int currentPage = 1;

  @override
  Future<void> goToPage(int pageNumber) async {
    requestedPages.add(pageNumber);
    currentPage = pageNumber;
  }
}
