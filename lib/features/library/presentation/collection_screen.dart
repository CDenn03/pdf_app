import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/shared/widgets/file_actions_sheet.dart';
import 'package:sefer/shared/widgets/file_list_tile.dart';

/// Shows the files in a collection, or all favorites when [isFavorites] is true.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({
    super.key,
    this.collectionId,
    this.isFavorites = false,
    this.onAddBook,
  }) : assert(
         collectionId != null || isFavorites,
         'Provide collectionId or set isFavorites',
       );

  final String? collectionId;
  final bool isFavorites;

  /// Called when the user taps the add (+) button. Only shown for collections.
  final VoidCallback? onAddBook;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(libraryEntriesProvider).value ?? [];
    final collections = ref.watch(collectionsProvider).value ?? [];

    final title = widget.isFavorites
        ? 'Favorites'
        : collections
                  .where((c) => c.id == widget.collectionId)
                  .map((c) => c.name)
                  .firstOrNull ??
              'Collection';

    final baseEntries = widget.isFavorites
        ? allEntries.where((e) => e.isFavorite).toList()
        : allEntries
              .where((e) => e.collectionId == widget.collectionId)
              .toList();

    final q = _query.toLowerCase().trim();
    final entries = q.isEmpty
        ? baseEntries
        : baseEntries.where((e) => e.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!widget.isFavorites && widget.onAddBook != null)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add book',
                  onPressed: () {
                    context.pop();
                    widget.onAddBook!();
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  q.isNotEmpty
                      ? 'No results for "$q"'
                      : widget.isFavorites
                      ? 'No favorites yet.'
                      : 'No files here yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _FileTile(
                  entry: entries[i],
                  inCollection: !widget.isFavorites,
                ),
                childCount: entries.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _FileTile extends ConsumerWidget {
  const _FileTile({required this.entry, required this.inCollection});

  final LibraryEntry entry;
  final bool inCollection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FileListTile(
      title: entry.name.replaceAll('.pdf', ''),
      gradientSeed: entry.path,
      unavailable: entry.status != FileStatus.ok,
      iconSize: 48,
      trailing: _FavoriteButton(entry: entry),
      onTap: entry.status == FileStatus.ok ? () => _open(context, ref) : null,
      onLongPress: () => showFileActionsSheet(
        context,
        ref,
        path: entry.path,
        name: entry.name,
        libraryEntryId: entry.id,
        status: entry.status,
        removeFromCollectionId: inCollection ? entry.collectionId : null,
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    context.push('/reader', extra: ReaderRouteArguments(path: entry.path));
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        entry.isFavorite ? Icons.favorite : Icons.favorite_border,
        size: 20,
        color: entry.isFavorite
            ? AppColors.brand
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: () => ref
          .read(libraryEntriesProvider.notifier)
          .setFavoriteForPaths({entry.path}, favorite: !entry.isFavorite),
    );
  }
}
