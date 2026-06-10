import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/core/utils/share_utils.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({
    super.key,
    this.bottomPadding = 0,
    this.onAddToCollection,
  });

  final double bottomPadding;
  final void Function(String collectionId)? onAddToCollection;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    // .value ?? [] gracefully handles loading/error states from AsyncNotifier (#16).
    final entries = ref.watch(libraryEntriesProvider).value ?? [];
    final collections = ref.watch(collectionsProvider).value ?? [];
    final recents = ref.watch(recentsProvider);
    final q = _query.toLowerCase().trim();
    final searching = q.isNotEmpty;
    final results = searching
        ? entries.where((e) => e.name.toLowerCase().contains(q)).toList()
        : const <LibraryEntry>[];

    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSearch();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GreetingHeader(subtitle: timeGreeting, title: 'Library'),
          ),
          SliverToBoxAdapter(
            child: PageSearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              hintText: 'Search library…',
            ),
          ),
          if (searching) ...[
            if (results.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No results for "$q"',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _EntryTile(entry: results[i]),
                  childCount: results.length,
                ),
              ),
          ] else ...[
            if (recents.isNotEmpty)
              SliverToBoxAdapter(
                child: _RecentFilesSection(
                  recents: recents.take(6).toList(),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'COLLECTIONS',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _createCollection(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: _CollectionGrid(
                collections: collections,
                entries: entries,
                onAddToCollection: widget.onAddToCollection,
              ),
            ),
            if (entries.isEmpty && collections.isEmpty && recents.isEmpty)
              SliverFillRemaining(
                child: _EmptyHome(bottomPadding: widget.bottomPadding),
              ),
          ],
          SliverToBoxAdapter(
            child: SizedBox(height: widget.bottomPadding + 8),
          ),
        ],
      ),
    );
  }

  Future<void> _createCollection(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
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
    if (name == null || name.trim().isEmpty) return;
    await ref.read(collectionsProvider.notifier).addCollection(name.trim());
  }
}

// ---------------------------------------------------------------------------
// Recently opened horizontal strip
// ---------------------------------------------------------------------------

class _RecentFilesSection extends ConsumerWidget {
  const _RecentFilesSection({required this.recents});

  final List<RecentEntry> recents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            'RECENTLY OPENED',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recents.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                _RecentCard(entry: recents[i], colorIndex: i),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard({required this.entry, required this.colorIndex});

  final RecentEntry entry;
  final int colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primary =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final gradient = AppColors.coverGradientAt(colorIndex);

    // Semantics added so screen readers announce the card as a button (#14).
    return Semantics(
      button: true,
      label: 'Open ${entry.name.replaceAll('.pdf', '')}',
      child: GestureDetector(
        onTap: () {
          ref.read(recentsProvider.notifier).recordOpened(entry.path);
          context.push('/reader', extra: entry.path);
        },
        onLongPress: () {
          final libraryEntry = ref
              .read(libraryEntriesProvider)
              .value
              ?.where((e) => e.path == entry.path)
              .firstOrNull;
          showModalBottomSheet<void>(
            context: context,
            builder: (_) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.open_in_new_outlined),
                    title: const Text('Open'),
                    onTap: () {
                      Navigator.pop(context);
                      ref
                          .read(recentsProvider.notifier)
                          .recordOpened(entry.path);
                      context.push('/reader', extra: entry.path);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Share'),
                    onTap: () {
                      Navigator.pop(context);
                      sharePdf(context, entry.path);
                    },
                  ),
                  if (libraryEntry != null)
                    ListTile(
                      leading: const Icon(Icons.drive_file_rename_outline),
                      title: const Text('Rename'),
                      onTap: () async {
                        Navigator.pop(context);
                        final newName = await showRenameDialog(
                          context,
                          currentName: libraryEntry.name,
                        );
                        if (newName == null || newName.trim().isEmpty) return;
                        await ref
                            .read(libraryEntriesProvider.notifier)
                            .renameFile(libraryEntry.id, newName);
                      },
                    ),
                ],
              ),
            ),
          );
        },
        child: Container(
          width: 96,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 28,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name.replaceAll('.pdf', ''),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _timeAgo(entry.openedAt),
                      style: GoogleFonts.dmSans(fontSize: 10, color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---------------------------------------------------------------------------
// Collection grid: Favorites card first, then user collections (asymmetric)
// ---------------------------------------------------------------------------

class _CollectionGrid extends StatelessWidget {
  const _CollectionGrid({
    required this.collections,
    required this.entries,
    this.onAddToCollection,
  });

  final List<PdfCollection> collections;
  final List<LibraryEntry> entries;
  final void Function(String id)? onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final favCount = entries.where((e) => e.isFavorite).length;

    // Pre-compute per-collection counts once — O(n·m) total rather than O(n²)
    // from repeated indexOf calls (#21).
    final collectionCounts = {
      for (var i = 0; i < collections.length; i++)
        i: entries.where((e) => e.collectionId == collections[i].id).length,
    };

    // Total cards = 1 favourites + n collections.
    final cardCount = 1 + collections.length;
    final rowCount = (cardCount / 2).ceil();

    Widget cardAt(int index) {
      if (index == 0) return _FavoritesCard(count: favCount);
      final colIndex = index - 1;
      final col = collections[colIndex];
      return _CollectionCard(
        collection: col,
        count: collectionCounts[colIndex] ?? 0,
        // colIndex + 1 so Favorites (index 0) uses gradient 0 and collections
        // start at 1 — no indexOf() needed (#21).
        colorIndex: colIndex + 1,
        onAdd: onAddToCollection != null ? () => onAddToCollection!(col.id) : null,
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, row) {
          final left = cardAt(row * 2);
          final rightIndex = row * 2 + 1;
          final right = rightIndex < cardCount ? cardAt(rightIndex) : null;
          final swapped = row % 2 == 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: right == null
                ? left
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: swapped
                          ? [
                              Expanded(flex: 2, child: right),
                              const SizedBox(width: 10),
                              Expanded(flex: 3, child: left),
                            ]
                          : [
                              Expanded(flex: 3, child: left),
                              const SizedBox(width: 10),
                              Expanded(flex: 2, child: right),
                            ],
                    ),
                  ),
          );
        },
        childCount: rowCount,
      ),
    );
  }
}

