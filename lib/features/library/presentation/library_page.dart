import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/home/presentation/page_headers.dart';
import 'package:sefer/features/library/domain/annotation_search.dart';
import 'package:sefer/features/library/presentation/collection_dialogs.dart';
import 'package:sefer/features/library/presentation/collection_filter_bar.dart';
import 'package:sefer/features/library/presentation/library_collection_grid.dart';
import 'package:sefer/features/library/presentation/library_empty_state.dart';
import 'package:sefer/features/library/presentation/library_search_results.dart';
import 'package:sefer/features/library/presentation/library_recents_section.dart';
import 'package:sefer/features/library/state/annotation_search_provider.dart';
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
  LibrarySearchFilter _filter = const SearchAllBooks();

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
    final scopedEntries = applyLibrarySearchFilter(entries, _filter).toList();
    final bookResults = searching
        ? scopedEntries.where((e) => e.name.toLowerCase().contains(q)).toList()
        : const <LibraryEntry>[];
    final annotationAsync = searching
        ? ref.watch(annotationSearchProvider(q))
        : null;
    final annotationHits = annotationAsync == null
        ? const <AnnotationSearchHit>[]
        : resolveAnnotationHits(
            rows: annotationAsync.value ?? const [],
            entries: entries,
            collections: collections,
            filter: _filter,
          );

    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSearch();
      },
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: GreetingHeader()),
          SliverToBoxAdapter(
            child: PageSearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              hintText: 'Search books and notes…',
            ),
          ),
          if (searching)
            SliverToBoxAdapter(
              child: CollectionFilterBar(
                collections: collections,
                filter: _filter,
                showFavorites: entries.any((e) => e.isFavorite),
                onFilterSelected: (next) => setState(() => _filter = next),
              ),
            ),
          if (searching)
            ...librarySearchSlivers(
              context: context,
              query: q,
              books: bookResults,
              annotationHits: annotationHits,
              annotationsLoading: annotationAsync?.isLoading ?? false,
              annotationsError: annotationAsync?.hasError ?? false,
            )
          else
            ..._browseSlivers(entries, collections, recents),
          SliverToBoxAdapter(
            child: SizedBox(height: widget.bottomPadding + AppSpacing.sm),
          ),
        ],
      ),
    );
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
