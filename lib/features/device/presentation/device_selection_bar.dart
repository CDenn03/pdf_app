import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';

class DeviceSelectionHeader extends StatelessWidget {
  const DeviceSelectionHeader({
    super.key,
    required this.count,
    required this.total,
    required this.onToggleAll,
  });

  final int count;
  final int total;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.brandTint.withValues(alpha: 0.12)
        : AppColors.brandTint;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Checkbox(
            value: count == total && total > 0,
            tristate: true,
            activeColor: AppColors.brand,
            onChanged: (_) => onToggleAll(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            count > 0 ? '$count selected' : 'Select files',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.brand),
          ),
        ],
      ),
    );
  }
}

class DeviceActionBar extends StatelessWidget {
  const DeviceActionBar({
    super.key,
    required this.count,
    required this.collectionName,
    required this.bottomPadding,
    required this.onAdd,
  });

  final int count;
  final String? collectionName;
  final double bottomPadding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = collectionName != null
        ? 'Add $count to "$collectionName"'
        : 'Add $count to collection…';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md - 2,
        AppSpacing.lg,
        AppSpacing.md - 2 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onAdd,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.onBrand,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.onBrand,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
