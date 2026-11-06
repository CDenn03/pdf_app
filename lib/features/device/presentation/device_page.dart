import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/features/device/domain/device_pdf_entry.dart';
import 'package:sefer/features/device/domain/device_sort.dart';
import 'package:sefer/features/device/presentation/device_collection_picker.dart';
import 'package:sefer/features/device/presentation/device_empty_states.dart';
import 'package:sefer/features/device/presentation/device_selection_bar.dart';
import 'package:sefer/features/device/presentation/device_sort_button.dart';
import 'package:sefer/features/device/presentation/device_tile.dart';
import 'package:sefer/features/device/state/device_files_providers.dart';
import 'package:sefer/features/device/state/device_selection_purpose.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/shared/state/document_selection_controller.dart';
import 'package:sefer/shared/widgets/file_actions_sheet.dart';
import 'package:sefer/shared/widgets/selection_action_bar.dart';

/// Shows all PDF files found on the device via storage scan.
///
/// When [targetCollectionId] is non-null the page selects files to add to
/// that collection; otherwise long-pressing a row starts selecting files to
/// manage (favorite, add to a collection).
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
  final _selection = DocumentSelectionController();
  final _searchController = TextEditingController();
  String _query = '';
  late DeviceSelectionPurpose _purpose = _purposeFor(widget);

  static DeviceSelectionPurpose _purposeFor(DevicePage widget) {
    final id = widget.targetCollectionId;
    return id == null ? const ManageDeviceFiles() : AddFilesToCollection(id);
  }

  String? get _targetCollectionId => switch (_purpose) {
    AddFilesToCollection(:final collectionId) => collectionId,
    ManageDeviceFiles() => null,
  };

  bool get _selecting => _targetCollectionId != null || _selection.isSelecting;

  @override
  void initState() {
    super.initState();
    _selection.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(DevicePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetCollectionId != oldWidget.targetCollectionId) {
      _selection.clear();
      setState(() => _purpose = _purposeFor(widget));
    }
  }

  @override
  void dispose() {
    _selection.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  void clearSelection() {
    _selection.clear();
    setState(() => _purpose = const ManageDeviceFiles());
  }

  /// Returns true when Back was consumed by leaving selection.
  bool handleBack() {
    if (!_selecting) return false;
    clearSelection();
    return true;
  }

  Future<void> _addSelected() async {
    var targetId = _targetCollectionId;
    targetId ??= await pickOrCreateCollection(context, ref);
    if (targetId == null || !mounted) return;
    final destination = targetId.isEmpty ? null : targetId;

    final paths = _selection.selectedPaths;
    final library = ref.read(libraryEntriesProvider.notifier);
    for (final path in paths) {
      await library.addFile(path, collectionId: destination);
    }
    if (!mounted) return;

    _showMessage(
      '${_fileCount(paths.length)} added to ${_collectionName(destination)}',
    );
    clearSelection();
    widget.onDone?.call();
  }

  Future<void> _setFavorite(bool favorite) async {
    final paths = _selection.selectedPaths;
    await ref
        .read(libraryEntriesProvider.notifier)
        .setFavoriteForPaths(paths, favorite: favorite);
    if (!mounted) return;
    final verb = favorite ? 'marked as favorite' : 'removed from favorites';
    _showMessage('${_fileCount(paths.length)} $verb');
    _selection.clear();
  }

  String _fileCount(int count) => '$count file${count == 1 ? '' : 's'}';

  String _collectionName(String? id) {
    if (id == null) return 'library';
    final collections = ref.read(collectionsProvider).value ?? [];
    return collections.where((c) => c.id == id).firstOrNull?.name ??
        'collection';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<DevicePdfEntry> _visibleEntries(
    List<DevicePdfEntry> all,
    DeviceSort sort,
  ) {
    final query = _query.toLowerCase().trim();
    final matching = query.isEmpty
        ? all
        : all.where((e) => e.name.toLowerCase().contains(query));
    return sortDeviceEntries(matching, sort);
  }

  void _toggleAll(List<DevicePdfEntry> visible) {
    final paths = visible.map((e) => e.path);
    if (paths.every(_selection.isSelected)) {
      _selection.clear();
    } else {
      _selection.selectVisible(paths);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deviceFilesProvider, (_, next) {
      final rows = next.value;
      if (rows != null) _selection.retainExisting(rows.map((e) => e.path));
    });
    final scanState = ref.watch(deviceFilesProvider);
    final sort = ref.watch(deviceSortProvider);
    final visible = _visibleEntries(scanState.value ?? [], sort);
    final targetId = _targetCollectionId;

    return Column(
      children: [
        GreetingHeader(
          subtitle: targetId != null
              ? 'Adding to "${_collectionName(targetId)}"'
              : 'All PDFs on device',
          title: 'Device',
          action: _selecting
              ? TextButton(
                  onPressed: clearSelection,
                  child: const Text('Cancel'),
                )
              : _HeaderActions(
                  sort: sort,
                  onSortSelected: ref.read(deviceSortProvider.notifier).select,
                  onRescan: scanState.isLoading
                      ? null
                      : () => ref.read(deviceFilesProvider.notifier).scan(),
                ),
        ),
        PageSearchBar(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          hintText: 'Search device…',
        ),
        if (_selecting)
          DeviceSelectionHeader(
            count: _selection.selectedPaths.length,
            allVisibleSelected:
                visible.isNotEmpty &&
                visible.every((e) => _selection.isSelected(e.path)),
            onToggleAll: () => _toggleAll(visible),
          ),
        Expanded(child: _buildList(visible, scanState.isLoading)),
        if (_selection.isSelecting) _buildActionBar(targetId),
        if (!_selecting) SizedBox(height: widget.bottomPadding),
      ],
    );
  }

  Widget _buildActionBar(String? targetId) {
    final count = _selection.selectedPaths.length;
    if (targetId != null) {
      return DeviceActionBar(
        count: count,
        collectionName: _collectionName(targetId),
        bottomPadding: widget.bottomPadding,
        onAdd: _addSelected,
      );
    }
    return SelectionActionBar(
      selectedPaths: _selection.selectedPaths,
      favoritePaths: ref.watch(favoritePathsProvider),
      onSetFavorite: _setFavorite,
      bottomPadding: widget.bottomPadding,
      extraActions: [
        TextButton.icon(
          onPressed: _addSelected,
          icon: const Icon(Icons.collections_bookmark_outlined),
          label: const Text('Add to collection'),
        ),
        TextButton.icon(
          onPressed: _selection.clear,
          icon: const Icon(Icons.close),
          label: const Text('Clear'),
        ),
      ],
    );
  }

  Widget _buildList(List<DevicePdfEntry> entries, bool isLoading) {
    if (isLoading) return const DeviceScanningState();

    if (entries.isEmpty && _query.isEmpty) {
      final permDenied = ref
          .watch(deviceFilesProvider.notifier)
          .permissionDenied;
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
    final favoritePaths = ref.watch(favoritePathsProvider);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        final available = entry.status == FileStatus.ok;
        return DeviceTile(
          entry: entry,
          inLibrary: libraryPaths.contains(entry.path),
          isFavorite: favoritePaths.contains(entry.path),
          isSelected: _selection.isSelected(entry.path),
          selecting: _selecting,
          onTap: () => _onTileTap(entry),
          onLongPress: available ? () => _selection.select(entry.path) : null,
          onOverflow: available ? () => _showFileActions(entry) : null,
        );
      },
    );
  }

  void _onTileTap(DevicePdfEntry entry) {
    if (_selecting) {
      _selection.toggle(entry.path);
    } else {
      context.push('/reader', extra: ReaderRouteArguments(path: entry.path));
    }
  }

  void _showFileActions(DevicePdfEntry entry) {
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
      onSelect: () => _selection.select(entry.path),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.sort,
    required this.onSortSelected,
    required this.onRescan,
  });

  final DeviceSort sort;
  final ValueChanged<DeviceSort> onSortSelected;
  final VoidCallback? onRescan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DeviceSortButton(sort: sort, onSelected: onSortSelected),
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          onPressed: onRescan,
          tooltip: 'Rescan',
        ),
      ],
    );
  }
}
