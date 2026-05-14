import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pdf_app/features/device/presentation/device_page.dart';
import 'package:pdf_app/features/library/presentation/library_page.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';
import 'package:pdf_app/features/recents/presentation/recents_page.dart';

/// Root shell with three tabs: Library / Device / Recents.
///
/// Each tab has its own search bar. Device and Recents support multi-select
/// for bulk-adding files to the library or a collection.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;
  bool _searchActive = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Keys to access page state for clearing selection on tab switch.
  final _deviceKey = GlobalKey<DevicePageState>();
  final _recentsKey = GlobalKey<RecentsPageState>();

  static const _tabs = [
    _TabItem(label: 'Library', icon: Icons.collections_bookmark_outlined),
    _TabItem(label: 'Device', icon: Icons.phone_android_outlined),
    _TabItem(label: 'Recents', icon: Icons.history_outlined),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    // Clear any active selection on the tab we're leaving.
    if (_selectedIndex == 1) _deviceKey.currentState?.clearSelection();
    if (_selectedIndex == 2) _recentsKey.currentState?.clearSelection();

    setState(() {
      _selectedIndex = index;
      _searchActive = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    await ref.read(libraryEntriesProvider.notifier).addFile(path);
    if (mounted) context.go('/reader', extra: path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(
                _tabs[_selectedIndex].label,
                style: theme.textTheme.titleMedium,
              ),
        actions: [
          IconButton(
            icon: Icon(
              _searchActive ? Icons.close : Icons.search_outlined,
              size: 22,
            ),
            tooltip: _searchActive ? 'Cancel' : 'Search',
            onPressed: _toggleSearch,
          ),
          if (_selectedIndex == 0 && !_searchActive)
            IconButton(
              icon: const Icon(Icons.add_outlined, size: 22),
              tooltip: 'Add PDF',
              onPressed: _importFile,
            ),
          if (_selectedIndex == 1 && !_searchActive)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 22),
              tooltip: 'Rescan device',
              onPressed: () => ref.read(deviceFilesProvider.notifier).scan(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          LibraryPage(searchQuery: _searchQuery),
          DevicePage(key: _deviceKey, searchQuery: _searchQuery),
          RecentsPage(key: _recentsKey, searchQuery: _searchQuery),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabChanged,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;

  const _TabItem({required this.label, required this.icon});
}