class _FavoritesCard extends StatelessWidget {
  const _FavoritesCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primary =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;

    return GestureDetector(
      onTap: () => context.push('/favorites'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 72,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B0000), Color(0xFFCC2936)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.favorite, size: 32, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorites',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  Text(
                    '$count file${count == 1 ? '' : 's'}',
                    style: GoogleFonts.dmSans(fontSize: 11, color: secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  const _CollectionCard({
    required this.collection,
    required this.count,
    required this.colorIndex,
    this.onAdd,
  });

  final PdfCollection collection;
  final int count;
  final int colorIndex;
  final VoidCallback? onAdd;

  Future<void> _onLongPress(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(context);
                await _rename(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);
                await _delete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: collection.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename collection'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(collectionsProvider.notifier).renameCollection(
          collection.id,
          name.trim(),
        );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text(
          '"${collection.name}" will be deleted. Files will not be removed.',
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
    await ref.read(collectionsProvider.notifier).deleteCollection(collection.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primary =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final gradient = AppColors.coverGradientAt(colorIndex);

    return GestureDetector(
      onTap: () => context.push('/collection/${collection.id}', extra: onAdd),
      onLongPress: () => _onLongPress(context, ref),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.collections_bookmark_outlined,
                      size: 28,
                      color: Colors.white70,
                    ),
                  ),
                  if (onAdd != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count file${count == 1 ? '' : 's'}',
                    style: GoogleFonts.dmSans(fontSize: 11, color: secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry tile (used in search results)
// ---------------------------------------------------------------------------

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primary =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final colorIndex = entry.path.hashCode.abs();
    final gradient = AppColors.coverGradientAt(colorIndex);
    final unavailable = entry.status != FileStatus.ok;

    final collections = ref.watch(collectionsProvider).value ?? [];
    final collectionName = entry.collectionId != null
        ? collections
            .where((c) => c.id == entry.collectionId)
            .map((c) => c.name)
            .firstOrNull
        : null;

    // Subtitle: collection name and/or favourite tag
    final tags = [
      ?collectionName,
      if (entry.isFavorite) 'Favorite',
    ];

    void open() {
      if (unavailable) return;
      ref.read(libraryEntriesProvider.notifier).recordOpened(entry.path);
      ref.read(recentsProvider.notifier).recordOpened(entry.path);
      context.push('/reader', extra: entry.path);
    }

    void showMenu() {
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!unavailable)
                ListTile(
                  leading: const Icon(Icons.open_in_new_outlined),
                  title: const Text('Open'),
                  onTap: () {
                    Navigator.pop(context);
                    open();
                  },
                ),
              if (!unavailable)
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(context);
                    sharePdf(context, entry.path);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('Rename'),
                onTap: () async {
                  Navigator.pop(context);
                  final newName = await showRenameDialog(
                    context,
                    currentName: entry.name,
                  );
                  if (newName == null || newName.trim().isEmpty) return;
                  await ref
                      .read(libraryEntriesProvider.notifier)
                      .renameFile(entry.id, newName);
                },
              ),
              if (entry.isFavorite)
                ListTile(
                  leading:
                      const Icon(Icons.favorite, color: AppColors.brand, size: 20),
                  title: const Text('Show in Favorites'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/favorites');
                  },
                ),
              if (collectionName != null)
                ListTile(
                  leading: const Icon(
                    Icons.collections_bookmark_outlined,
                  ),
                  title: Text('Show in "$collectionName"'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/collection/${entry.collectionId}');
                  },
                ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: unavailable ? null : open,
      onLongPress: showMenu,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: unavailable
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                color: unavailable
                    ? (isDark
                        ? AppColors.darkSurface
                        : const Color(0xFFEEEEEE))
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                size: 20,
                color: unavailable
                    ? secondary
                    : Colors.white.withValues(alpha: 0.9),
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
                      color: unavailable ? secondary : primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tags.isNotEmpty)
                    Text(
                      tags.join(' · '),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: secondary,
                      ),
                    ),
                ],
              ),
            ),
            if (entry.isFavorite)
              const Icon(Icons.favorite, size: 14, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(32, 32, 32, bottomPadding + 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 52,
              color: secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Your library is empty',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Device tab to add PDFs.',
              style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
