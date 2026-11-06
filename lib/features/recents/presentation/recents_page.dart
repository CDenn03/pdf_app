import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/presentation/recent_actions_sheet.dart';
import 'package:sefer/features/recents/presentation/recent_tile.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/shared/state/document_selection_controller.dart';
import 'package:sefer/shared/widgets/selection_action_bar.dart';

/// Shows all PDFs the user has opened recently, newest first.
/// Includes files from outside the library.
///
/// [initialSelectedPath] opens the page already in selection mode.
class RecentsPage extends ConsumerStatefulWidget {
  const RecentsPage({super.key, this.initialSelectedPath});

  final String? initialSelectedPath;

  @override
  ConsumerState<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends ConsumerState<RecentsPage> {
  final _selection = DocumentSelectionController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelectedPath;
    if (initial != null) _selection.select(initial);
    _selection.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  void _toggleAll(List<RecentEntry> recents) {
    final paths = recents.map((e) => e.path);
    if (paths.every(_selection.isSelected)) {
      _selection.clear();
    } else {
      _selection.selectVisible(paths);
    }
  }

  Future<void> _setFavorite(bool favorite) async {
    await ref
        .read(libraryEntriesProvider.notifier)
        .setFavoriteForPaths(_selection.selectedPaths, favorite: favorite);
    _selection.clear();
  }

  void _onTap(RecentEntry entry) {
    if (_selection.isSelecting) {
      _selection.toggle(entry.path);
      return;
    }
    context.push('/reader', extra: ReaderRouteArguments(path: entry.path));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recentsProvider, (_, next) {
      _selection.retainExisting(next.map((e) => e.path));
    });
    final recents = ref.watch(recentsProvider);
    final favoritePaths = ref.watch(favoritePathsProvider);
    final selecting = _selection.isSelecting;

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selection.clear();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            selecting
                ? '${_selection.selectedPaths.length} selected'
                : 'Recently opened',
          ),
          actions: [
            if (selecting) ...[
              TextButton(
                onPressed: () => _toggleAll(recents),
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed: _selection.clear,
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
        body: recents.isEmpty
            ? const _EmptyRecents()
            : ListView.builder(
                itemCount: recents.length,
                itemBuilder: (_, i) {
                  final entry = recents[i];
                  return RecentTile(
                    entry: entry,
                    isFavorite: favoritePaths.contains(entry.path),
                    isSelected: _selection.isSelected(entry.path),
                    selecting: selecting,
                    onTap: () => _onTap(entry),
                    onLongPress: () => _selection.select(entry.path),
                    onOverflow: () =>
                        showRecentActionsSheet(context, ref, entry),
                  );
                },
              ),
        bottomNavigationBar: selecting
            ? SafeArea(
                child: SelectionActionBar(
                  selectedPaths: _selection.selectedPaths,
                  favoritePaths: favoritePaths,
                  onSetFavorite: _setFavorite,
                ),
              )
            : null,
      ),
    );
  }
}

class _EmptyRecents extends StatelessWidget {
  const _EmptyRecents();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 48, color: secondary),
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
}
