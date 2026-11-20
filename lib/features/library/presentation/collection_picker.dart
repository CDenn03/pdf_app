import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/features/library/presentation/collection_dialogs.dart';
import 'package:sefer/features/library/state/library_providers.dart';

const _newCollectionChoice = '__new__';

Future<String?> pickOrCreateCollection(
  BuildContext context,
  WidgetRef ref, {
  Set<String> existingCollectionIds = const {},
}) async {
  final collections = ref.read(collectionsProvider).value ?? [];
  final choice = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Add to collection'),
      children: [
        for (final collection in collections)
          SimpleDialogOption(
            onPressed: existingCollectionIds.contains(collection.id)
                ? null
                : () => Navigator.pop(dialogContext, collection.id),
            child: Row(
              children: [
                Expanded(child: Text(collection.name)),
                if (existingCollectionIds.contains(collection.id))
                  const Icon(Icons.check, semanticLabel: 'Already added'),
              ],
            ),
          ),
        if (collections.isNotEmpty) const Divider(),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, _newCollectionChoice),
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
