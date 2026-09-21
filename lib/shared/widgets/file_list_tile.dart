import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';

/// A file row with a gradient PDF icon, title, optional subtitle and trailing.
///
/// Shared across Library, Device, and Collection lists so the row's look and
/// unavailable-state styling stay identical everywhere.
class FileListTile extends StatelessWidget {
  const FileListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.gradientSeed,
    this.unavailable = false,
    this.leadingOverride,
    this.trailing,
    this.iconSize = 44,
    this.onTap,
    this.onLongPress,
    this.background = Colors.transparent,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;

  /// Value hashed to pick a cover gradient. Defaults to [title].
  final Object? gradientSeed;
  final bool unavailable;

  /// Replaces the gradient icon (e.g. a selection checkbox).
  final Widget? leadingOverride;
  final Widget? trailing;
  final double iconSize;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color background;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final seed = (gradientSeed ?? title).hashCode.abs();

    final row = Row(
      children: [
        ?leadingOverride,
        if (leadingOverride == null)
          _GradientIcon(
            size: iconSize,
            unavailable: unavailable,
            seed: seed,
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: unavailable ? scheme.onSurfaceVariant : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (unavailable)
                Text(
                  'File unavailable',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                )
              else if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: background,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          child: row,
        ),
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({
    required this.size,
    required this.unavailable,
    required this.seed,
  });

  final double size;
  final bool unavailable;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: unavailable
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.coverGradientAt(seed),
              ),
        color: unavailable ? scheme.surfaceContainerHighest : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        Icons.picture_as_pdf_outlined,
        size: size * 0.45,
        color: unavailable
            ? scheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}
