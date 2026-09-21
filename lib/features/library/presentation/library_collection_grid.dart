import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/features/library/presentation/collection_dialogs.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';

class CollectionGrid extends StatelessWidget {
  const CollectionGrid({
    super.key,
    required this.collections,
    required this.entries,
    this.onAddToCollection,
  });

  final List<PdfCollection> collections;
  final List<LibraryEntry> entries;
  final void Function(String id)? onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final favCount = entries.where((e) => e.isFavorite).length;

    // Pre-compute per-collection counts once — O(n·m) rather than repeated
    // indexOf scans (#21).
    final collectionCounts = {
      for (var i = 0; i < collections.length; i++)
        i: entries.where((e) => e.collectionId == collections[i].id).length,
    };

    final cardCount = 1 + collections.length;
    final rowCount = (cardCount / 2).ceil();

    Widget cardAt(int index) {
      if (index == 0) return FavoritesCard(count: favCount);
      final colIndex = index - 1;
      final col = collections[colIndex];
      return CollectionCard(
        collection: col,
        count: collectionCounts[colIndex] ?? 0,
        colorIndex: colIndex + 1,
        onAdd:
            onAddToCollection != null ? () => onAddToCollection!(col.id) : null,
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, row) {
          final left = cardAt(row * 2);
          final rightIndex = row * 2 + 1;
          final right = rightIndex < cardCount ? cardAt(rightIndex) : null;
          final swapped = row % 2 == 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: right == null
                ? left
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: swapped
                          ? [
                              Expanded(flex: 2, child: right),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(flex: 3, child: left),
                            ]
                          : [
                              Expanded(flex: 3, child: left),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(flex: 2, child: right),
                            ],
                    ),
                  ),
          );
        },
        childCount: rowCount,
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({
    required this.title,
    required this.count,
    required this.header,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final int count;
  final Widget header;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 72, child: header),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count file${count == 1 ? '' : 's'}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesCard extends StatelessWidget {
  const FavoritesCard({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _CoverCard(
      title: 'Favorites',
      count: count,
      onTap: () => context.push('/favorites'),
      header: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.favoritesGradient,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.favorite, size: 32, color: Colors.white),
      ),
    );
  }
}

class CollectionCard extends ConsumerWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.count,
    required this.colorIndex,
    this.onAdd,
  });

  final PdfCollection collection;
  final int count;
  final int colorIndex;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = AppColors.coverGradientAt(colorIndex);

    return _CoverCard(
      title: collection.name,
      count: count,
      onTap: () => context.push('/collection/${collection.id}', extra: onAdd),
      onLongPress: () => _showActions(context, ref),
      header: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.collections_bookmark_outlined,
                size: 28,
                color: Colors.white70,
              ),
            ),
            if (onAdd != null)
              Positioned(
                top: AppSpacing.xs + 2,
                right: AppSpacing.xs + 2,
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _rename(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _delete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showCollectionNameDialog(
      context,
      title: 'Rename collection',
      initial: collection.name,
      confirmLabel: 'Rename',
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(collectionsProvider.notifier)
        .renameCollection(collection.id, name.trim());
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDeleteCollection(
      context,
      name: collection.name,
    );
    if (!confirmed) return;
    await ref
        .read(collectionsProvider.notifier)
        .deleteCollection(collection.id);
  }
}
