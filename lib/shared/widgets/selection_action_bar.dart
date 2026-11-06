import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_spacing.dart';

class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    super.key,
    required this.selectedPaths,
    required this.favoritePaths,
    required this.onSetFavorite,
    this.extraActions = const [],
    this.bottomPadding = 0,
  });

  final Set<String> selectedPaths;
  final Set<String> favoritePaths;
  final ValueChanged<bool> onSetFavorite;
  final List<Widget> extraActions;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoriteCount = selectedPaths.where(favoritePaths.contains).length;
    final canMark = favoriteCount < selectedPaths.length;
    final canRemove = favoriteCount > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: [
          if (canMark)
            TextButton.icon(
              onPressed: () => onSetFavorite(true),
              icon: const Icon(Icons.favorite_border),
              label: const Text('Mark favorite'),
            ),
          if (canRemove)
            TextButton.icon(
              onPressed: () => onSetFavorite(false),
              icon: const Icon(Icons.heart_broken_outlined),
              label: const Text('Remove favorite'),
            ),
          ...extraActions,
        ],
      ),
    );
  }
}
