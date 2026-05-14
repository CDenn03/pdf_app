import 'package:flutter/material.dart';

import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/core/theme/scroll_direction.dart';
import 'package:pdf_app/shared/widgets/overlay_panel.dart';

/// Shows the "More" panel with reading mode and scroll direction options.
Future<void> showMorePanel({
  required BuildContext context,
  required ReadingMode currentMode,
  required void Function(ReadingMode) onModeChanged,
  required ScrollDirection currentScrollDirection,
  required void Function(ScrollDirection) onScrollDirectionChanged,
}) {
  return OverlayPanel.show(
    context: context,
    title: 'Options',
    builder: (ctx) => _MorePanelContent(
      currentMode: currentMode,
      onModeChanged: (mode) {
        onModeChanged(mode);
        Navigator.of(ctx).pop();
      },
      currentScrollDirection: currentScrollDirection,
      onScrollDirectionChanged: (dir) {
        onScrollDirectionChanged(dir);
        Navigator.of(ctx).pop();
      },
    ),
  );
}

class _MorePanelContent extends StatelessWidget {
  const _MorePanelContent({
    required this.currentMode,
    required this.onModeChanged,
    required this.currentScrollDirection,
    required this.onScrollDirectionChanged,
  });

  final ReadingMode currentMode;
  final void Function(ReadingMode) onModeChanged;
  final ScrollDirection currentScrollDirection;
  final void Function(ScrollDirection) onScrollDirectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Reading mode ---
          Text('Reading mode', style: theme.textTheme.labelMedium),
          const SizedBox(height: 12),
          Row(
            children: ReadingMode.values.map((mode) {
              final isActive = mode == currentMode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ModeChip(
                    label: mode.label,
                    background: mode.background,
                    textColor: mode.primaryText,
                    isActive: isActive,
                    onTap: () => onModeChanged(mode),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // --- Scroll direction ---
          Text('Scroll', style: theme.textTheme.labelMedium),
          const SizedBox(height: 12),
          Row(
            children: ScrollDirection.values.map((dir) {
              final isActive = dir == currentScrollDirection;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ModeChip(
                    label: dir.label,
                    background: theme.colorScheme.surface,
                    textColor: theme.colorScheme.onSurface,
                    isActive: isActive,
                    onTap: () => onScrollDirectionChanged(dir),
                    leading: Icon(
                      dir == ScrollDirection.paginated
                          ? Icons.swap_horiz
                          : Icons.swap_vert,
                      size: 16,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.background,
    required this.textColor,
    required this.isActive,
    required this.onTap,
    this.leading,
  });

  final String label;
  final Color background;
  final Color textColor;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : theme.dividerColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? theme.colorScheme.primary : textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
