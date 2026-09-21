import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_spacing.dart';

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({super.key, required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xxxl,
        AppSpacing.xxxl,
        bottomPadding + AppSpacing.xxxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 52,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Your library is empty', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Go to Device tab to add PDFs.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
