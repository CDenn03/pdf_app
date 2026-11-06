import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/initial_page_report_filter.dart';

void main() {
  test('drops the viewer initial page-1 report when resuming later', () {
    final filter = InitialPageReportFilter(initialPage: 7);

    expect(filter.shouldForward(1), isFalse);
  });

  test('forwards page 1 once the viewer has reported another page', () {
    final filter = InitialPageReportFilter(initialPage: 7)..shouldForward(7);

    expect(filter.shouldForward(1), isTrue);
  });

  test('forwards page 1 when the document opens on page 1', () {
    final filter = InitialPageReportFilter(initialPage: 1);

    expect(filter.shouldForward(1), isTrue);
  });

  test('forwards a null report without settling the filter', () {
    final filter = InitialPageReportFilter(initialPage: 7);

    expect(filter.shouldForward(null), isTrue);
    expect(filter.shouldForward(1), isFalse);
  });
}
