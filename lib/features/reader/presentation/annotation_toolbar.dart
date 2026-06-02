import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/theme/reading_mode.dart';
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
    required this.readingMode,
  });

  final AnnotationTool activeTool;
  final void Function(AnnotationTool) onToolChanged;
  final VoidCallback onExit;
  final VoidCallback onUndo;
  final ReadingMode readingMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeColor = ref.watch(activeAnnotationColorProvider);
    final canUndo = ref.watch(canUndoAnnotationProvider);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: readingMode.controlSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: readingMode.primaryText.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
            children: [
              // Tool buttons — each gets equal space, text truncates if needed.
              Expanded(
                child: _ToolButton(
                  icon: Icons.highlight,
                  label: 'Highlight',
                  selected: activeTool == AnnotationTool.highlight,
                  color: readingMode.primaryText,
                  onTap: () => onToolChanged(AnnotationTool.highlight),
                ),
              ),
              Expanded(
                child: _ToolButton(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Note',
                  selected: activeTool == AnnotationTool.note,
                  color: readingMode.primaryText,
                  onTap: () => onToolChanged(AnnotationTool.note),
                ),
              ),
              Expanded(
                child: _ToolButton(
                  icon: Icons.bookmark_outline,
                  label: 'Bookmark',
                  selected: activeTool == AnnotationTool.bookmark,
                  color: readingMode.primaryText,
                  onTap: () => onToolChanged(AnnotationTool.bookmark),
                ),
              ),
              // Color picker — only for highlight/note, fixed width.
              if (activeTool != AnnotationTool.bookmark)
                _ColorPicker(
                  activeColor: activeColor,
                  onColorSelected: (color) {
                    ref
                        .read(activeAnnotationColorProvider.notifier)
                        .setValue(color);
                  },
                ),
              // Undo + Done — fixed width.
              IconButton(
                icon: Icon(
                  Icons.undo,
                  size: 20,
                  color: canUndo
                      ? readingMode.primaryText
                      : readingMode.primaryText.withValues(alpha: 0.3),
                ),
                tooltip: 'Undo',
                onPressed: canUndo ? onUndo : null,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
              TextButton(
                onPressed: onExit,
                style: TextButton.styleFrom(
                  foregroundColor: readingMode.primaryText,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(48, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Done', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
              size: 18,
              color: selected ? theme.colorScheme.primary : color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? theme.colorScheme.primary : color,
              ),
              overflow: TextOverflow.ellipsis,
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
