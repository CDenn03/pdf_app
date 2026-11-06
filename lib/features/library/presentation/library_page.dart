import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/library/presentation/collection_dialogs.dart';
import 'package:sefer/features/library/presentation/library_collection_grid.dart';
import 'package:sefer/features/library/presentation/library_empty_state.dart';
import 'package:sefer/features/library/presentation/library_entry_tile.dart';
import 'package:sefer/features/library/presentation/library_recents_section.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({
    super.key,
    this.bottomPadding = 0,
    this.onAddToCollection,
  });

  final double bottomPadding;
  final void Function(String collectionId)? onAddToCollection;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    // .value ?? [] gracefully handles AsyncNotifier loading/error states (#16).
    final entries = ref.watch(libraryEntriesProvider).value ?? [];
    final collections = ref.watch(collectionsProvider).value ?? [];
    final recents = ref.watch(recentsProvider);
    final q = _query.toLowerCase().trim();
    final searching = q.isNotEmpty;
    final results = searching
        ? entries.where((e) => e.name.toLowerCase().contains(q)).toList()
        : const <LibraryEntry>[];

    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSearch();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GreetingHeader(subtitle: timeGreeting, title: 'Library'),
          ),
          SliverToBoxAdapter(
            child: PageSearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              hintText: 'Search library…',
            ),
          ),
          if (searching)
            ..._searchSlivers(context, q, results)
          else
            ..._browseSlivers(entries, collections, recents),
          SliverToBoxAdapter(
            child: SizedBox(height: widget.bottomPadding + AppSpacing.sm),
          ),
        ],
      ),
    );
  }

  List<Widget> _searchSlivers(
    BuildContext context,
    String query,
    List<LibraryEntry> results,
  ) {
    if (results.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              'No results for "$query"',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => LibraryEntryTile(entry: results[i]),
          childCount: results.length,
        ),
      ),
    ];
  }

  List<Widget> _browseSlivers(
    List<LibraryEntry> entries,
    List<PdfCollection> collections,
    List<RecentEntry> recents,
  ) {
    return [
      if (recents.isNotEmpty)
        SliverToBoxAdapter(
          child: RecentFilesSection(recents: recents.take(6).toList()),
        ),
      SliverToBoxAdapter(child: _CollectionsHeader(onNew: _createCollection)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.sm,
        ),
        sliver: CollectionGrid(
          collections: collections,
          entries: entries,
          onAddToCollection: widget.onAddToCollection,
        ),
      ),
      if (entries.isEmpty && collections.isEmpty && recents.isEmpty)
        SliverFillRemaining(
          child: LibraryEmptyState(bottomPadding: widget.bottomPadding),
        ),
    ];
  }

  Future<void> _createCollection() async {
    final name = await showCollectionNameDialog(
      context,
      title: 'New collection',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(collectionsProvider.notifier).addCollection(name.trim());
  }
}

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'COLLECTIONS',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          TextButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New'),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
          ),
        ],
      ),
    );
  }
}
