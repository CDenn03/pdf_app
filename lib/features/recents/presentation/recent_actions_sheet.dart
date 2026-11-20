import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/core/utils/share_utils.dart';
import 'package:sefer/features/library/presentation/collection_picker.dart';
import 'package:sefer/features/library/state/document_actions.dart';
import 'package:sefer/features/library/state/document_collections.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/shared/widgets/document_collection_tiles.dart';

Future<void> showRecentActionsSheet(
  BuildContext context,
  WidgetRef ref,
  RecentEntry entry,
) {
  final messenger = ScaffoldMessenger.of(context);

  Future<void> rename() async {
    final newName = await showRenameDialog(context, currentName: entry.name);
    if (newName == null) return;
    final result = await ref
        .read(documentActionsProvider)
        .rename(path: entry.path, newName: newName);
    messenger.showSnackBar(SnackBar(content: Text(result.userMessage)));
  }

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (_, sheetRef, _) {
        final libraryEntries =
            sheetRef.watch(libraryEntriesProvider).value ?? const [];
        final libraryEntry = libraryEntries
            .where((item) => item.path == entry.path)
            .firstOrNull;
        final membership = collectionsForPath(
          path: entry.path,
          entries: libraryEntries,
          collections: sheetRef.watch(collectionsProvider).value ?? const [],
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new_outlined),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(
                    '/reader',
                    extra: ReaderRouteArguments(path: entry.path),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  sharePdf(context, entry.path);
                },
              ),
              DocumentCollectionTiles(
                collections: membership,
                onAddToCollection: () async {
                  Navigator.pop(sheetContext);
                  final collectionId = await pickOrCreateCollection(
                    context,
                    ref,
                    existingCollectionIds:
                        libraryEntry?.collectionIds ?? const {},
                  );
                  if (collectionId == null) return;
                  await ref
                      .read(libraryEntriesProvider.notifier)
                      .addFile(entry.path, collectionIds: {collectionId});
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Added to collection.')),
                  );
                },
                onOpenCollection: (collection) {
                  Navigator.pop(sheetContext);
                  context.push('/collection/${collection.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  rename();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
