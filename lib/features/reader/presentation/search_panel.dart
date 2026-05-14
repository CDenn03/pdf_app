import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:pdf_app/shared/widgets/overlay_panel.dart';

/// Shows the in-document text search panel as a bottom sheet.
Future<void> showSearchPanel({
  required BuildContext context,
  required PdfViewerController pdfController,
}) {
  return OverlayPanel.show(
    context: context,
    title: 'Search',
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
  PdfTextSearchResult? _result;
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _focusNode.dispose();
    _result?.clear();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    // Debounce: wait 400ms after the user stops typing before searching.
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _result?.clear();
      setState(() => _result = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    _result?.clear();
    setState(() => _searching = true);

    // searchText is synchronous — it returns a result object that updates
    // asynchronously as the viewer finds matches.
    final result = widget.pdfController.searchText(query.trim());

    // Listen for the result to populate, then jump to the first match.
    result.addListener(() {
      if (!mounted) return;
      setState(() {
        _result = result;
        _searching = false;
      });
    });

    setState(() {
      _result = result;
      _searching = false;
    });
  }

  void _submit() {
    // Dismiss keyboard, then search.
    _focusNode.unfocus();
    _debounce?.cancel();
    _search(_queryController.text);
  }

  void _previous() => _result?.previousInstance();
  void _next() => _result?.nextInstance();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    final hasResults = result != null && result.totalInstanceCount > 0;
    final noResults =
        result != null && result.totalInstanceCount == 0 && !_searching;

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
                              _result?.clear();
                              setState(() => _result = null);
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    setState(() {}); // rebuild for suffix icon
                    _onQueryChanged(v);
                  },
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
                  '${result.currentInstanceIndex} of '
                  '${result.totalInstanceCount} results',
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
