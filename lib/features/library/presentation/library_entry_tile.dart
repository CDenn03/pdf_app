import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/shared/widgets/file_actions_sheet.dart';
import 'package:sefer/shared/widgets/file_list_tile.dart';

class LibraryEntryTile extends ConsumerWidget {
  const LibraryEntryTile({super.key, required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider).value ?? [];
    final collectionName = entry.collectionId != null
        ? collections
              .where((c) => c.id == entry.collectionId)
              .map((c) => c.name)
              .firstOrNull
        : null;

    final tags = [?collectionName, if (entry.isFavorite) 'Favorite'];

    return FileListTile(
      title: entry.name,
      subtitle: tags.isNotEmpty ? tags.join(' · ') : null,
      gradientSeed: entry.path,
      unavailable: entry.status != FileStatus.ok,
      semanticLabel: 'Open ${entry.name}',
      trailing: entry.isFavorite
          ? const Icon(Icons.favorite, size: 14, color: AppColors.brand)
          : null,
      onTap: entry.status == FileStatus.ok ? () => _open(context, ref) : null,
      onLongPress: () => showFileActionsSheet(
        context,
        ref,
        path: entry.path,
        name: entry.name,
        libraryEntryId: entry.id,
        status: entry.status,
        showInFavorites: entry.isFavorite,
        showInCollectionId: entry.collectionId,
        showInCollectionLabel: collectionName != null
            ? 'Show in "$collectionName"'
            : null,
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    ref.read(libraryEntriesProvider.notifier).recordOpened(entry.path);
    ref.read(recentsProvider.notifier).recordOpened(entry.path);
    context.push('/reader', extra: entry.path);
  }
}
