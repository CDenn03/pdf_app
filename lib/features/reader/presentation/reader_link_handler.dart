import 'dart:async';

import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/domain/external_link_opener.dart';
import 'package:sefer/features/reader/domain/reader_page_navigation.dart';

PdfLinkHandlerParams readerLinkHandlerParams({
  required ReaderPageNavigation navigation,
  required ExternalLinkOpener linkOpener,
}) => PdfLinkHandlerParams(
  onLinkTap: (link) {
    final destination = link.dest;
    final uri = link.url;
    if (destination != null) {
      unawaited(navigation.goToPage(destination.pageNumber));
    } else if (uri != null) {
      unawaited(linkOpener.open(uri));
    }
  },
);
