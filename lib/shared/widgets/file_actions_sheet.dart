import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/utils/share_utils.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

/// Long-press action menu shared by every file list surface.
///
/// Open and Share are shown only when the file is available. Optional actions
/// are included only when their callback / flag is supplied, so each surface
/// opts into exactly the actions that apply to it.
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
  String? showInCollectionId,
  String? showInCollectionLabel,
  bool showInFavorites = false,
  FileStatus status = FileStatus.ok,
}) {
  final available = status == FileStatus.ok;

  void open() {
    ref.read(libraryEntriesProvider.notifier).recordOpened(path);
    ref.read(recentsProvider.notifier).recordOpened(path);
    context.push('/reader', extra: path);
  }

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
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
          if (canRename && libraryEntryId != null)
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final newName = await showRenameDialog(
                  context,
                  currentName: name,
                );
                if (newName == null || newName.trim().isEmpty) return;
                await ref
                    .read(libraryEntriesProvider.notifier)
                    .renameFile(libraryEntryId, newName);
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
                    .moveToCollection(libraryEntryId, null);
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
          if (showInCollectionId != null)
            ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined),
              title: Text(showInCollectionLabel ?? 'Show in collection'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/collection/$showInCollectionId');
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
        ],
      ),
    ),
  );
}
