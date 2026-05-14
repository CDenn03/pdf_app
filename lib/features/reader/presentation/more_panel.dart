import 'package:flutter/material.dart';

import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/shared/widgets/overlay_panel.dart';

/// Shows the "More" panel with reading mode selector and secondary actions.
Future<void> showMorePanel({
  required BuildContext context,
  required ReadingMode currentMode,
  required void Function(ReadingMode) onModeChanged,
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
    ),
  );
}

class _MorePanelContent extends StatelessWidget {
  const _MorePanelContent({
    required this.currentMode,
    required this.onModeChanged,
  });

  final ReadingMode currentMode;
  final void Function(ReadingMode) onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reading mode', style: theme.textTheme.labelMedium),
          const SizedBox(height: 12),
          Row(
            children: ReadingMode.values.map((mode) {
              final isActive = mode == currentMode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ModeChip(
                    mode: mode,
                    isActive: isActive,
                    onTap: () => onModeChanged(mode),
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
    required this.mode,
    required this.isActive,
    required this.onTap,
  });

  final ReadingMode mode;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: mode.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : theme.dividerColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            mode.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: mode.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
