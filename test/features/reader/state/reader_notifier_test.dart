import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_app/features/reader/state/reader_notifier.dart';
import 'package:pdf_app/features/reader/state/reader_state.dart';

void main() {
  late ReaderNotifier notifier;

  setUp(() => notifier = ReaderNotifier());
  tearDown(() => notifier.dispose());

  test('initial state has sensible defaults', () {
    expect(notifier.state, const ReaderState());
    expect(notifier.state.isLoaded, false);
    expect(notifier.state.currentPage, 1);
  });

  group('onDocumentLoaded', () {
    test('sets pdfId, totalPages and isLoaded', () {
      notifier.onDocumentLoaded(pdfId: 'abc', totalPages: 10);
      expect(notifier.state.pdfId, 'abc');
      expect(notifier.state.totalPages, 10);
      expect(notifier.state.isLoaded, true);
      expect(notifier.state.currentPage, 1);
    });
  });

  group('onPageChanged', () {
    test('updates currentPage', () {
      notifier.onPageChanged(5);
      expect(notifier.state.currentPage, 5);
    });
  });
}
