import 'package:flutter/material.dart';

/// A unified bottom-sheet panel used by TOC, Search, and Annotations.
///
/// All secondary features share this single panel structure:
/// header + scrollable list + tap-to-navigate. This prevents panel
/// explosion and keeps the mental model consistent.
///
/// Usage:
/// ```dart
/// OverlayPanel.show(
///   context: context,
///   title: 'Table of Contents',
///   builder: (context) => TocPanelContent(...),
/// );
/// ```
class OverlayPanel extends StatelessWidget {
  const OverlayPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;

  /// Optional widget placed at the end of the header row (e.g. a filter).
  final Widget? trailing;

  /// Shows this panel as a modal bottom sheet.
  ///
  /// Set [isDismissible] to false to prevent the sheet from being dismissed
  /// by tapping the scrim or dragging it down — useful for panels like Search
  /// where the user needs to interact with content behind the sheet while
  /// keeping the panel open.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
    Widget? trailing,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: isDismissible,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      builder: (ctx) =>
          OverlayPanel(title: title, trailing: trailing, child: builder(ctx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Panel occupies 85% of screen height max.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(title: title, trailing: trailing),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ?trailing,
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
