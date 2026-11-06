import 'package:sefer/features/reader/domain/reader_page_text.dart';

abstract interface class ReaderPageTextSource {
  Future<ReaderPageText> textOn(int pageNumber);
}
