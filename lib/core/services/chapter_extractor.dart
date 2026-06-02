import 'dart:developer' as developer;

import 'package:syncfusion_flutter_pdf/pdf.dart';

class DetectedChapter {
  final String title;
  final int page;
  final int depth;

  const DetectedChapter({
    required this.title,
    required this.page,
    required this.depth,
  });
}

class ChapterExtractor {
  static const int _maxPages = 300;

  static const double _fontSizeRatio = 1.35;

  static const int _maxHeadingLength = 120;

  static const int _tocSearchPages = 20;

  static List<DetectedChapter> extract(PdfDocument document) {
    try {
      final pageCount = document.pages.count;

      // Single-page document — no chapters to identify.
      if (pageCount <= 1) return [];

      final bookmarkResult = _extractBookmarks(document);

      if (bookmarkResult.isNotEmpty) {
        return bookmarkResult;
      }

      final extractor = PdfTextExtractor(document);

      final scanPages = pageCount.clamp(0, _maxPages);

      final lines = extractor.extractTextLines(
        startPageIndex: 0,
        endPageIndex: scanPages - 1,
      );

      if (lines.isEmpty) return [];

      final tocResult = _extractFromTOC(lines);

      if (tocResult.isNotEmpty) {
        return tocResult;
      }

      final repeatedTexts = _findRepeatedTexts(lines);

      final filteredLines = lines.where((line) {
        final text = _normalize(line.text);

        if (text.isEmpty) return false;

        if (repeatedTexts.contains(text)) {
          return false;
        }

        return true;
      }).toList();

      if (filteredLines.isEmpty) return [];

      final fontSizes =
          filteredLines
              .where((l) => l.fontSize > 0)
              .map((l) => l.fontSize)
              .toList()
            ..sort();

      if (fontSizes.isEmpty) return [];

      final median = fontSizes[fontSizes.length ~/ 2];
      final headingThreshold = median * _fontSizeRatio;

      final headingSizes =
          fontSizes.where((s) => s >= headingThreshold).toSet().toList()
            ..sort((a, b) => b.compareTo(a));

      final candidates = <_Candidate>[];

      for (final line in filteredLines) {
        final text = _normalize(line.text);

        if (text.isEmpty) continue;

        if (text.length > _maxHeadingLength) continue;

        if (_isBodyText(text)) continue;

        final isKeyword = _matchesHeadingKeyword(text);

        final isLargeFont = line.fontSize >= headingThreshold;

        final isBold = line.fontStyle.contains(PdfFontStyle.bold);

        if (!isKeyword && !isLargeFont && !isBold) {
          continue;
        }

        if (!isKeyword && isBold && text.length > 60) {
          continue;
        }

        int depth = 0;

        if (headingSizes.isNotEmpty) {
          final tier = headingSizes.indexWhere(
            (s) => (s - line.fontSize).abs() < 0.5,
          );

          if (tier >= 0) {
            depth = tier.clamp(0, 2);
          }
        }

        if (isKeyword && !isLargeFont) {
          depth = 0;
        }

        candidates.add(
          _Candidate(
            text: text,
            page: line.pageIndex + 1,
            depth: depth,
            fontSize: line.fontSize,
          ),
        );
      }

      final deduped = _dedupe(candidates);

      final merged = _mergeMultiLineHeadings(deduped);

      return merged
          .map(
            (c) => DetectedChapter(title: c.text, page: c.page, depth: c.depth),
          )
          .toList();
    } catch (e, s) {
      developer.log(
        'Chapter extraction failed',
        name: 'pdf_reader.chapters',
        error: e,
        stackTrace: s,
      );

      return [];
    }
  }

  // ------------------------------------------------------------
  // BOOKMARKS
  // ------------------------------------------------------------

