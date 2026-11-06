import 'package:sefer/features/reader/domain/per_page_cache.dart';
import 'package:sefer/features/reader/domain/reader_page_text.dart';
import 'package:sefer/features/reader/domain/reader_page_text_source.dart';

class CachingPageTextSource implements ReaderPageTextSource {
  CachingPageTextSource({required ReaderPageTextSource source})
    : _cache = PerPageCache(load: source.textOn);

  final PerPageCache<ReaderPageText> _cache;

  @override
  Future<ReaderPageText> textOn(int pageNumber) => _cache.of(pageNumber);
}
