import 'package:sefer/features/reader/domain/reader_page_text.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';

class FakePageTextSource implements ReaderPageTextSource {
  FakePageTextSource([this.textByPage = const {}]);

  final Map<int, ReaderPageText> textByPage;

  @override
  Future<ReaderPageText> textOn(int pageNumber) async =>
      textByPage[pageNumber] ?? ReaderPageText.empty;
}
