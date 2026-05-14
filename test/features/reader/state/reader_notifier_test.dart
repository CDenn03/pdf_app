import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_app/core/services/reading_progress_service.dart';
import 'package:pdf_app/features/reader/state/reader_notifier.dart';
import 'package:pdf_app/features/reader/state/reader_state.dart';

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
  late ReaderNotifier notifier;
  late _FakeProgressStore store;

  setUp(() {
    store = _FakeProgressStore();
    notifier = ReaderNotifier(progressStore: store);
  });
  tearDown(() => notifier.dispose());

  test('initial state has sensible defaults', () {
    expect(notifier.state, const ReaderState());
    expect(notifier.state.isLoaded, false);
    expect(notifier.state.currentPage, 1);
  });

  group('onDocumentLoaded', () {
    test('sets pdfId, totalPages and isLoaded', () async {
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      expect(notifier.state.pdfId, 'abc');
      expect(notifier.state.totalPages, 10);
      expect(notifier.state.isLoaded, true);
    });

    test('resumes from persisted page', () async {
      store._pages['abc'] = 7;
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      expect(notifier.state.resumePage, 7);
      expect(notifier.state.currentPage, 7);
    });

    test('clamps resume page to totalPages', () async {
      store._pages['abc'] = 99;
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      expect(notifier.state.resumePage, 10);
    });
  });

  group('onPageChanged', () {
    test('updates currentPage', () async {
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      notifier.onPageChanged(5);
      expect(notifier.state.currentPage, 5);
    });

    test('persists page to store', () async {
      await notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      notifier.onPageChanged(5);
      expect(store._pages['abc'], 5);
    });
  });
}
