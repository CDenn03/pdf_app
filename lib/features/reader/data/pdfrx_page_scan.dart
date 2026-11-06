import 'dart:async';
import 'dart:developer' as developer;

import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/pdfrx_page_bounds.dart';
import 'package:sefer/features/reader/domain/excerpt_around.dart';
import 'package:sefer/features/reader/domain/reader_page_match.dart';

typedef PageMatchFinder =
    Future<List<ReaderPageMatch>> Function(int pageNumber);

Future<List<ReaderPageMatch>> findMatchesOnPage(
  PdfPage page,
  String query,
) async {
  final text = await page.loadStructuredText();
  final found = <ReaderPageMatch>[];
  await for (final range in text.allMatches(query, caseInsensitive: true)) {
    found.add(
      ReaderPageMatch(
        pageNumber: page.pageNumber,
        excerpt: excerptAround(range.pageText.fullText, range.start, range.end),
        normalizedBounds: [normalizePageBounds(range.bounds, page)],
      ),
    );
  }
  return found;
}

Stream<List<ReaderPageMatch>> scanPages({
  required int pageCount,
  required PageMatchFinder matchesOn,
}) {
  var cancelled = false;
  final output = StreamController<List<ReaderPageMatch>>();
  output.onCancel = () => cancelled = true;
  unawaited(_scan(pageCount, matchesOn, output, () => cancelled));
  return output.stream;
}

Future<void> _scan(
  int pageCount,
  PageMatchFinder matchesOn,
  StreamController<List<ReaderPageMatch>> output,
  bool Function() isCancelled,
) async {
  try {
    for (var pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
      final matches = await matchesOn(pageNumber);
      if (isCancelled()) return;
      output.add(matches);
    }
  } catch (error, stack) {
    developer.log(
      'pdfrx text scan failed',
      name: 'sefer.search',
      level: 1000,
      error: error,
      stackTrace: stack,
    );
    if (!isCancelled()) output.addError(error, stack);
  } finally {
    if (!isCancelled()) await output.close();
  }
}
