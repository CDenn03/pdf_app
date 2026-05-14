import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_app/core/services/reading_progress_service.dart';
import 'package:pdf_app/features/reader/state/reader_state.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

/// In-memory fake that always returns page 1 and discards saves.
class _FakeProgressStore implements ReadingProgressStore {
  final Map<String, int> _pages = {};

  @override
  Future<int> getLastPage(String pdfId) async => _pages[pdfId] ?? 1;

  @override
  Future<void> saveLastPage(String pdfId, int page) async {
    _pages[pdfId] = page;
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
      expect(store._pages['abc'], 5);
    });
  });
}
