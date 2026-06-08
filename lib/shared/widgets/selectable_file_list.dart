import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/models/collection.dart';
import 'package:pdf_app/core/models/file_status.dart';
import 'package:pdf_app/features/library/state/library_entry.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';

/// Controller that lets a parent widget clear the selection from outside.
class SelectableListController {
  VoidCallback? _clearCallback;

  void clearSelection() => _clearCallback?.call();
}

/// A list of PDF entries that supports multi-select and bulk add to library.
///
/// Interaction model:
/// - Long-press any item → enter selection mode
/// - Tap while selecting → toggle that item
/// - Tap while not selecting → [onOpenFile] is called
/// - Select-all checkbox in the header bar
/// - Bottom action bar: "Add N to Library" | "Add to Collection"
class SelectableFileList extends ConsumerStatefulWidget {
  const SelectableFileList({
    super.key,
    required this.entries,
    required this.onOpenFile,
    required this.onSelectionChanged,
    this.controller,
    this.showPath = false,
  });

  final List<LibraryEntry> entries;
  final void Function(LibraryEntry entry) onOpenFile;

  /// Called whenever the selection set changes (empty = not selecting).
  final void Function(Set<String> selected) onSelectionChanged;

  /// Optional controller to clear selection from outside.
  final SelectableListController? controller;

  /// Show the file path as subtitle (Device tab).
  final bool showPath;

  @override
  ConsumerState<SelectableFileList> createState() => _SelectableFileListState();
}

class _SelectableFileListState extends ConsumerState<SelectableFileList> {
  final _selected = <String>{};

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller?._clearCallback = _clearSelection;
  }

  @override
  void didUpdateWidget(SelectableFileList old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._clearCallback = null;
      widget.controller?._clearCallback = _clearSelection;
    }
  }

  @override
  void dispose() {
    widget.controller?._clearCallback = null;
    super.dispose();
  }

  void _clearSelection() {
    setState(() => _selected.clear());
    widget.onSelectionChanged({});
  }

  void _toggleAll() {
    setState(() {
      if (_selected.length == widget.entries.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(widget.entries.map((e) => e.path));
      }
    });
    widget.onSelectionChanged(Set.of(_selected));
  }

  void _toggleItem(String path) {
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
      } else {
        _selected.add(path);
      }
    });
    widget.onSelectionChanged(Set.of(_selected));
  }

  void _enterSelection(String path) {
    setState(() => _selected.add(path));
    widget.onSelectionChanged(Set.of(_selected));
  }

  Future<void> _addToLibrary() async {
    final paths = List<String>.from(_selected);
    for (final path in paths) {
      await ref.read(libraryEntriesProvider.notifier).addFile(path);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${paths.length} file${paths.length == 1 ? '' : 's'} added to library',
          ),
        ),
      );
      _clearSelection();
    }
  }

  Future<void> _addToCollection() async {
    final collections = ref.read(collectionsProvider).value ?? [];
    final result = await _showCollectionPicker(collections);
    if (result == null) return; // cancelled

    final collectionId = result.isEmpty ? null : result;
    final paths = List<String>.from(_selected);
    for (final path in paths) {
      await ref
          .read(libraryEntriesProvider.notifier)
          .addFile(path, collectionId: collectionId);
    }

    if (mounted) {
      final dest = collectionId == null
          ? 'library'
          : collections.firstWhere((c) => c.id == collectionId).name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${paths.length} file${paths.length == 1 ? '' : 's'} added to $dest',
          ),
        ),
      );
      _clearSelection();
    }
  }

  /// Returns collection id, '' for root library, or null if cancelled.
  Future<String?> _showCollectionPicker(List<PdfCollection> collections) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _CollectionPickerSheet(
        collections: collections,
        onCreateNew: () async {
          Navigator.of(ctx).pop();
          final name = await _showCreateCollectionDialog();
          if (name == null || name.trim().isEmpty) return null;
          await ref
              .read(collectionsProvider.notifier)
              .addCollection(name.trim());
          final updated = ref.read(collectionsProvider).value ?? [];
          return updated.last.id;
        },
      ),
    );
  }

  Future<String?> _showCreateCollectionDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Collection name',
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final libraryPaths = ref
        .watch(libraryEntriesProvider)
        .value
        ?.map((e) => e.path)
        .toSet() ?? {};
    final allSelected =
        widget.entries.isNotEmpty && _selected.length == widget.entries.length;

    return Column(
      children: [
        // Select-all header — only visible in selection mode.
        if (_selecting)
          Container(
            color: theme.colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  tristate: true,
                  onChanged: (_) => _toggleAll(),
                ),
                Text(
                  '${_selected.length} selected',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),

        // File list.
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: _selecting ? 4 : 24),
            itemCount: widget.entries.length,
            itemBuilder: (_, i) {
              final entry = widget.entries[i];
              final isSelected = _selected.contains(entry.path);
              final inLibrary = libraryPaths.contains(entry.path);
              final unavailable = entry.status != FileStatus.ok;

              return _SelectableTile(
                entry: entry,
                isSelected: isSelected,
                selecting: _selecting,
                inLibrary: inLibrary,
                showPath: widget.showPath,
                unavailable: unavailable,
                onTap: () {
                  if (_selecting) {
                    _toggleItem(entry.path);
                  } else {
                    widget.onOpenFile(entry);
                  }
                },
                onLongPress: unavailable
                    ? null
                    : () => _enterSelection(entry.path),
              );
            },
          ),
        ),

        // Bottom action bar — only visible in selection mode.
        if (_selecting)
          _SelectionActionBar(
            count: _selected.length,
            onAddToLibrary: _addToLibrary,
            onAddToCollection: _addToCollection,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Selectable tile
// ---------------------------------------------------------------------------

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.entry,
    required this.isSelected,
    required this.selecting,
    required this.inLibrary,
    required this.showPath,
    required this.unavailable,
    required this.onTap,
    this.onLongPress,
  });

  final LibraryEntry entry;
  final bool isSelected;
  final bool selecting;
  final bool inLibrary;
  final bool showPath;
  final bool unavailable;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: selecting
            ? Checkbox(value: isSelected, onChanged: (_) => onTap())
            : Container(
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
            : showPath
            ? Text(
                entry.path,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : entry.lastOpenedAt != null
            ? Text(
                _formatDate(entry.lastOpenedAt!),
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: !selecting
            ? inLibrary
                  ? Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    )
                  : Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.outline,
                    )
            : null,
        onTap: unavailable && !selecting ? null : onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.count,
    required this.onAddToLibrary,
    required this.onAddToCollection,
  });

  final int count;
  final VoidCallback onAddToLibrary;
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddToLibrary,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Add $count to Library',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddToCollection,
                  icon: const Icon(Icons.folder_outlined, size: 18),
                  label: const Text(
                    'Add to Collection',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Collection picker sheet
// ---------------------------------------------------------------------------

class _CollectionPickerSheet extends StatelessWidget {
  const _CollectionPickerSheet({
    required this.collections,
    required this.onCreateNew,
  });

  final List<PdfCollection> collections;
  final Future<String?> Function() onCreateNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('Add to', style: theme.textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.collections_bookmark_outlined),
            title: const Text('Root library'),
            onTap: () => Navigator.of(context).pop(''),
          ),
          if (collections.isNotEmpty) const Divider(height: 1),
          ...collections.map(
            (col) => ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(col.name),
              onTap: () => Navigator.of(context).pop(col.id),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
            title: const Text('New collection…'),
            onTap: () async {
              final id = await onCreateNew();
              if (context.mounted && id != null) {
                Navigator.of(context).pop(id);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
