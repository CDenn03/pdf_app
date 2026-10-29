import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/features/reader/state/reader_state.dart';
import 'package:sefer/features/reader/state/providers.dart';

/// In-memory fake that always returns page 1 and discards saves.
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

    test('an initial page-1 callback does not clobber saved progress',
        () async {
      store._pages['A'] = 7;
      final notifier = container.read(readerNotifierProvider.notifier);
      await notifier.onDocumentLoaded(pdfId: 'A', totalPages: 10);
      expect(container.read(readerNotifierProvider).resumePage, 7);

      notifier.onPageChanged(1);
      await _flushDebounce();
      expect(store._pages['A'], 1);

      final reopened = ProviderContainer(
        overrides: [readingProgressProvider.overrideWithValue(store)],
      );
      addTearDown(reopened.dispose);
      await reopened
          .read(readerNotifierProvider.notifier)
          .onDocumentLoaded(pdfId: 'A', totalPages: 10);
      expect(reopened.read(readerNotifierProvider).resumePage, 1);
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
