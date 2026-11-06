import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/caching_page_link_source.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';

class _CountingLinkSource implements ReaderPageLinkSource {
  final List<int> loaded = [];
  bool failing = false;

  @override
  Future<List<ReaderPageLink>> linksOn(int pageNumber) async {
    loaded.add(pageNumber);
    if (failing) throw StateError('unreadable page');
    return [
      ReaderPageLink(
        target: PageLinkTarget(pageNumber),
        normalizedBounds: const [],
      ),
    ];
  }
}

void main() {
  late _CountingLinkSource inner;
  late CachingPageLinkSource cached;

  setUp(() {
    inner = _CountingLinkSource();
    cached = CachingPageLinkSource(source: inner);
  });

  test(
    'given a page asked twice, it loads once and shares the result',
    () async {
      final first = await cached.linksOn(3);
      final second = await cached.linksOn(3);

      expect(inner.loaded, [3]);
      expect(second, same(first));
    },
  );

  test('given a repeat request while loading, it loads once', () async {
    final results = await Future.wait([cached.linksOn(2), cached.linksOn(2)]);

    expect(inner.loaded, [2]);
    expect(results.first, same(results.last));
  });

  test('given different pages, each loads separately', () async {
    await cached.linksOn(1);
    await cached.linksOn(2);

    expect(inner.loaded, [1, 2]);
  });

  test('given a failed load, the next request tries again', () async {
    inner.failing = true;
    await expectLater(cached.linksOn(1), throwsStateError);
    await pumpEventQueue();

    inner.failing = false;
    final links = await cached.linksOn(1);

    expect(inner.loaded, [1, 1]);
    expect(links.single.target, const PageLinkTarget(1));
  });
}
