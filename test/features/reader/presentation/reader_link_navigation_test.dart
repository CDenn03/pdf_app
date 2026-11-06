import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/presentation/reader_link_handler.dart';
import '../support/recording_external_link_opener.dart';
import '../support/recording_page_navigation.dart';

void main() {
  late RecordingPageNavigation navigation;
  late RecordingExternalLinkOpener linkOpener;

  setUp(() {
    navigation = RecordingPageNavigation();
    linkOpener = RecordingExternalLinkOpener();
  });

  void tap(PdfLink link) => readerLinkHandlerParams(
    navigation: navigation,
    linkOpener: linkOpener,
  ).onLinkTap(link);

  test('an internal link destination navigates to its page', () {
    const link = PdfLink([], dest: PdfDest(7, PdfDestCommand.xyz, null));

    tap(link);

    expect(navigation.requestedPages, [7]);
    expect(linkOpener.opened, isEmpty);
  });

  test('an external link is handed to the opener, not navigated', () {
    final uri = Uri.parse('https://example.com');

    tap(PdfLink(const [], url: uri));

    expect(linkOpener.opened, [uri]);
    expect(navigation.requestedPages, isEmpty);
  });

  test('a link with neither destination nor URL does nothing', () {
    tap(const PdfLink([]));

    expect(linkOpener.opened, isEmpty);
    expect(navigation.requestedPages, isEmpty);
  });
}
