import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pdf_app/core/models/file_status.dart';
import 'package:pdf_app/core/theme/app_colors.dart';
import 'package:pdf_app/core/utils/share_utils.dart';
import 'package:pdf_app/features/library/state/library_entry.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';
import 'package:pdf_app/features/recents/state/recents_notifier.dart';

/// Shows the files in a collection, or all favorites when [isFavorites] is true.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({
    super.key,
    this.collectionId,
    this.isFavorites = false,
    this.onAddBook,
  }) : assert(
          collectionId != null || isFavorites,
          'Provide collectionId or set isFavorites',
        );

  final String? collectionId;
  final bool isFavorites;

  /// Called when the user taps the add (+) button. Only shown for collections.
  final VoidCallback? onAddBook;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(libraryEntriesProvider).value ?? [];
    final collections = ref.watch(collectionsProvider).value ?? [];

    final title = widget.isFavorites
        ? 'Favorites'
        : collections
                .where((c) => c.id == widget.collectionId)
                .map((c) => c.name)
                .firstOrNull ??
            'Collection';

    final baseEntries = widget.isFavorites
        ? allEntries.where((e) => e.isFavorite).toList()
        : allEntries
            .where((e) => e.collectionId == widget.collectionId)
            .toList();

    final q = _query.toLowerCase().trim();
    final entries = q.isEmpty
        ? baseEntries
        : baseEntries.where((e) => e.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!widget.isFavorites && widget.onAddBook != null)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add book',
                  onPressed: () {
                    context.pop();
                    widget.onAddBook!();
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  q.isNotEmpty
                      ? 'No results for "$q"'
                      : widget.isFavorites
                          ? 'No favorites yet.'
                          : 'No files here yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _FileTile(
                  entry: entries[i],
                  inCollection: !widget.isFavorites,
                ),
                childCount: entries.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _FileTile extends ConsumerWidget {
  const _FileTile({required this.entry, required this.inCollection});

  final LibraryEntry entry;

  /// Whether this tile is shown inside a named collection (not Favorites).
  final bool inCollection;

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.status == FileStatus.ok) ...[
              ListTile(
                leading: const Icon(Icons.open_in_new_outlined),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(context);
                  _open(context, ref);
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
            ],
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(context);
                await _rename(context, ref);
              },
            ),
            if (inCollection)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Remove from collection'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(libraryEntriesProvider.notifier)
                      .moveToCollection(entry.id, null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    ref.read(libraryEntriesProvider.notifier).recordOpened(entry.path);
    ref.read(recentsProvider.notifier).recordOpened(entry.path);
    context.push('/reader', extra: entry.path);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final newName = await showRenameDialog(context, currentName: entry.name);
    if (newName == null || newName.trim().isEmpty) return;
    await ref.read(libraryEntriesProvider.notifier).renameFile(
          entry.id,
          newName,
        );
  }

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
    final theme = Theme.of(context);

    return InkWell(
      onTap: unavailable ? null : () => _open(context, ref),
      onLongPress: () => _showMenu(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                size: 22,
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
                    entry.name.replaceAll('.pdf', ''),
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: unavailable ? secondary : primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (unavailable)
                    Text(
                      'File unavailable',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            _FavoriteButton(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        entry.isFavorite ? Icons.favorite : Icons.favorite_border,
        size: 20,
        color: entry.isFavorite
            ? AppColors.brand
            : (Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText),
      ),
      onPressed: () =>
          ref.read(libraryEntriesProvider.notifier).toggleFavorite(entry.id),
    );
  }
}
