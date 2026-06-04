import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pdf_app/core/models/collection.dart';
import 'package:pdf_app/core/models/file_status.dart';
import 'package:pdf_app/core/theme/app_colors.dart';
import 'package:pdf_app/features/home/presentation/home_shell.dart';
import 'package:pdf_app/features/library/state/library_entry.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';

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

  /// If set, the page starts in selection mode to add files to this collection.
  final String? targetCollectionId;

  /// Called after a bulk-add completes so the shell can return to Library.
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
      if (_selected.contains(path)) {
        _selected.remove(path);
      } else {
        _selected.add(path);
      }
    });
  }

  Future<void> _addSelected() async {
    // If not already targeting a collection, ask the user to pick or create one.
    String? targetId = _activeCollectionId;
    if (targetId == null && mounted) {
      targetId = await _pickOrCreateCollection();
      if (!mounted) return;
      // null means user cancelled; empty string means root library.
      if (targetId == null) return;
    }

    final paths = List<String>.from(_selected);
    for (final path in paths) {
      await ref.read(libraryEntriesProvider.notifier).addFile(
        path,
        collectionId: targetId!.isEmpty ? null : targetId,
      );
    }
    if (!mounted) return;

    final collections = ref.read(collectionsProvider);
    final dest = targetId == null || targetId.isEmpty
        ? 'library'
        : collections
                .firstWhere(
                  (c) => c.id == targetId,
                  orElse: () => PdfCollection(id: '', name: 'collection'),
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

  /// Shows a dialog to pick an existing collection or create a new one.
  /// Returns null if cancelled, '' for root library, or a collection id.
  Future<String?> _pickOrCreateCollection() async {
    final collections = ref.read(collectionsProvider);
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

    // User wants to create a new collection — show a second dialog.
    if (!mounted) return null;
    final name = await _showNewCollectionDialog();
    if (name == null || name.trim().isEmpty || !mounted) return null;

    await ref.read(collectionsProvider.notifier).addCollection(name.trim());
    final updated = ref.read(collectionsProvider);
    return updated.last.id;
  }

  Future<String?> _showNewCollectionDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New collection'),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(deviceFilesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    final q = _query.toLowerCase().trim();
    final entries = q.isEmpty
        ? all
        : all.where((e) => e.name.toLowerCase().contains(q)).toList();

    final collectionName = _activeCollectionId == null
        ? null
        : ref
            .watch(collectionsProvider)
            .firstWhere(
              (c) => c.id == _activeCollectionId,
              orElse: () => PdfCollection(id: '', name: 'collection'),
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
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.brand,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.refresh_outlined, color: secondary),
                  onPressed: () => ref.read(deviceFilesProvider.notifier).scan(),
                  tooltip: 'Rescan',
                ),
        ),
        PageSearchBar(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          hintText: 'Search device…',
        ),
        if (_selecting)
          _SelectionHeader(
            count: _selected.length,
            total: entries.length,
            onToggleAll: () {
              setState(() {
                if (_selected.length == entries.length) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(entries.map((e) => e.path));
                }
              });
            },
          ),
        Expanded(child: _buildList(entries, isDark, secondary)),
        // Action bar sits above the floating nav bar.
        if (_selecting && _selected.isNotEmpty)
          _ActionBar(
            count: _selected.length,
            collectionName: collectionName,
            bottomPadding: widget.bottomPadding,
            onAdd: _addSelected,
          ),
        if (!_selecting)
          SizedBox(height: widget.bottomPadding),
      ],
    );
  }

  Widget _buildList(
    List<LibraryEntry> entries,
    bool isDark,
    Color secondary,
  ) {
    if (entries.isEmpty && _query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_android_outlined,
                size: 52,
                color: secondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No PDFs found on device',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Grant storage permission and tap refresh to scan.',
                style: GoogleFonts.dmSans(fontSize: 14, color: secondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No results for "$_query"',
          style: GoogleFonts.dmSans(fontSize: 15),
        ),
      );
    }

    final libraryPaths = ref
        .watch(libraryEntriesProvider)
        .map((e) => e.path)
        .toSet();

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        final inLibrary = libraryPaths.contains(entry.path);
        final isSelected = _selected.contains(entry.path);

        return _DeviceTile(
          entry: entry,
          inLibrary: inLibrary,
          isSelected: isSelected,
          selecting: _selecting,
          onTap: () {
            if (_selecting) {
              _toggle(entry.path);
            } else {
              // Single tap outside selection mode: open directly.
              ref.read(libraryEntriesProvider.notifier).recordOpened(entry.path);
              context.push('/reader', extra: entry.path);
            }
          },
          onLongPress: entry.status == FileStatus.ok
              ? () {
                  setState(() {
                    _selected.add(entry.path);
                  });
                }
              : null,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Selection header bar
// ---------------------------------------------------------------------------

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.count,
    required this.total,
    required this.onToggleAll,
  });

  final int count;
  final int total;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.brandTint.withValues(alpha: 0.12)
        : AppColors.brandTint;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: count == total && total > 0,
            tristate: true,
            activeColor: AppColors.brand,
            onChanged: (_) => onToggleAll(),
          ),
          const SizedBox(width: 4),
          Text(
            count > 0 ? '$count selected' : 'Select files',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Device file tile
// ---------------------------------------------------------------------------

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.entry,
    required this.inLibrary,
    required this.isSelected,
    required this.selecting,
    required this.onTap,
    this.onLongPress,
  });

  final LibraryEntry entry;
  final bool inLibrary;
  final bool isSelected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primary =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final colorIndex = entry.path.hashCode.abs();
    final gradient = AppColors.coverGradientAt(colorIndex);

    final bg = isSelected
        ? AppColors.brandTint.withValues(alpha: isDark ? 0.15 : 1.0)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            if (selecting)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    activeColor: AppColors.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (_) => onTap(),
                  ),
                ),
              ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                size: 20,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    entry.path,
                    style: GoogleFonts.dmSans(fontSize: 12, color: secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!selecting)
              Icon(
                inLibrary ? Icons.check_circle_outline : Icons.chevron_right,
                size: 18,
                color: inLibrary ? AppColors.brand : secondary,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar (floats above the pill nav)
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.count,
    required this.collectionName,
    required this.bottomPadding,
    required this.onAdd,
  });

  final int count;
  final String? collectionName;
  final double bottomPadding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final label = collectionName != null
        ? 'Add $count to "$collectionName"'
        : 'Add $count to collection…';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPadding),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onAdd,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onBrand,
          ),
        ),
      ),
    );
  }
}
