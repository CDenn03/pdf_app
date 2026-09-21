import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/features/device/presentation/device_empty_states.dart';
import 'package:sefer/features/device/presentation/device_selection_bar.dart';
import 'package:sefer/features/device/presentation/device_tile.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/library/presentation/collection_dialogs.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/shared/widgets/file_actions_sheet.dart';

/// Shows all PDF files found on the device via storage scan.
///
/// When [targetCollectionId] is non-null the page enters multi-select mode
/// immediately so the user can pick files to add to that collection.
class DevicePage extends ConsumerStatefulWidget {
  const DevicePage({
    super.key,
    this.bottomPadding = 0,
    this.targetCollectionId,
    this.onDone,
  });

  final double bottomPadding;
  final String? targetCollectionId;
  final VoidCallback? onDone;

  @override
  ConsumerState<DevicePage> createState() => DevicePageState();
}

class DevicePageState extends ConsumerState<DevicePage> {
  final _selected = <String>{};
  final _searchController = TextEditingController();
  String _query = '';
  String? _activeCollectionId;

  bool get _selecting => _selected.isNotEmpty || _activeCollectionId != null;

  @override
  void initState() {
    super.initState();
    if (widget.targetCollectionId != null) {
      _activeCollectionId = widget.targetCollectionId;
    }
  }

  @override
  void didUpdateWidget(DevicePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetCollectionId != oldWidget.targetCollectionId) {
      setState(() {
        _activeCollectionId = widget.targetCollectionId;
        _selected.clear();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void clearSelection() {
    setState(() {
      _selected.clear();
      _activeCollectionId = null;
    });
  }

  void _toggle(String path) {
    setState(() {
      if (!_selected.remove(path)) _selected.add(path);
    });
  }

  Future<void> _addSelected() async {
    String? targetId = _activeCollectionId;
    if (targetId == null && mounted) {
      targetId = await _pickOrCreateCollection();
      if (!mounted) return;
      // null means cancelled; empty string means root library.
      if (targetId == null) return;
    }

    final paths = List<String>.from(_selected);
    for (final path in paths) {
      await ref
          .read(libraryEntriesProvider.notifier)
          .addFile(path, collectionId: targetId!.isEmpty ? null : targetId);
    }
    if (!mounted) return;

    final collections = ref.read(collectionsProvider).value ?? [];
    final dest = targetId == null || targetId.isEmpty
        ? 'library'
        : collections
              .firstWhere(
                (c) => c.id == targetId,
                orElse: () => const PdfCollection(id: '', name: 'collection'),
              )
              .name;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${paths.length} file${paths.length == 1 ? '' : 's'} added to $dest',
        ),
      ),
    );
    clearSelection();
    widget.onDone?.call();
  }

  /// Returns null if cancelled, '' for root library, or a collection id.
  Future<String?> _pickOrCreateCollection() async {
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
            onPressed: () => Navigator.pop(ctx, '__new__'),
            child: const Text('+ New collection…'),
          ),
        ],
      ),
    );

    if (choice != '__new__') return choice;

    if (!mounted) return null;
    final name = await showCollectionNameDialog(context, title: 'New collection');
    if (name == null || name.trim().isEmpty || !mounted) return null;

    await ref.read(collectionsProvider.notifier).addCollection(name.trim());
    final updated = ref.read(collectionsProvider).value ?? [];
    return updated.last.id;
  }

  @override
  Widget build(BuildContext context) {
    // .value ?? [] handles AsyncNotifier loading/error states (#16).
    final scanState = ref.watch(deviceFilesProvider);
    final all = scanState.value ?? [];

    final q = _query.toLowerCase().trim();
    final entries = q.isEmpty
        ? all
        : all.where((e) => e.name.toLowerCase().contains(q)).toList();

    final collectionName = _activeCollectionId == null
        ? null
        : ref
              .watch(collectionsProvider)
              .value
              ?.firstWhere(
                (c) => c.id == _activeCollectionId,
                orElse: () => const PdfCollection(id: '', name: 'collection'),
              )
              .name;

    return Column(
      children: [
        GreetingHeader(
          subtitle: collectionName != null
              ? 'Adding to "$collectionName"'
              : 'All PDFs on device',
          title: 'Device',
          action: _selecting
              ? TextButton(
                  onPressed: clearSelection,
                  child: const Text('Cancel'),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: scanState.isLoading
                      ? null
                      : () => ref.read(deviceFilesProvider.notifier).scan(),
                  tooltip: 'Rescan',
                ),
        ),
        PageSearchBar(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          hintText: 'Search device…',
        ),
        if (_selecting)
          DeviceSelectionHeader(
            count: _selected.length,
            total: entries.length,
            onToggleAll: () => _toggleAll(entries),
          ),
        Expanded(child: _buildList(entries, scanState.isLoading)),
        if (_selecting && _selected.isNotEmpty)
          DeviceActionBar(
            count: _selected.length,
            collectionName: collectionName,
            bottomPadding: widget.bottomPadding,
            onAdd: _addSelected,
          ),
        if (!_selecting) SizedBox(height: widget.bottomPadding),
      ],
    );
  }

  void _toggleAll(List<LibraryEntry> entries) {
    setState(() {
      if (_selected.length == entries.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(entries.map((e) => e.path));
      }
    });
  }

  Widget _buildList(List<LibraryEntry> entries, bool isLoading) {
    if (isLoading) return const DeviceScanningState();

    if (entries.isEmpty && _query.isEmpty) {
      final permDenied =
          ref.watch(deviceFilesProvider.notifier).permissionDenied;
      return DeviceEmptyState(
        permissionDenied: permDenied,
        onScan: () => ref.read(deviceFilesProvider.notifier).scan(),
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No results for "$_query"',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final libraryPaths =
        ref.watch(libraryEntriesProvider).value?.map((e) => e.path).toSet() ??
        {};

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return DeviceTile(
          entry: entry,
          inLibrary: libraryPaths.contains(entry.path),
          isSelected: _selected.contains(entry.path),
          selecting: _selecting,
          onTap: () => _onTileTap(entry),
          onLongPress: entry.status == FileStatus.ok
              ? () => _onTileLongPress(entry)
              : null,
        );
      },
    );
  }

  void _onTileTap(LibraryEntry entry) {
    if (_selecting) {
      _toggle(entry.path);
    } else {
      ref.read(libraryEntriesProvider.notifier).recordOpened(entry.path);
      context.push('/reader', extra: entry.path);
    }
  }

  void _onTileLongPress(LibraryEntry entry) {
    final libraryEntry = ref
        .read(libraryEntriesProvider)
        .value
        ?.where((e) => e.path == entry.path)
        .firstOrNull;
    showFileActionsSheet(
      context,
      ref,
      path: entry.path,
      name: entry.name,
      libraryEntryId: libraryEntry?.id,
      canSelect: true,
      onSelect: () => setState(() => _selected.add(entry.path)),
    );
  }
}
