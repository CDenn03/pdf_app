import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/utils/share_utils.dart';
import 'package:sefer/features/library/presentation/collection_picker.dart';
import 'package:sefer/features/library/state/document_actions.dart';
import 'package:sefer/features/library/state/document_collections.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/shared/widgets/document_collection_tiles.dart';

/// Long-press action menu shared by every file list surface.
///
/// Open and Share are shown only when the file is available. Optional actions
/// are included only when their callback / flag is supplied, so each surface
/// opts into exactly the actions that apply to it.
///
/// Rename, Remove from library and Delete follow rules that are worth stating
/// because they are not symmetrical:
///
/// - **Rename** renames the file on disk. It needs the file to be readable,
///   so it is hidden for a missing file, where it could only fail. It does
///   not need a library entry: renaming a file you have only seen on the
///   Device tab works, and simply leaves your library untouched.
/// - **Remove from library** needs a library entry, since that is all it
///   removes. Shown whatever the file's status, because a missing file is
///   exactly the entry you most want to clear.
/// - **Delete file** removes the file from the device and erases its
///   annotations, bookmarks, reading position and recents. Always behind a
///   confirmation that names the file.
///
/// All three are hidden for the bundled sample, which is an asset rather than
/// a file on disk.
Future<void> showFileActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required String name,
  String? libraryEntryId,
  bool canRename = true,
  bool canSelect = false,
  VoidCallback? onSelect,
  String? removeFromCollectionId,
  bool showInFavorites = false,
  FileStatus status = FileStatus.ok,
}) {
  final available = status == FileStatus.ok;
  final bundled = DocumentActions.isBundled(path);

  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(documentActionsProvider);

  void report(DocumentActionResult result, String successText) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.ok ? successText : result.message!),
        action: result.undo == null
            ? null
            : SnackBarAction(label: 'Undo', onPressed: result.undo!),
      ),
    );
  }

  void open() {
    context.push('/reader', extra: ReaderRouteArguments(path: path));
  }

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (_, sheetRef, _) {
        final libraryEntries =
            sheetRef.watch(libraryEntriesProvider).value ?? const [];
        final libraryEntry = libraryEntries
            .where((entry) => entry.path == path)
            .firstOrNull;
        final inLibrary = libraryEntryId != null || libraryEntry != null;
        final membership = collectionsForPath(
          path: path,
          entries: libraryEntries,
          collections: sheetRef.watch(collectionsProvider).value ?? const [],
        );
        return SafeArea(
          // Scrollable because the available actions can overflow a short screen
          // in landscape or at a large text scale.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (available)
                  ListTile(
                    leading: const Icon(Icons.open_in_new_outlined),
                    title: const Text('Open'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      open();
                    },
                  ),
                if (available)
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Share'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      sharePdf(context, path);
                    },
                  ),
                DocumentCollectionTiles(
                  collections: membership,
                  onAddToCollection: available
                      ? () async {
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
                              .addFile(path, collectionIds: {collectionId});
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Added to collection.'),
                            ),
                          );
                        }
                      : null,
                  onOpenCollection: (collection) {
                    Navigator.pop(sheetContext);
                    context.push('/collection/${collection.id}');
                  },
                ),
                if (canRename && available && !bundled)
                  ListTile(
                    leading: const Icon(Icons.drive_file_rename_outline),
                    title: const Text('Rename'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final newName = await showRenameDialog(
                        context,
                        currentName: name,
                      );
                      if (newName == null) return;
                      final result = await actions.rename(
                        path: path,
                        newName: newName,
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text(result.userMessage)),
                      );
                    },
                  ),
                if (removeFromCollectionId != null && libraryEntryId != null)
                  ListTile(
                    leading: const Icon(Icons.remove_circle_outline),
                    title: const Text('Remove from collection'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await ref
                          .read(libraryEntriesProvider.notifier)
                          .removeFromCollection(
                            libraryEntryId,
                            removeFromCollectionId,
                          );
                    },
                  ),
                if (showInFavorites)
                  ListTile(
                    leading: const Icon(Icons.favorite, size: 20),
                    title: const Text('Show in Favorites'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/favorites');
                    },
                  ),
                if (canSelect && onSelect != null)
                  ListTile(
                    leading: const Icon(Icons.check_box_outlined),
                    title: const Text('Select'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onSelect();
                    },
                  ),
                if (inLibrary && !bundled)
                  ListTile(
                    leading: const Icon(Icons.playlist_remove_outlined),
                    title: const Text('Remove from library'),
                    subtitle: const Text('Keeps the file on your device'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final result = await actions.removeFromLibrary(path);
                      report(result, 'Removed from library.');
                    },
                  ),
                if (!bundled)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                    title: Text(
                      'Delete file',
                      style: TextStyle(
                        color: Theme.of(sheetContext).colorScheme.error,
                      ),
                    ),
                    subtitle: const Text('Removes it from your device'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final confirmed = await showDeleteFileDialog(
                        context,
                        name: name,
                      );
                      if (confirmed != true) return;
                      final result = await actions.deleteFile(path);
                      report(result, 'Deleted.');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Confirmation for an irreversible file delete.
///
/// Names the file, and says what else goes with it, because annotations and
/// reading position are destroyed too and that is not obvious from "delete".
Future<bool?> showDeleteFileDialog(
  BuildContext context, {
  required String name,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete file?'),
      content: Text(
        '"$name" will be deleted from your device, along with its '
        'highlights, notes, bookmarks and reading position. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
