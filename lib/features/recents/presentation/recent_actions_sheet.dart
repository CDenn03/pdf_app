import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/core/utils/share_utils.dart';
import 'package:sefer/features/library/state/document_actions.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

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
    builder: (sheetContext) => SafeArea(
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
    ),
  );
}
