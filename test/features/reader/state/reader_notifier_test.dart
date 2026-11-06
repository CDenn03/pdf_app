import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/features/reader/state/reader_state.dart';
import 'package:sefer/features/reader/state/providers.dart';

/// In-memory fake progress store.
class _FakeProgressStore implements ReadingProgressStore {
  final Map<String, int> _pages = {};
  int saveCount = 0;

  @override
  Future<int> getLastPage(String pdfId) async => _pages[pdfId] ?? 1;

  @override
  Future<void> saveLastPage(String pdfId, int page) async {
    saveCount++;
    _pages[pdfId] = page;
  }

  @override
  Future<void> movePage(String oldPdfId, String newPdfId) async {
    final page = _pages.remove(oldPdfId);
    if (page != null) _pages[newPdfId] = page;
  }

  @override
  Future<void> clear(String pdfId) async {
    _pages.remove(pdfId);
  }
}

class _ThrowingProgressStore extends _FakeProgressStore {
  @override
  Future<int> getLastPage(String pdfId) async => throw StateError('boom');
}

void main() {
  late _FakeProgressStore store;
  late ProviderContainer container;

  setUp(() {
    store = _FakeProgressStore();
    container = ProviderContainer(
      overrides: [readingProgressProvider.overrideWithValue(store)],
    );
    // readerNotifierProvider is autoDispose; hold a subscription so it is not
    // torn down (which would cancel the debounce timer) while a test awaits.
    container.listen(readerNotifierProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  test('initial state has sensible defaults', () {
    final state = container.read(readerNotifierProvider);
    expect(state, const ReaderState());
    expect(state.isLoaded, false);
    expect(state.currentPage, 1);
  });

  group('flushProgress', () {
    test('writes the pending page without waiting for the debounce', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);

      notifier.onPageChanged(6);
      expect(store.saveCount, 0);
      await notifier.flushProgress();

      expect(store.saveCount, 1);
      expect(await store.getLastPage('abc'), 6);
    });

    test('is a no-op when nothing is pending', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);

      await notifier.flushProgress();

      expect(store.saveCount, 0);
    });

    test('loadResumePage prefers an explicit initialPage', () async {
      final notifier = container.read(readerNotifierProvider.notifier);

      final page = await notifier.loadResumePage('abc', initialPage: 5);

      expect(page, 5);
      expect(container.read(readerNotifierProvider).resumePage, 5);
    });
  });

  group('onDocumentLoaded', () {
    test('sets pdfId, totalPages and isLoaded', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      final state = container.read(readerNotifierProvider);
      expect(state.pdfId, 'abc');
      expect(state.totalPages, 10);
      expect(state.isLoaded, true);
    });

    test('resumes from persisted page', () async {
      store._pages['abc'] = 7;
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      final state = container.read(readerNotifierProvider);
      expect(state.resumePage, 7);
      expect(state.currentPage, 7);
    });

    test('clamps resume page to totalPages', () async {
      store._pages['abc'] = 99;
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      final state = container.read(readerNotifierProvider);
      expect(state.resumePage, 10);
    });
  });

  group('viewer replaced after a layout mode change', () {
    test('a second ready event keeps the current page', () async {
      store._pages['abc'] = 3;
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      notifier.onPageChanged(8);

      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);

      final state = container.read(readerNotifierProvider);
      expect(state.currentPage, 8);
      expect(state.resumePage, 3);
    });

    test('a different page count re-clamps the current page', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      notifier.onPageChanged(8);

      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 5);

      expect(container.read(readerNotifierProvider).currentPage, 5);
    });
  });

  group('loadResumePage', () {
    test('reads the saved page only once per document', () async {
      store._pages['abc'] = 4;
      final notifier = container.read(readerNotifierProvider.notifier);
      expect(await notifier.loadResumePage('abc'), 4);
      store._pages['abc'] = 9;
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      expect(container.read(readerNotifierProvider).resumePage, 4);
    });

    test('falls back to page 1 when the store fails', () async {
      final failing = ProviderContainer(
        overrides: [
          readingProgressProvider.overrideWithValue(_ThrowingProgressStore()),
        ],
      );
      addTearDown(failing.dispose);
      failing.listen(readerNotifierProvider, (_, _) {});
      final page = await failing
          .read(readerNotifierProvider.notifier)
          .loadResumePage('abc');
      expect(page, 1);
    });
  });

  group('onPageChanged', () {
    test('updates currentPage', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      notifier.onPageChanged(5);
      expect(container.read(readerNotifierProvider).currentPage, 5);
    });

    test('persists page to store', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      notifier.onPageChanged(5);
      await _flushDebounce();
      expect(store._pages['abc'], 5);
    });

    test('persists nothing while pdfId is empty', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      notifier.onPageChanged(5);
      await _flushDebounce();
      expect(store._pages, isEmpty);
    });

    test('a direct jump to page 1 is always persisted', () async {
      store._pages['A'] = 7;
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'A', totalPages: 10);

      notifier.onPageChanged(1);
      await _flushDebounce();

      expect(store._pages['A'], 1);
      expect(container.read(readerNotifierProvider).currentPage, 1);
    });

    test('page 1 is persisted when no later page was saved', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'A', totalPages: 10);

      notifier.onPageChanged(1);
      await _flushDebounce();

      expect(store._pages['A'], 1);
    });

    test('closing the reader flushes the pending progress write', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      notifier.onPageChanged(6);
      expect(store._pages['abc'], isNull);

      container.dispose();

      expect(store._pages['abc'], 6);
    });

    test('closing the reader without changes writes nothing', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      container.dispose();
      expect(store.saveCount, 0);
    });

    test('rapid page changes collapse into a single write', () async {
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 100);
      for (var page = 2; page <= 20; page++) {
        notifier.onPageChanged(page);
      }
      expect(store.saveCount, 0);
      await _flushDebounce();
      expect(store.saveCount, 1);
      expect(store._pages['abc'], 20);
    });
  });
}

Future<void> _flushDebounce() =>
    Future<void>.delayed(const Duration(milliseconds: 500));
