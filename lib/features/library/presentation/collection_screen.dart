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
class CollectionScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // .value ?? [] handles loading/error states from AsyncNotifier (#16).
    final allEntries = ref.watch(libraryEntriesProvider).value ?? [];
    final collections = ref.watch(collectionsProvider).value ?? [];

    final title = isFavorites
        ? 'Favorites'
        : collections
            .where((c) => c.id == collectionId)
            .map((c) => c.name)
            .firstOrNull ?? 'Collection';

    final entries = isFavorites
        ? allEntries.where((e) => e.isFavorite).toList()
        : allEntries.where((e) => e.collectionId == collectionId).toList();

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
              if (!isFavorites && onAddBook != null)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add book',
                  onPressed: () {
                    context.pop();
                    onAddBook!();
                  },
                ),
            ],
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  isFavorites ? 'No favorites yet.' : 'No files here yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _FileTile(entry: entries[i]),
                childCount: entries.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _FileTile extends ConsumerWidget {
  const _FileTile({required this.entry});

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
    final theme = Theme.of(context);

    return InkWell(
      onTap: unavailable
          ? null
          : () {
              ref.read(libraryEntriesProvider.notifier).recordOpened(entry.path);
              ref.read(recentsProvider.notifier).recordOpened(entry.path);
              context.push('/reader', extra: entry.path);
            },
      onLongPress: unavailable
          ? null
          : () => showModalBottomSheet<void>(
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
                              .read(libraryEntriesProvider.notifier)
                              .recordOpened(entry.path);
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
                    ],
                  ),
                ),
              ),
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
