import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/features/library/presentation/collection_dialogs.dart';
import 'package:sefer/features/library/state/library_providers.dart';

const _newCollectionChoice = '__new__';

/// Returns null if cancelled, '' for the root library, or a collection id.
Future<String?> pickOrCreateCollection(
  BuildContext context,
  WidgetRef ref,
) async {
  final collections = ref.read(collectionsProvider).value ?? [];
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Add to collection'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, ''),
          child: const Text('Library (no collection)'),
        ),
        for (final col in collections)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, col.id),
            child: Text(col.name),
          ),
        const Divider(),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, _newCollectionChoice),
          child: const Text('+ New collection…'),
        ),
      ],
    ),
  );
  if (choice != _newCollectionChoice) return choice;
  if (!context.mounted) return null;

  final name = await showCollectionNameDialog(context, title: 'New collection');
  if (name == null || name.trim().isEmpty) return null;

  await ref.read(collectionsProvider.notifier).addCollection(name.trim());
  return ref.read(collectionsProvider).value?.last.id;
}
