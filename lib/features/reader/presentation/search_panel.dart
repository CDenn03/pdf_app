import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:pdf_app/shared/widgets/overlay_panel.dart';

/// Shows the in-document text search panel as a bottom sheet.
///
/// The sheet is non-dismissible so the user can scroll the PDF to see
/// highlighted matches without accidentally closing the panel.
Future<void> showSearchPanel({
  required BuildContext context,
  required PdfViewerController pdfController,
}) {
  return OverlayPanel.show(
    context: context,
    title: 'Search',
    isDismissible: false,
    builder: (ctx) => _SearchPanelContent(pdfController: pdfController),
  );
}

class _SearchPanelContent extends StatefulWidget {
  const _SearchPanelContent({required this.pdfController});

  final PdfViewerController pdfController;

  @override
  State<_SearchPanelContent> createState() => _SearchPanelContentState();
}

class _SearchPanelContentState extends State<_SearchPanelContent> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();

  PdfTextSearcher? _searcher;
  int _matchCount = 0;
  int _currentMatch = 0;
  bool _searching = false;

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    _searcher?.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _searcher?.dispose();
      setState(() {
        _searcher = null;
        _matchCount = 0;
        _currentMatch = 0;
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);

    _searcher?.dispose();
    final searcher = PdfTextSearcher(widget.pdfController);
    _searcher = searcher;

    searcher.addListener(() {
      if (!mounted) return;
      setState(() {
        _matchCount = searcher.matches.length;
        _currentMatch = (searcher.currentIndex ?? -1) + 1;
        _searching = searcher.isSearching;
      });
    });

    searcher.startTextSearch(query.trim());
    if (mounted) setState(() => _searching = false);
  }

  void _submit() {
    _focusNode.unfocus();
    _search(_queryController.text);
  }

  Future<void> _previous() async {
    await _searcher?.goToPrevMatch();
    if (mounted) {
      setState(() => _currentMatch = (_searcher?.currentIndex ?? -1) + 1);
    }
  }

  Future<void> _next() async {
    await _searcher?.goToNextMatch();
    if (mounted) {
      setState(() => _currentMatch = (_searcher?.currentIndex ?? -1) + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResults = _matchCount > 0;
    final noResults = _searcher != null && _matchCount == 0 && !_searching;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        top: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  focusNode: _focusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search in document…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                    suffixIcon: _queryController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _queryController.clear();
                              _search('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}), // rebuild suffix icon
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searching ? null : _submit,
                child: const Text('Go'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator.adaptive(),
            )
          else if (noResults)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No results found.',
                style: theme.textTheme.bodySmall,
              ),
            )
          else if (hasResults)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_currentMatch of $_matchCount results',
                  style: theme.textTheme.bodySmall,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 20),
                      onPressed: _previous,
                      tooltip: 'Previous',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 20),
                      onPressed: _next,
                      tooltip: 'Next',
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
