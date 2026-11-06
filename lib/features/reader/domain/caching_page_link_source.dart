import 'package:sefer/features/reader/domain/per_page_cache.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';

class CachingPageLinkSource implements ReaderPageLinkSource {
  CachingPageLinkSource({required ReaderPageLinkSource source})
    : _cache = PerPageCache(load: source.linksOn);

  final PerPageCache<List<ReaderPageLink>> _cache;

  @override
  Future<List<ReaderPageLink>> linksOn(int pageNumber) => _cache.of(pageNumber);
}
