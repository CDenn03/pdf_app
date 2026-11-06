import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/utils/time_ago.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/shared/widgets/file_list_tile.dart';

class RecentTile extends StatelessWidget {
  const RecentTile({
    super.key,
    required this.entry,
    required this.isFavorite,
    required this.isSelected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
    required this.onOverflow,
  });

  final RecentEntry entry;
  final bool isFavorite;
  final bool isSelected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onOverflow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FileListTile(
      title: entry.name.replaceAll('.pdf', ''),
      subtitle: formatTimeAgo(entry.openedAt),
      gradientSeed: entry.path,
      background: isSelected
          ? AppColors.brandTint.withValues(alpha: isDark ? 0.15 : 1.0)
          : Colors.transparent,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: selecting
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Checkbox(
                value: isSelected,
                activeColor: AppColors.brand,
                onChanged: (_) => onTap(),
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFavorite)
            const Icon(
              Icons.favorite,
              size: 16,
              color: AppColors.brand,
              semanticLabel: 'Favorite',
            ),
          if (!selecting)
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'File actions for ${entry.name}',
              onPressed: onOverflow,
            ),
        ],
      ),
    );
  }
}
