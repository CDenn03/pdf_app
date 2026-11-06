import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/active_page_navigation.dart';
import 'package:sefer/features/reader/domain/active_search_backend.dart';
import '../support/fake_search_backend.dart';
import '../support/recording_page_navigation.dart';

void main() {
  group('ActivePageNavigation', () {
    late ActivePageNavigation navigation;
    late RecordingPageNavigation first;
    late RecordingPageNavigation second;
    const firstOwner = 'first';
    const secondOwner = 'second';

    setUp(() {
      navigation = ActivePageNavigation();
      first = RecordingPageNavigation();
      second = RecordingPageNavigation();
    });

    test('given no viewport, going to a page does nothing', () async {
      await navigation.goToPage(4);

      expect(navigation.currentPage, 1);
    });

    test('given an attached viewport, requests reach it', () async {
      navigation.attach(firstOwner, first);

      await navigation.goToPage(4);

      expect(first.requestedPages, [4]);
      expect(navigation.currentPage, 4);
    });

    test('given a replaced viewport, requests reach the new one', () async {
      navigation.attach(firstOwner, first);
      navigation.attach(secondOwner, second);

      await navigation.goToPage(6);

      expect(first.requestedPages, isEmpty);
      expect(second.requestedPages, [6]);
    });

    test('when the replaced viewport detaches late, the new one stays '
        'attached', () async {
      navigation.attach(firstOwner, first);
      navigation.attach(secondOwner, second);

      navigation.detach(firstOwner);
      await navigation.goToPage(2);

      expect(second.requestedPages, [2]);
    });

    test('when the active viewport detaches, requests are dropped', () async {
      navigation.attach(firstOwner, first);

      navigation.detach(firstOwner);
      await navigation.goToPage(3);

      expect(first.requestedPages, isEmpty);
      expect(navigation.currentPage, 1);
    });
  });

  group('ActiveSearchBackend', () {
    late ActiveSearchBackend backend;
    late FakeSearchBackend first;
    late FakeSearchBackend second;

    setUp(() {
      backend = ActiveSearchBackend();
      first = FakeSearchBackend();
      second = FakeSearchBackend();
    });

    test('given no viewport, search is empty and reveal declines', () async {
      expect(await backend.search('x').toList(), isEmpty);
      expect(await backend.reveal(matchOnPage(1), margin: 0), isFalse);
    });

    test('given an attached viewport, search and reveal use it', () async {
      backend.attach('first', first);

      backend.search('word').listen((_) {});
      final revealed = await backend.reveal(matchOnPage(2), margin: 8);

      expect(first.queries, ['word']);
      expect(first.revealed, [matchOnPage(2)]);
      expect(revealed, isTrue);
    });

    test('when a replaced viewport detaches late, the new one keeps '
        'serving', () {
      backend.attach('first', first);
      backend.attach('second', second);

      backend.detach('first');
      backend.search('word').listen((_) {});

      expect(first.queries, isEmpty);
      expect(second.queries, ['word']);
    });
  });
}
