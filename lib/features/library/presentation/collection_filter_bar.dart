import 'package:flutter/material.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/library/domain/annotation_search.dart';

/// Horizontal chips to narrow library search to a collection or favorites.
class CollectionFilterBar extends StatelessWidget {
  const CollectionFilterBar({
    super.key,
    required this.collections,
    required this.filter,
    required this.onFilterSelected,
    this.showFavorites = false,
  });

  final List<PdfCollection> collections;
  final LibrarySearchFilter filter;
  final ValueChanged<LibrarySearchFilter> onFilterSelected;
  final bool showFavorites;

  bool get _visible => collections.isNotEmpty || showFavorites;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.sm,
        ),
        children: [
          _FilterChip(
            label: 'All',
            selected: filter is SearchAllBooks,
            onTap: () => onFilterSelected(const SearchAllBooks()),
          ),
          if (showFavorites)
            _FilterChip(
              label: 'Favorites',
              selected: filter is SearchFavorites,
              onTap: () => onFilterSelected(const SearchFavorites()),
            ),
          for (final collection in collections)
            _FilterChip(
              label: collection.name,
              selected: switch (filter) {
                SearchInCollection(:final collectionId) =>
                  collectionId == collection.id,
                _ => false,
              },
              onTap: () => onFilterSelected(SearchInCollection(collection.id)),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected ? AppColors.brand : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected
                      ? AppColors.brand
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.onBrand : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
