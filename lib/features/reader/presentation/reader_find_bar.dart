import 'package:flutter/material.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/presentation/reader_search_controller.dart';

/// Browser-style find bar docked under the app bar.
///
/// Non-modal: the viewer stays fully interactive while it is open. It drives
/// its own match jumps with a margin large enough to clear the find chrome,
/// since pdfrx's own `goToMatch` centres a match with a flat margin and knows
/// nothing about this bar.
class ReaderFindBar extends StatefulWidget {
  const ReaderFindBar({
    super.key,
    required this.search,
    required this.readingMode,
    required this.onClose,
  });

  final ReaderSearchController search;
  final ReadingMode readingMode;
  final VoidCallback onClose;

  @override
  State<ReaderFindBar> createState() => _ReaderFindBarState();
}

class _ReaderFindBarState extends State<ReaderFindBar> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  bool _expanded = false;

  static const _jumpMargin = 120.0;

  @override
  void initState() {
    super.initState();
    widget.search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.search.removeListener(_onSearchChanged);
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  int get _matchCount => widget.search.matches.length;
  int get _currentIndex => widget.search.currentIndex ?? -1;

  void _search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      widget.search.resetTextSearch();
      setState(() => _expanded = false);
      return;
    }
    widget.search.startTextSearch(trimmed);
  }

  Future<void> _jumpTo(int index) =>
      widget.search.goToMatchAt(index, chromeMargin: _jumpMargin);

  Future<void> _previous() async {
    if (_matchCount == 0) return;
    final next = _currentIndex <= 0 ? _matchCount - 1 : _currentIndex - 1;
    await _jumpTo(next);
  }

  Future<void> _next() async {
    if (_matchCount == 0) return;
    final next = (_currentIndex + 1) % _matchCount;
    await _jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.readingMode;
    final onSurface = mode.primaryText;
    final hasResults = _matchCount > 0;
    final searching = widget.search.isSearching;
    final counter = hasResults
        ? '${_currentIndex + 1} of $_matchCount'
        : (searching ? '…' : '0 of 0');

    return Material(
      color: mode.controlSurface,
      elevation: 2,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: TextStyle(color: onSurface),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Find in document',
                        prefixIcon:
                            Icon(Icons.search, size: 20, color: onSurface),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _search,
                      onSubmitted: (_) => _next(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    counter,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: onSurface),
                  ),
                  IconButton(
                    tooltip: 'Previous',
                    icon: Icon(Icons.keyboard_arrow_up, color: onSurface),
                    onPressed: hasResults ? _previous : null,
                  ),
                  IconButton(
                    tooltip: 'Next',
                    icon: Icon(Icons.keyboard_arrow_down, color: onSurface),
                    onPressed: hasResults ? _next : null,
                  ),
                  IconButton(
                    tooltip: _expanded ? 'Hide results' : 'Show results',
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.list,
                      color: onSurface,
                    ),
                    onPressed: hasResults
                        ? () => setState(() => _expanded = !_expanded)
                        : null,
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: onSurface),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            if (_expanded && hasResults)
              _FindResultList(
                matches: widget.search.matches,
                activeIndex: _currentIndex,
                readingMode: mode,
                onSelect: _jumpTo,
              ),
          ],
        ),
      ),
    );
  }
}

class _FindResultList extends StatelessWidget {
  const _FindResultList({
    required this.matches,
    required this.activeIndex,
    required this.readingMode,
    required this.onSelect,
  });

  final List<FindMatch> matches;
  final int activeIndex;
  final ReadingMode readingMode;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.35;
    final onSurface = readingMode.primaryText;
    final activeColor = Theme.of(context).colorScheme.primary;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: matches.length,
        itemBuilder: (context, i) {
          final match = matches[i];
          final isActive = i == activeIndex;
          return Material(
            key: ValueKey('find-result-$i'),
            color: isActive
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            child: ListTile(
              dense: true,
              selected: isActive,
              leading: Text(
                '${match.page}',
                style: TextStyle(
                  color: isActive ? activeColor : onSurface,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              title: Text(
                _snippet(match.snippet),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onSurface,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              onTap: () => onSelect(i),
            ),
          );
        },
      ),
    );
  }

  String _snippet(String text) {
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= 80) return collapsed;
    return '${collapsed.substring(0, 80)}…';
  }
}
