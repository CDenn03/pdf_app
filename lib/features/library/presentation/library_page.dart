import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pdf_app/core/models/collection.dart';
import 'package:pdf_app/core/models/file_status.dart';
import 'package:pdf_app/features/library/state/library_entry.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';

/// The Library tab — only files the user has explicitly added.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.searchQuery = ''});

  final String searchQuery;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final _expandedCollections = <String>{};

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(libraryEntriesProvider);
    final collections = ref.watch(collectionsProvider);
    final q = widget.searchQuery.toLowerCase().trim();

    if (q.isNotEmpty) {
      final filtered = entries
          .where((e) => e.name.toLowerCase().contains(q))
          .toList();
      if (filtered.isEmpty) return _EmptySearch(query: widget.searchQuery);
      return _EntryList(entries: filtered);
    }

    final uncollected = entries.where((e) => e.collectionId == null).toList();

    if (entries.isEmpty) {
      return const _EmptyLibrary();
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final col in collections) ...[
          _CollectionHeader(
            collection: col,
            expanded: _expandedCollections.contains(col.id),
            onToggle: () => setState(() {
              if (_expandedCollections.contains(col.id)) {
                _expandedCollections.remove(col.id);
              } else {
                _expandedCollections.add(col.id);
              }
            }),
            onRename: () => _renameCollection(context, col),
            onDelete: () => _deleteCollection(context, col),
          ),
          if (_expandedCollections.contains(col.id))
            ...entries
                .where((e) => e.collectionId == col.id)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _EntryTile(entry: e),
                  ),
                ),
        ],
        if (uncollected.isNotEmpty) ...[
          if (collections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Files',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ...uncollected.map((e) => _EntryTile(entry: e)),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: OutlinedButton.icon(
            onPressed: () => _createCollection(context),
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: const Text('New collection'),
          ),
        ),
      ],
    );
  }

  Future<void> _createCollection(BuildContext context) async {
    final name = await _showNameDialog(context, title: 'New collection');
    if (name == null || name.trim().isEmpty) return;
    ref.read(collectionsProvider.notifier).addCollection(name.trim());
  }

  Future<void> _renameCollection(
    BuildContext context,
    PdfCollection col,
  ) async {
    final name = await _showNameDialog(
      context,
      title: 'Rename collection',
      initial: col.name,
    );
    if (name == null || name.trim().isEmpty) return;
    ref
        .read(collectionsProvider.notifier)
        .renameCollection(col.id, name.trim());
  }

  Future<void> _deleteCollection(
    BuildContext context,
    PdfCollection col,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text(
          'Files in "${col.name}" will be moved to the root library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final entries = ref.read(libraryEntriesProvider);
    for (final e in entries.where((e) => e.collectionId == col.id)) {
      await ref
          .read(libraryEntriesProvider.notifier)
          .moveToCollection(e.id, null);
    }
    ref.read(collectionsProvider.notifier).deleteCollection(col.id);
  }

  Future<String?> _showNameDialog(
    BuildContext context, {
    required String title,
    String initial = '',
  }) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, ctrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.entries});

  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: entries.length,
      itemBuilder: (_, i) => _EntryTile(entry: entries[i]),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unavailable = entry.status != FileStatus.ok;
    final theme = Theme.of(context);
    final collections = ref.watch(collectionsProvider);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: unavailable
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.picture_as_pdf_outlined,
          size: 20,
          color: unavailable
              ? theme.colorScheme.outline
              : theme.colorScheme.primary,
        ),
      ),
      title: Text(
        entry.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: unavailable ? theme.colorScheme.outline : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: unavailable
          ? Text(
              'File unavailable',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          : null,
      trailing: PopupMenuButton<_EntryAction>(
        icon: Icon(Icons.more_vert, size: 18, color: theme.colorScheme.outline),
        onSelected: (action) =>
            _handleAction(context, ref, action, collections),
        itemBuilder: (_) => const [
          PopupMenuItem(value: _EntryAction.open, child: Text('Open')),
          PopupMenuItem(
            value: _EntryAction.move,
            child: Text('Move to collection'),
          ),
          PopupMenuItem(
            value: _EntryAction.remove,
            child: Text('Remove from library'),
          ),
        ],
      ),
      onTap: unavailable
          ? null
          : () {
              ref
                  .read(libraryEntriesProvider.notifier)
                  .recordOpened(entry.path);
              context.go('/reader', extra: entry.path);
            },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _EntryAction action,
    List<PdfCollection> collections,
  ) async {
    switch (action) {
      case _EntryAction.open:
        ref.read(libraryEntriesProvider.notifier).recordOpened(entry.path);
        if (context.mounted) context.go('/reader', extra: entry.path);
      case _EntryAction.move:
        await _showMoveDialog(context, ref, collections);
      case _EntryAction.remove:
        ref.read(libraryEntriesProvider.notifier).removeFile(entry.id);
    }
  }

  Future<void> _showMoveDialog(
    BuildContext context,
    WidgetRef ref,
    List<PdfCollection> collections,
  ) async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to collection'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Root library'),
          ),
          for (final col in collections)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, col.id),
              child: Text(col.name),
            ),
        ],
      ),
    );
    if (selected == null) return;
    ref
        .read(libraryEntriesProvider.notifier)
        .moveToCollection(entry.id, selected.isEmpty ? null : selected);
  }
}

enum _EntryAction { open, move, remove }

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.collection,
    required this.expanded,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
  });

  final PdfCollection collection;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(
        expanded ? Icons.folder_open_outlined : Icons.folder_outlined,
        color: theme.colorScheme.primary,
      ),
      title: Text(collection.name, style: theme.textTheme.bodyMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: theme.colorScheme.outline,
          ),
          PopupMenuButton<_CollectionAction>(
            icon: Icon(
              Icons.more_vert,
              size: 18,
              color: theme.colorScheme.outline,
            ),
            onSelected: (a) {
              if (a == _CollectionAction.rename) onRename();
              if (a == _CollectionAction.delete) onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _CollectionAction.rename,
                child: Text('Rename'),
              ),
              PopupMenuItem(
                value: _CollectionAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      onTap: onToggle,
    );
  }
}

enum _CollectionAction { rename, delete }

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Your library is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap + to add PDFs, or browse the Device tab to find files on your phone.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No results for "$query"', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
