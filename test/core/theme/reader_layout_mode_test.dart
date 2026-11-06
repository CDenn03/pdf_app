import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/theme/reader_layout_mode.dart';

void main() {
  group('decodeReaderLayoutMode', () {
    test('migrates the legacy sideBySide token to paged', () {
      expect(decodeReaderLayoutMode('sideBySide'), ReaderLayoutMode.paged);
    });

    test('reads current tokens', () {
      expect(decodeReaderLayoutMode('paged'), ReaderLayoutMode.paged);
      expect(decodeReaderLayoutMode('continuous'), ReaderLayoutMode.continuous);
      expect(decodeReaderLayoutMode('bookFlip'), ReaderLayoutMode.bookFlip);
    });

    test('falls back to paged for null and unknown tokens', () {
      expect(decodeReaderLayoutMode(null), ReaderLayoutMode.paged);
      expect(decodeReaderLayoutMode('nonsense'), ReaderLayoutMode.paged);
    });
  });

  test('every mode round-trips through its storage token', () {
    for (final mode in ReaderLayoutMode.values) {
      expect(decodeReaderLayoutMode(encodeReaderLayoutMode(mode)), mode);
    }
  });

  test('paged is labelled Swipe Pages', () {
    expect(ReaderLayoutMode.paged.label, 'Swipe Pages');
  });

  test('only continuous mode is not paginated', () {
    expect(ReaderLayoutMode.continuous.isPaginated, isFalse);
    expect(ReaderLayoutMode.paged.isPaginated, isTrue);
    expect(ReaderLayoutMode.bookFlip.isPaginated, isTrue);
  });

  test('annotation preload window is 3 continuous and 1 otherwise', () {
    expect(ReaderLayoutMode.continuous.annotationPreloadWindow, 3);
    expect(ReaderLayoutMode.paged.annotationPreloadWindow, 1);
    expect(ReaderLayoutMode.bookFlip.annotationPreloadWindow, 1);
  });
}
