import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

/// The active annotation tool within annotation mode.
enum AnnotationTool { highlight, note, bookmark }

/// Bottom toolbar shown when annotation mode is active.
///
/// Contains tool selector, color picker, undo, and exit.
/// The undo button is enabled only when [canUndoAnnotationProvider] is true.
class AnnotationToolbar extends ConsumerWidget {
  const AnnotationToolbar({
    super.key,
    required this.activeTool,
    required this.onToolChanged,
    required this.onExit,
    required this.onUndo,
  });

  final AnnotationTool activeTool;
  final void Function(AnnotationTool) onToolChanged;
  final VoidCallback onExit;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeColor = ref.watch(activeAnnotationColorProvider);
    final canUndo = ref.watch(canUndoAnnotationProvider);
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFFFFF9C4).withValues(alpha: 0.95),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _ToolButton(
                icon: Icons.highlight,
                label: 'Highlight',
                selected: activeTool == AnnotationTool.highlight,
                onTap: () => onToolChanged(AnnotationTool.highlight),
              ),
              _ToolButton(
                icon: Icons.sticky_note_2_outlined,
                label: 'Note',
                selected: activeTool == AnnotationTool.note,
                onTap: () => onToolChanged(AnnotationTool.note),
              ),
              _ToolButton(
                icon: Icons.bookmark_outline,
                label: 'Bookmark',
                selected: activeTool == AnnotationTool.bookmark,
                onTap: () => onToolChanged(AnnotationTool.bookmark),
              ),
              if (activeTool != AnnotationTool.bookmark) ...[
                const SizedBox(width: 4),
                _ColorPicker(
                  activeColor: activeColor,
                  onColorSelected: (color) {
                    ref.read(activeAnnotationColorProvider.notifier).state =
                        color;
                  },
                ),
              ],
              const Spacer(),
              // Undo button — greyed out when nothing to undo.
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                tooltip: 'Undo',
                onPressed: canUndo ? onUndo : null,
                color: theme.colorScheme.onSurface,
                disabledColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
              ),
              TextButton.icon(
                onPressed: onExit,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Done'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  textStyle: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.activeColor,
    required this.onColorSelected,
  });

  final AnnotationColor activeColor;
  final void Function(AnnotationColor) onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AnnotationColor.values.map((color) {
        final isActive = color == activeColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: color.solid,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.black54 : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