  static List<DetectedChapter> _extractBookmarks(PdfDocument document) {
    try {
      final result = <DetectedChapter>[];

      final bookmarks = document.bookmarks;

      for (int i = 0; i < bookmarks.count; i++) {
        final bookmark = bookmarks[i];

        final destination = bookmark.destination;
        int page = 1;
        if (destination != null) {
          final idx = document.pages.indexOf(destination.page);
          if (idx >= 0) page = idx + 1;
        }

        result.add(
          DetectedChapter(title: bookmark.title.trim(), page: page, depth: 0),
        );
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  // ------------------------------------------------------------
  // TOC DETECTION
  // ------------------------------------------------------------

  static List<DetectedChapter> _extractFromTOC(List<dynamic> lines) {
    final pages = <int, List<String>>{};

    for (final line in lines) {
      final page = line.pageIndex + 1;
      pages.putIfAbsent(page, () => []);
      pages[page]!.add(_normalize(line.text));
    }

    final maxPage = pages.keys.fold<int>(0, (a, b) => a > b ? a : b);
    final searchUntil = maxPage < _tocSearchPages ? maxPage : _tocSearchPages;

    for (int page = 1; page <= searchUntil; page++) {
      final pageLines = pages[page];
      if (pageLines == null || pageLines.isEmpty) continue;
      if (!_looksLikeTOCPage(pageLines)) continue;

      final raw = <_RawTocEntry>[];
      for (final line in pageLines) {
        final parsed = _parseTOCEntry(line);
        if (parsed != null) raw.add(parsed);
      }

      if (raw.length < 3) continue;

      // Merge "Chapter N" label-only lines with the following subtitle.
      // e.g. ["Chapter 2", p=8] + ["Your Conscience", p=9]
      //   → ["Chapter 2 Your Conscience", p=9]
      final merged = <_RawTocEntry>[];
      final labelOnly = RegExp(
        r'^(chapter|part|section|unit)\s*\d*$',
        caseSensitive: false,
      );
      int i = 0;
      while (i < raw.length) {
        final current = raw[i];
        if (labelOnly.hasMatch(current.title) && i + 1 < raw.length) {
          final next = raw[i + 1];
          merged.add(
            _RawTocEntry(
              title: '${current.title} ${next.title}'.trim(),
              page: next.page,
            ),
          );
          i += 2;
        } else {
          merged.add(current);
          i++;
        }
      }

      // Drop any remaining bare label entries (e.g. a lone "Chapter" with
      // no following subtitle).
      final chapters = merged
          .where((e) => !labelOnly.hasMatch(e.title.trim()))
          .map((e) => DetectedChapter(title: e.title, page: e.page, depth: 0))
          .toList();

      if (chapters.length < 3) continue;

      final offset = _detectPageOffset(pages, maxPage);
      if (offset == 0) return chapters;

      return chapters
          .map(
            (c) => DetectedChapter(
              title: c.title,
              page: (c.page + offset).clamp(1, maxPage),
              depth: c.depth,
            ),
          )
          .toList();
    }

    return [];
  }

  /// Returns the number to add to a printed page number to get the PDF
  /// page index (1-based).
  ///
  /// Scans pages looking for a short standalone number that matches the
  /// expected printed sequence (e.g. a page whose PDF index is 5 shows
  /// the text "1" → offset = 4). Returns 0 if it cannot determine the
  /// offset.
  static int _detectPageOffset(Map<int, List<String>> pages, int maxPage) {
    final scanUntil = maxPage.clamp(0, 50);

    for (int pdfPage = 1; pdfPage <= scanUntil; pdfPage++) {
      final pageLines = pages[pdfPage];
      if (pageLines == null) continue;

      for (final line in pageLines) {
        final trimmed = line.trim();
        // Look for an isolated small integer (likely a printed page number).
        if (!RegExp(r'^\d{1,4}$').hasMatch(trimmed)) continue;
        final printed = int.tryParse(trimmed);
        if (printed == null || printed < 1) continue;
        // Reasonable: printed page 1 is usually near the start.
        if (printed > 20) continue;

        final offset = pdfPage - printed;
        if (offset > 0) return offset;
      }
    }

    return 0;
  }

  static bool _looksLikeTOCPage(List<String> lines) {
    int score = 0;

    for (final line in lines) {
      final lower = line.toLowerCase();

      if (_tocKeywords.any(lower.contains)) {
        score += 3;
      }

      if (RegExp(r'.+\s+\d+$').hasMatch(line)) {
        score++;
      }

      if (RegExp(r'.+\.{2,}\s+\d+$').hasMatch(line)) {
        score += 2;
      }
    }

    return score >= 8;
  }

  static _RawTocEntry? _parseTOCEntry(String line) {
    // Require at least 2 spaces or dots before the page number so that
    // single-space word boundaries inside a title don't get split off.
    final match = RegExp(r'^(.+?)(?:\.{2,}|\s{2,})\s*(\d+)$').firstMatch(line);

    if (match == null) return null;

    final title = match.group(1)?.trim();
    final page = int.tryParse(match.group(2) ?? '');

    if (title == null || title.isEmpty || page == null) return null;

    return _RawTocEntry(title: title, page: page);
  }

  // ------------------------------------------------------------
  // HEADER / FOOTER DETECTION
  // ------------------------------------------------------------

  static Set<String> _findRepeatedTexts(List<dynamic> lines) {
    final frequency = <String, int>{};

    for (final line in lines) {
      final text = _normalize(line.text);

      if (text.length < 2) continue;

      frequency[text] = (frequency[text] ?? 0) + 1;
    }

    return frequency.entries
        .where((e) => e.value >= 5)
        .map((e) => e.key)
        .toSet();
  }

  // ------------------------------------------------------------
  // HEADING DETECTION
  // ------------------------------------------------------------

  static bool _isBodyText(String text) {
    if (text.isEmpty) return true;

    if (RegExp(r'^\d+$').hasMatch(text)) {
      return true;
    }

    if (text.length > 100) {
      return true;
    }

    if (text.contains('://')) {
      return true;
    }

    if (text.endsWith('.') && text.length > 30) {
      return true;
    }

    final wordCount = text.split(RegExp(r'\s+')).length;

    if (wordCount > 18) {
      return true;
    }

    return false;
  }

  static bool _matchesHeadingKeyword(String text) {
    final lower = text.toLowerCase();

    for (final keyword in _headingKeywords) {
      if (lower.startsWith(keyword)) {
        return true;
      }
    }

    if (RegExp(
      r'^(chapter|part|section|unit|lesson|module|topic)\s+\d+',
      caseSensitive: false,
    ).hasMatch(text)) {
      return true;
    }

    if (RegExp(r'^\d+(\.\d+)*\s+[A-Z]').hasMatch(text)) {
      return true;
    }

    return false;
  }

  // ------------------------------------------------------------
  // DEDUPE
  // ------------------------------------------------------------

  static List<_Candidate> _dedupe(List<_Candidate> input) {
    final result = <_Candidate>[];

    for (final item in input) {
      if (result.isNotEmpty &&
          result.last.text == item.text &&
          result.last.page == item.page) {
        continue;
      }

      result.add(item);
    }

    return result;
  }

  // ------------------------------------------------------------
  // MERGING
  // ------------------------------------------------------------

  static List<_Candidate> _mergeMultiLineHeadings(List<_Candidate> input) {
    if (input.length <= 1) {
      return input;
    }

    final result = <_Candidate>[];

    int i = 0;

    while (i < input.length) {
      final current = input[i];

      if (i + 1 < input.length) {
        final next = input[i + 1];

        final looksLikeTOC =
            RegExp(r'\d+$').hasMatch(current.text) ||
            RegExp(r'\d+$').hasMatch(next.text);

        final samePage = current.page == next.page;

        final sameDepth = current.depth == next.depth;

        final similarSize = (current.fontSize - next.fontSize).abs() < 0.5;

        if (!looksLikeTOC && samePage && sameDepth && similarSize) {
          final mergedText = '${current.text} ${next.text}';

          if (mergedText.length <= _maxHeadingLength) {
            result.add(
              _Candidate(
                text: mergedText,
                page: current.page,
                depth: current.depth,
                fontSize: current.fontSize,
              ),
            );

            i += 2;
            continue;
          }
        }
      }

      result.add(current);
      i++;
    }

    return result;
  }

  static String _normalize(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const _tocKeywords = [
    'contents',
    'table of contents',
    'chapters',
    'toc',
    'outline',
    'roadmap',
    'inside this book',
    'at a glance',
  ];

  static const _headingKeywords = [
    'chapter',
    'part',
    'section',
    'appendix',
    'introduction',
    'conclusion',
    'preface',
    'foreword',
    'afterword',
    'prologue',
    'epilogue',
    'summary',
    'lesson',
    'unit',
    'module',
    'topic',
    'references',
    'bibliography',
    'glossary',
    'index',
  ];
}

class _Candidate {
  final String text;
  final int page;
  final int depth;
  final double fontSize;

  const _Candidate({
    required this.text,
    required this.page,
    required this.depth,
    required this.fontSize,
  });
}

class _RawTocEntry {
  final String title;
  final int page;

  const _RawTocEntry({required this.title, required this.page});
}
