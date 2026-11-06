import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/device/domain/device_pdf_entry.dart';
import 'package:sefer/features/device/presentation/device_entry_format.dart';
import 'package:sefer/shared/widgets/file_list_tile.dart';

class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.entry,
    required this.inLibrary,
    required this.isSelected,
    required this.selecting,
    required this.onTap,
    this.isFavorite = false,
    this.onLongPress,
    this.onOverflow,
  });

  final DevicePdfEntry entry;
  final bool inLibrary;
  final bool isFavorite;
  final bool isSelected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onOverflow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isSelected
        ? AppColors.brandTint.withValues(alpha: isDark ? 0.15 : 1.0)
        : Colors.transparent;

    return FileListTile(
      title: entry.name,
      subtitle: deviceEntrySubtitle(entry),
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
          ? (isFavorite ? const _FavoriteMark() : null)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFavorite) const _FavoriteMark(),
                if (inLibrary)
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.brand,
                  ),
                if (onOverflow != null)
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

class _FavoriteMark extends StatelessWidget {
  const _FavoriteMark();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.favorite,
        size: 16,
        color: AppColors.brand,
        semanticLabel: 'Favorite',
      ),
    );
  }
}
