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
  static const int _tocSearchPages = 25;

  // Session-level cache: document instance → extracted chapters.
  static final Expando<List<DetectedChapter>> _cache = Expando();

  static List<DetectedChapter> extract(PdfDocument document) {
    final cached = _cache[document];
    if (cached != null) return cached;

    final result = _doExtract(document);
    _cache[document] = result;
    return result;
  }

  static List<DetectedChapter> _doExtract(PdfDocument document) {
    try {
      final pageCount = document.pages.count;
      if (pageCount <= 1) return [];

      // 1. Embedded bookmarks are most reliable.
      final bookmarks = _extractBookmarks(document);
      if (bookmarks.isNotEmpty) return bookmarks;

      final extractor = PdfTextExtractor(document);
      final scanPages = pageCount.clamp(0, _maxPages);
      final lines = extractor.extractTextLines(
        startPageIndex: 0,
        endPageIndex: scanPages - 1,
      );
      if (lines.isEmpty) return [];

      // Group lines by page for TOC detection.
      final byPage = <int, List<String>>{};
      for (final line in lines) {
        final page = line.pageIndex + 1;
        byPage.putIfAbsent(page, () => []).add(line.text);
      }

      // 2. Try to parse a Table of Contents page.
      final tocResult = _extractFromTOC(byPage, pageCount);
      if (tocResult.isNotEmpty) return tocResult;

      // 3. Fall back to font/style heuristics, skipping TOC pages.
      return _extractByHeuristics(lines, byPage, pageCount);
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

  // ------------------------------------------------------------------
  // BOOKMARKS
  // ------------------------------------------------------------------

  static List<DetectedChapter> _extractBookmarks(PdfDocument document) {
    try {
      final result = <DetectedChapter>[];
      final bookmarks = document.bookmarks;
      for (int i = 0; i < bookmarks.count; i++) {
        final bm = bookmarks[i];
        int page = 1;
        final dest = bm.destination;
        if (dest != null) {
          final idx = document.pages.indexOf(dest.page);
          if (idx >= 0) page = idx + 1;
        }
        result.add(DetectedChapter(title: bm.title.trim(), page: page, depth: 0));
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ------------------------------------------------------------------
  // TOC DETECTION
  // ------------------------------------------------------------------

  static List<DetectedChapter> _extractFromTOC(
    Map<int, List<String>> byPage,
    int maxPage,
  ) {
    final searchUntil = maxPage.clamp(0, _tocSearchPages);

    for (int pdfPage = 1; pdfPage <= searchUntil; pdfPage++) {
      final pageLines = byPage[pdfPage];
      if (pageLines == null || pageLines.isEmpty) continue;
      if (!_looksLikeTOCPage(pageLines)) continue;

      final raw = <_RawTocEntry>[];
      for (final line in pageLines) {
        final entry = _parseTOCLine(line);
        if (entry != null) raw.add(entry);
      }
      if (raw.length < 3) continue;

      // Merge bare "Chapter N" lines with the next subtitle line.
      final merged = _mergeLabelOnlyEntries(raw);

      if (merged.length < 3) continue;

      // Calculate offset from printed page numbers to PDF page numbers.
      final offset = _calcOffset(byPage, merged, maxPage);

      return merged.map((e) {
        final realPage = (e.page + offset).clamp(1, maxPage);
        return DetectedChapter(title: e.title, page: realPage, depth: 0);
      }).toList();
    }

    return [];
  }

  /// Parse a single line from a TOC page.
  ///
  /// Handles these formats:
  ///   "Chapter 1  Your Conscience    3"
  ///   "Introduction ............. 1"
  ///   "Chapter 2 His Word 9"  (single space, trailing number)
  static _RawTocEntry? _parseTOCLine(String rawLine) {
    final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (line.isEmpty) return null;

    // Strip leading dots/dashes used as leaders.
    final noLeaders = line.replaceAll(RegExp(r'[.\-–—]{2,}'), ' ');

    // Match: title (anything) followed by whitespace and a trailing number.
    final match = RegExp(r'^(.+?)\s+(\d{1,4})$').firstMatch(noLeaders.trim());
    if (match == null) return null;

    final title = match.group(1)!.trim();
    final page = int.tryParse(match.group(2)!);

    if (title.isEmpty || page == null || page < 1) return null;

    // Reject lines that are just a number (e.g. a lone page number row).
    if (RegExp(r'^\d+$').hasMatch(title)) return null;

    // Reject very long lines — unlikely to be TOC entries.
    if (title.length > _maxHeadingLength) return null;

    return _RawTocEntry(title: title, page: page);
  }

  static List<_RawTocEntry> _mergeLabelOnlyEntries(List<_RawTocEntry> raw) {
    final labelOnly = RegExp(
      r'^(chapter|part|section|unit)\s*\d*$',
      caseSensitive: false,
    );
    final result = <_RawTocEntry>[];
    int i = 0;
    while (i < raw.length) {
      final cur = raw[i];
      if (labelOnly.hasMatch(cur.title) && i + 1 < raw.length) {
        final next = raw[i + 1];
        result.add(_RawTocEntry(
          title: '${cur.title} ${next.title}'.trim(),
          page: next.page,
        ));
        i += 2;
      } else {
        result.add(cur);
        i++;
      }
    }
    // Remove any remaining bare label entries.
    return result.where((e) => !labelOnly.hasMatch(e.title)).toList();
  }

  /// Calculates offset to add to a printed page number to get the PDF page.
  ///
  /// Strategy: look at the first TOC entry whose title appears verbatim as
  /// a heading on some nearby PDF page. The difference between that PDF page
  /// and the printed page is the offset.
  static int _calcOffset(
    Map<int, List<String>> byPage,
    List<_RawTocEntry> entries,
    int maxPage,
  ) {
    // Build a map: normalised heading text → list of PDF pages it appears on.
    final headingPages = <String, List<int>>{};
    for (final e in byPage.entries) {
      for (final line in e.value) {
        final norm = _norm(line);
        if (norm.length >= 3) {
          headingPages.putIfAbsent(norm, () => []).add(e.key);
        }
      }
    }

    for (final entry in entries) {
      final norm = _norm(entry.title);
      final hits = headingPages[norm];
      if (hits == null || hits.isEmpty) continue;

      // Pick the hit closest to where we expect (printed page + rough guess).
      for (final hit in hits) {
        final offset = hit - entry.page;
        // Sanity: offset should be non-negative and not huge.
        if (offset >= 0 && offset <= maxPage) return offset;
      }
    }

    // Fallback: scan early pages for isolated small numbers.
    for (int pdf = 1; pdf <= maxPage.clamp(0, 50); pdf++) {
      for (final line in byPage[pdf] ?? []) {
        final t = line.trim();
        if (!RegExp(r'^\d{1,3}$').hasMatch(t)) continue;
        final printed = int.tryParse(t);
        if (printed == null || printed < 1 || printed > 20) continue;
        final offset = pdf - printed;
        if (offset > 0) return offset;
      }
    }

    return 0;
  }

  static bool _looksLikeTOCPage(List<String> lines) {
    int score = 0;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_tocKeywords.any((k) => lower.contains(k))) score += 3;
      // Line ends with a number (page ref).
      if (RegExp(r'\d+\s*$').hasMatch(line.trim())) score++;
      // Has dot leaders.
      if (line.contains('...') || line.contains('···')) score += 2;
    }
    return score >= 6;
  }

  // ------------------------------------------------------------------
  // HEURISTIC FONT-BASED DETECTION
  // ------------------------------------------------------------------

  static List<DetectedChapter> _extractByHeuristics(
    List<dynamic> lines,
    Map<int, List<String>> byPage,
    int maxPage,
  ) {
    // Detect which PDF pages are TOC pages so we can skip them.
    final tocPages = <int>{};
    for (int p = 1; p <= maxPage.clamp(0, _tocSearchPages); p++) {
      if (_looksLikeTOCPage(byPage[p] ?? [])) tocPages.add(p);
    }

    final repeated = _findRepeatedTexts(lines);

    final filtered = lines.where((line) {
      if (tocPages.contains(line.pageIndex + 1)) return false;
      final text = _norm(line.text);
      return text.isNotEmpty && !repeated.contains(text);
    }).toList();

    if (filtered.isEmpty) return [];

    final sizes = filtered
        .where((l) => l.fontSize > 0)
        .map<double>((l) => l.fontSize as double)
        .toList()
      ..sort();
    if (sizes.isEmpty) return [];

    final median = sizes[sizes.length ~/ 2];
    final threshold = median * _fontSizeRatio;

    final headingSizes = sizes.where((s) => s >= threshold).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    final candidates = <_Candidate>[];

    for (final line in filtered) {
      final text = _norm(line.text);
      if (text.isEmpty || text.length > _maxHeadingLength) continue;
      if (_isBodyText(text)) continue;

      final isKeyword = _matchesHeadingKeyword(text);
      final isLargeFont = line.fontSize >= threshold;
      final isBold = (line.fontStyle as List).contains(PdfFontStyle.bold);

      if (!isKeyword && !isLargeFont && !isBold) continue;
      if (!isKeyword && isBold && text.length > 60) continue;

      int depth = 0;
      if (headingSizes.isNotEmpty) {
        final tier = headingSizes.indexWhere(
          (s) => (s - (line.fontSize as double)).abs() < 0.5,
        );
        if (tier >= 0) depth = tier.clamp(0, 2);
      }
      if (isKeyword && !isLargeFont) depth = 0;

      candidates.add(_Candidate(
        text: text,
        page: line.pageIndex + 1,
        depth: depth,
        fontSize: line.fontSize as double,
      ));
    }

    final deduped = _dedupe(candidates);
    final merged = _mergeMultiLineHeadings(deduped);

    return merged
        .map((c) => DetectedChapter(title: c.text, page: c.page, depth: c.depth))
        .toList();
  }

  // ------------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------------

  static Set<String> _findRepeatedTexts(List<dynamic> lines) {
    final freq = <String, int>{};
    for (final l in lines) {
      final t = _norm(l.text);
      if (t.length >= 2) freq[t] = (freq[t] ?? 0) + 1;
    }
    return freq.entries.where((e) => e.value >= 5).map((e) => e.key).toSet();
  }

  static bool _isBodyText(String text) {
    if (RegExp(r'^\d+$').hasMatch(text)) return true;
    if (text.length > 100) return true;
    if (text.contains('://')) return true;
    if (text.endsWith('.') && text.length > 30) return true;
    if (text.split(RegExp(r'\s+')).length > 18) return true;
    return false;
  }

  static bool _matchesHeadingKeyword(String text) {
    final lower = text.toLowerCase();
    for (final kw in _headingKeywords) {
      if (lower.startsWith(kw)) return true;
    }
    if (RegExp(
      r'^(chapter|part|section|unit|lesson|module|topic)\s+\d+',
      caseSensitive: false,
    ).hasMatch(text)) { return true; }
    if (RegExp(r'^\d+(\.\d+)*\s+[A-Z]').hasMatch(text)) { return true; }
    return false;
  }

  static List<_Candidate> _dedupe(List<_Candidate> input) {
    final result = <_Candidate>[];
    for (final item in input) {
      if (result.isNotEmpty &&
          result.last.text == item.text &&
          result.last.page == item.page) { continue; }
      result.add(item);
    }
    return result;
  }

  static List<_Candidate> _mergeMultiLineHeadings(List<_Candidate> input) {
    if (input.length <= 1) return input;
    final result = <_Candidate>[];
    int i = 0;
    while (i < input.length) {
      final cur = input[i];
      if (i + 1 < input.length) {
        final next = input[i + 1];
        final samePage = cur.page == next.page;
        final sameDepth = cur.depth == next.depth;
        final similarSize = (cur.fontSize - next.fontSize).abs() < 0.5;
        final merged = '${cur.text} ${next.text}';
        if (samePage && sameDepth && similarSize &&
            merged.length <= _maxHeadingLength) {
          result.add(_Candidate(
            text: merged,
            page: cur.page,
            depth: cur.depth,
            fontSize: cur.fontSize,
          ));
          i += 2;
          continue;
        }
      }
      result.add(cur);
      i++;
    }
    return result;
  }

  static String _norm(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static const _tocKeywords = [
    'contents',
    'table of contents',
    'chapters',
    'toc',
    'outline',
    'inside this book',
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
