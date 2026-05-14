import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pdf_app/features/library/state/library_providers.dart';
import 'package:pdf_app/shared/widgets/selectable_file_list.dart';

/// Shows all PDF files found on the device via storage scan.
///
/// Long-press any item to enter multi-select mode, then bulk-add to library
/// or a specific collection. Tapping a single file opens it directly.
class DevicePage extends ConsumerStatefulWidget {
  const DevicePage({super.key, this.searchQuery = ''});

  final String searchQuery;

  @override
  ConsumerState<DevicePage> createState() => DevicePageState();
}

class DevicePageState extends ConsumerState<DevicePage> {
  final _controller = SelectableListController();

  /// Called by [HomeShell] when the user switches tabs.
  void clearSelection() => _controller.clearSelection();

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(deviceFilesProvider);
    final theme = Theme.of(context);
    final q = widget.searchQuery.toLowerCase().trim();

    final entries = q.isEmpty
        ? all
        : all.where((e) => e.name.toLowerCase().contains(q)).toList();

    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_android_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No PDFs found on device',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Grant storage permission and tap refresh to scan.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.read(deviceFilesProvider.notifier).scan(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Scan device'),
              ),
            ],
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No results for "${widget.searchQuery}"',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(deviceFilesProvider.notifier).scan(),
      child: SelectableFileList(
        controller: _controller,
        entries: entries,
        showPath: true,
        onOpenFile: (entry) async {
          await ref.read(libraryEntriesProvider.notifier).addFile(entry.path);
          ref.read(libraryEntriesProvider.notifier).recordOpened(entry.path);
          if (context.mounted) context.go('/reader', extra: entry.path);
        },
        onSelectionChanged: (_) {},
      ),
    );
  }
}
