import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pdf_app/features/recents/state/recents_notifier.dart';
import 'package:pdf_app/shared/widgets/selectable_file_list.dart';

/// Shows the PDFs the user has opened recently, newest first.
///
/// Long-press any item to enter multi-select mode and bulk-add to library
/// or a specific collection.
class RecentsPage extends ConsumerStatefulWidget {
  const RecentsPage({super.key, this.searchQuery = ''});

  final String searchQuery;

  @override
  ConsumerState<RecentsPage> createState() => RecentsPageState();
}

class RecentsPageState extends ConsumerState<RecentsPage> {
  final _controller = SelectableListController();

  /// Called by [HomeShell] when the user switches tabs.
  void clearSelection() => _controller.clearSelection();

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(recentsProvider);
    final theme = Theme.of(context);
    final q = widget.searchQuery.toLowerCase().trim();

    final recents = q.isEmpty
        ? all
        : all.where((e) => e.name.toLowerCase().contains(q)).toList();

    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text('No recent files', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Files you open will appear here.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (recents.isEmpty) {
      return Center(
        child: Text(
          'No results for "${widget.searchQuery}"',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return SelectableFileList(
      controller: _controller,
      entries: recents,
      showPath: false,
      onOpenFile: (entry) => context.go('/reader', extra: entry.path),
      onSelectionChanged: (_) {},
    );
  }
}
