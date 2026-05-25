import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' show PdfViewerController;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:pdf_app/core/services/chapter_extractor.dart';
import 'package:pdf_app/shared/widgets/overlay_panel.dart';

/// Shows the document Table of Contents as a bottom sheet.
///
/// If the document has embedded bookmarks, those are shown.
/// If not, [ChapterExtractor] scans the text and generates chapters
/// automatically. Extraction runs in a compute isolate so the UI
/// stays responsive during processing.
Future<void> showTocPanel({
  required BuildContext context,
  required PdfViewerController pdfController,
  required PdfDocument? document,
}) {
  return OverlayPanel.show(
    context: context,
    title: 'Contents',
    builder: (ctx) => _TocPanelContent(
      document: document,
      onNavigate: (page) {
        Navigator.of(ctx).pop();
        Future.delayed(
          const Duration(milliseconds: 300),
          () => pdfController.goToPage(pageNumber: page),
        );
      },
    ),
  );
}

class _TocPanelContent extends StatefulWidget {
  const _TocPanelContent({required this.document, required this.onNavigate});

  final PdfDocument? document;
  final void Function(int page) onNavigate;

  @override
  State<_TocPanelContent> createState() => _TocPanelContentState();
}

class _TocPanelContentState extends State<_TocPanelContent> {
  List<_TocEntry> _entries = [];
  bool _loading = false;
  bool _isGenerated = false; // true when chapters were auto-detected

  @override
  void initState() {
    super.initState();
    _buildEntries();
  }

  Future<void> _buildEntries() async {
    final doc = widget.document;
    if (doc == null) return;

    // --- Try embedded bookmarks first ---
    final embedded = <_TocEntry>[];
    try {
      _collectBookmarks(doc, doc.bookmarks, embedded, 0);
    } catch (e) {
      developer.log(
        'bookmark collection failed',
        name: 'pdf_app.toc',
        level: 900,
        error: e,
      );
    }

    if (embedded.isNotEmpty) {
      setState(() => _entries = embedded);
      return;
    }

    // --- No bookmarks — run auto-detection in an isolate ---
    setState(() => _loading = true);

    try {
      final chapters = await compute(ChapterExtractor.extract, doc);
      if (mounted) {
        setState(() {
          _entries = chapters
              .map(
                (c) => _TocEntry(title: c.title, page: c.page, depth: c.depth),
              )
              .toList();
          _isGenerated = _entries.isNotEmpty;
          _loading = false;
        });
      }
    } catch (e, s) {
      developer.log(
        'chapter extraction failed',
        name: 'pdf_app.toc',
        level: 900,
        error: e,
        stackTrace: s,
      );
      if (mounted) setState(() => _loading = false);
    }
  }

  void _collectBookmarks(
    PdfDocument doc,
    PdfBookmarkBase bookmarks,
    List<_TocEntry> entries,
    int depth,
  ) {
    for (var i = 0; i < bookmarks.count; i++) {
      final bookmark = bookmarks[i];
      int? page;

      try {
        final destination = bookmark.destination;
        if (destination != null) {
          final idx = doc.pages.indexOf(destination.page);
          if (idx >= 0) page = idx + 1;
        }
      } catch (_) {}

      entries.add(_TocEntry(title: bookmark.title, page: page, depth: depth));

      if (bookmark.count > 0) {
        _collectBookmarks(doc, bookmark, entries, depth + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator.adaptive(),
              SizedBox(height: 16),
              Text('Detecting chapters…'),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 40,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text('No chapters found.', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'This document has no embedded outline and no detectable headings.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner when chapters were auto-generated.
        if (_isGenerated)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chapters auto-detected — may not be exact.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Chapter list.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return _TocItem(
                entry: entry,
                onTap: entry.page != null
                    ? () => widget.onNavigate(entry.page!)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TocItem extends StatelessWidget {
  const _TocItem({required this.entry, this.onTap});

  final _TocEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indent = 20.0 + entry.depth * 16.0;

    return ListTile(
      contentPadding: EdgeInsets.only(left: indent, right: 20),
      dense: entry.depth > 0,
      enabled: entry.page != null,
      title: Text(
        entry.title,
        style: entry.depth == 0
            ? theme.textTheme.bodyMedium
            : theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
              ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: entry.page != null
          ? Text('${entry.page}', style: theme.textTheme.bodySmall)
          : null,
      onTap: onTap,
    );
  }
}

class _TocEntry {
  final String title;
  final int? page;
  final int depth;

  const _TocEntry({
    required this.title,
    required this.page,
    required this.depth,
  });
}
