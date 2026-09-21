import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/shared/widgets/file_list_tile.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.entry,
    required this.inLibrary,
    required this.isSelected,
    required this.selecting,
    required this.onTap,
    this.onLongPress,
  });

  final LibraryEntry entry;
  final bool inLibrary;
  final bool isSelected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final background = isSelected
        ? AppColors.brandTint.withValues(alpha: isDark ? 0.15 : 1.0)
        : Colors.transparent;

    return FileListTile(
      title: entry.name,
      subtitle: entry.path,
      gradientSeed: entry.path,
      background: background,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: selecting
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppColors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (_) => onTap(),
                ),
              ),
            )
          : null,
      trailing: selecting
          ? null
          : Icon(
              inLibrary ? Icons.check_circle_outline : Icons.chevron_right,
              size: 18,
              color: inLibrary ? AppColors.brand : scheme.onSurfaceVariant,
            ),
    );
  }
}
