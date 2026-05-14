import 'dart:developer' as developer;

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// A detected chapter or section heading.
class DetectedChapter {
  final String title;

  /// 1-based page number.
  final int page;

  /// Nesting depth: 0 = top-level chapter, 1 = section, 2 = subsection.
  final int depth;

  const DetectedChapter({
    required this.title,
    required this.page,
    required this.depth,
  });
}

/// Extracts chapter headings from a PDF document by analysing text lines.
///
/// Strategy (in priority order):
///
/// 1. **Font-size outliers** — compute the median body font size across the
///    document. Lines whose font size is significantly larger (≥ 1.4×) are
///    treated as headings. This works for the majority of well-formatted PDFs.
///
/// 2. **Bold short lines** — lines that are bold, short (≤ 80 chars), and
///    not sentence-like (no trailing period) are treated as headings when
///    font-size detection yields nothing.
///
/// 3. **Keyword patterns** — lines starting with "Chapter", "Part",
///    "Section", "Appendix", or common numbering schemes ("1.", "I.", "1.1")
///    are always included regardless of font size.
///
/// Depth is assigned by relative font size:
/// - Largest font tier → depth 0 (chapter)
/// - Second tier → depth 1 (section)
/// - Third tier → depth 2 (subsection)
///
/// Runs in a Flutter `compute` isolate — never call on the UI thread for
/// large documents.
class ChapterExtractor {
  /// Maximum pages to scan. Keeps processing time bounded for huge documents.
  static const _maxPages = 300;

  /// Minimum font size ratio above median to qualify as a heading.
  static const _fontSizeRatio = 1.35;

  /// Maximum character length for a heading line.
  static const _maxHeadingLength = 120;

  /// Extracts chapters from [document]. Returns an empty list if the
  /// document is image-based or extraction fails.
  static List<DetectedChapter> extract(PdfDocument document) {
    try {
      final extractor = PdfTextExtractor(document);
      final pageCount = document.pages.count;
      final scanPages = pageCount.clamp(0, _maxPages);

      // Extract all text lines across the scan range.
      final lines = extractor.extractTextLines(
        startPageIndex: 0,
        endPageIndex: scanPages - 1,
      );

      if (lines.isEmpty) return [];

      // --- Step 1: Compute font size statistics ---
      final sizes =
          lines
              .where((l) => l.fontSize > 0 && l.text.trim().isNotEmpty)
              .map((l) => l.fontSize)
              .toList()
            ..sort();

      if (sizes.isEmpty) return [];

      final median = sizes[sizes.length ~/ 2];
      final threshold = median * _fontSizeRatio;

      // Collect distinct font sizes that qualify as headings.
      final headingSizes = sizes.where((s) => s >= threshold).toSet().toList()
        ..sort((a, b) => b.compareTo(a)); // largest first

      // --- Step 2: Classify each line ---
      final candidates = <_Candidate>[];

      for (final line in lines) {
        final text = line.text.trim();
        if (text.isEmpty || text.length > _maxHeadingLength) continue;

        // Skip lines that look like body text (long sentences, page numbers).
        if (_isBodyText(text)) continue;

        final isBold = line.fontStyle.contains(PdfFontStyle.bold);
        final isSizeHeading = line.fontSize >= threshold;
        final isKeyword = _matchesKeywordPattern(text);

        if (!isSizeHeading && !isKeyword && !isBold) continue;
        if (!isSizeHeading && !isKeyword && isBold && text.length > 60) {
          continue; // Bold but too long — likely a bold paragraph.
        }

        // Determine depth from font size tier.
        int depth = 0;
        if (headingSizes.isNotEmpty) {
          final tierIndex = headingSizes.indexWhere(
            (s) => (s - line.fontSize).abs() < 0.5,
          );
          depth = tierIndex.clamp(0, 2);
        }

        // Keyword-only matches that aren't large font get depth 0.
        if (isKeyword && !isSizeHeading) depth = 0;

        candidates.add(
          _Candidate(
            text: text,
            page: line.pageIndex + 1, // convert to 1-based
            fontSize: line.fontSize,
            depth: depth,
          ),
        );
      }

      if (candidates.isEmpty) return [];

      // --- Step 3: Deduplicate consecutive same-page same-text entries ---
      final deduped = <_Candidate>[];
      for (final c in candidates) {
        if (deduped.isNotEmpty &&
            deduped.last.page == c.page &&
            deduped.last.text == c.text) {
          continue;
        }
        deduped.add(c);
      }

      // --- Step 4: Merge multi-line headings ---
      // If two consecutive candidates are on the same page and within
      // 2 lines of each other, merge them into one entry.
      final merged = _mergeMultiLine(deduped);

      return merged
          .map(
            (c) => DetectedChapter(title: c.text, page: c.page, depth: c.depth),
          )
          .toList();
    } catch (e, s) {
      developer.log(
        'ChapterExtractor failed',
        name: 'pdf_app.chapters',
        level: 900,
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  /// Returns true for lines that are clearly body text, not headings.
  static bool _isBodyText(String text) {
    // Pure numbers (page numbers, footnotes).
    if (RegExp(r'^\d+$').hasMatch(text)) return true;
    // Ends with a period and is longer than a short title.
    if (text.endsWith('.') && text.length > 40) return true;
    // Looks like a URL or file path.
    if (text.contains('://') || text.contains('\\')) return true;
    // Very short single characters or punctuation.
    if (text.length <= 1) return true;
    return false;
  }

  /// Returns true if the line matches a common chapter/section keyword pattern.
  static bool _matchesKeywordPattern(String text) {
    final lower = text.toLowerCase();

    // Explicit keywords.
    const keywords = [
      'chapter',
      'part ',
      'section',
      'appendix',
      'introduction',
      'conclusion',
      'preface',
      'foreword',
      'contents',
      'bibliography',
      'references',
      'index',
      'glossary',
      'abstract',
      'summary',
    ];
    for (final kw in keywords) {
      if (lower.startsWith(kw)) return true;
    }

    // Numbered patterns: "1.", "1 ", "I.", "A.", "1.1", "1.1.1"
    if (RegExp(r'^\d+[\.\s]').hasMatch(text)) return true;
    if (RegExp(r'^\d+\.\d+').hasMatch(text)) return true;
    if (RegExp(r'^[IVXivx]+[\.\s]').hasMatch(text)) return true;
    if (RegExp(r'^[A-Z][\.\s]\s').hasMatch(text)) return true;

    return false;
  }

  /// Merges consecutive candidates on the same page that appear to be
  /// a single multi-line heading (e.g. a long title split across two lines).
  static List<_Candidate> _mergeMultiLine(List<_Candidate> candidates) {
    if (candidates.length <= 1) return candidates;

    final result = <_Candidate>[];
    var i = 0;

    while (i < candidates.length) {
      final current = candidates[i];

      // Look ahead: same page, same depth, short combined length.
      if (i + 1 < candidates.length) {
        final next = candidates[i + 1];
        final combined = '${current.text} ${next.text}';
        if (next.page == current.page &&
            next.depth == current.depth &&
            combined.length <= _maxHeadingLength) {
          result.add(
            _Candidate(
              text: combined,
              page: current.page,
              fontSize: current.fontSize,
              depth: current.depth,
            ),
          );
          i += 2;
          continue;
        }
      }

      result.add(current);
      i++;
    }

    return result;
  }
}

class _Candidate {
  final String text;
  final int page;
  final double fontSize;
  final int depth;

  const _Candidate({
    required this.text,
    required this.page,
    required this.fontSize,
    required this.depth,
  });
}
