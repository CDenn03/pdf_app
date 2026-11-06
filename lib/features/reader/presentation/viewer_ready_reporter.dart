import 'dart:developer' as developer;

import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';

void reportViewerReady(ReaderViewportConfig config, PdfDocument document) {
  config.onViewerReady(document).catchError((Object e, StackTrace s) {
    developer.log(
      'onViewerReady failed',
      name: 'sefer.reader',
      level: 1000,
      error: e,
      stackTrace: s,
    );
  });
}
