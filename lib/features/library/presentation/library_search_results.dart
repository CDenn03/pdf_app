import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/library/domain/annotation_search.dart';
import 'package:sefer/features/library/presentation/annotation_search_tile.dart';
import 'package:sefer/features/library/presentation/library_entry_tile.dart';
import 'package:sefer/features/library/state/library_entry.dart';

/// Search-mode slivers: matching books, then annotations grouped by book.
List<Widget> librarySearchSlivers({
  required BuildContext context,
  required String query,
  required List<LibraryEntry> books,
  required List<AnnotationSearchHit> annotationHits,
  bool annotationsLoading = false,
  bool annotationsError = false,
}) {
  final annotationGroups = groupHitsByBook(annotationHits);
  final noBooks = books.isEmpty;
  final noAnnotations = !annotationsLoading && annotationGroups.isEmpty;

  if (noBooks && noAnnotations && !annotationsLoading) {
    return [
      SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'No results for "$query"',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ];
  }

  return [
    if (books.isNotEmpty) ...[
      const SliverToBoxAdapter(child: SectionLabel('Books')),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => LibraryEntryTile(entry: books[i]),
          childCount: books.length,
        ),
      ),
    ],
    if (annotationsLoading)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      )
    else if (annotationsError)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Could not search notes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      )
    else if (annotationGroups.isNotEmpty) ...[
      const SliverToBoxAdapter(child: SectionLabel('Annotations')),
      for (final group in annotationGroups) ...[
        SliverToBoxAdapter(child: _BookGroupHeader(name: group.bookName)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => AnnotationSearchTile(hit: group.hits[i]),
            childCount: group.hits.length,
          ),
        ),
      ],
    ],
  ];
}

class _BookGroupHeader extends StatelessWidget {
  const _BookGroupHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.headlineMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
