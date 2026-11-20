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

class LibraryEntryTile extends ConsumerWidget {
  const LibraryEntryTile({super.key, required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider).value ?? [];
    final collectionNames = [
      for (final collection in collections)
        if (entry.collectionIds.contains(collection.id)) collection.name,
    ];
    final tags = [...collectionNames, if (entry.isFavorite) 'Favorite'];

    void showActions() => showFileActionsSheet(
      context,
      ref,
      path: entry.path,
      name: entry.name,
      libraryEntryId: entry.id,
      status: entry.status,
      showInFavorites: entry.isFavorite,
    );

    return FileListTile(
      title: entry.name,
      subtitle: tags.isNotEmpty ? tags.join(' · ') : null,
      gradientSeed: entry.path,
      unavailable: entry.status != FileStatus.ok,
      semanticLabel: 'Open ${entry.name}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.isFavorite)
            const Icon(Icons.favorite, size: 14, color: AppColors.brand),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'File actions for ${entry.name}',
            onPressed: showActions,
          ),
        ],
      ),
      onTap: entry.status == FileStatus.ok ? () => _open(context, ref) : null,
      onLongPress: showActions,
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    context.push('/reader', extra: ReaderRouteArguments(path: entry.path));
  }
}
