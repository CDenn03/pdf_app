import 'package:sefer/features/reader/domain/reader_page_link.dart';

class FakePageLinkSource implements ReaderPageLinkSource {
  FakePageLinkSource([this.linksByPage = const {}]);

  final Map<int, List<ReaderPageLink>> linksByPage;

  @override
  Future<List<ReaderPageLink>> linksOn(int pageNumber) async =>
      linksByPage[pageNumber] ?? const [];
}
