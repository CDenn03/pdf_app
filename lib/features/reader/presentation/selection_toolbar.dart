import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Copy and Share actions floating next to [selectionBounds], which is in the
/// coordinate space of the layer the toolbar fills.
class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    super.key,
    required this.selectionBounds,
    required this.onCopy,
    required this.onShare,
  });

  final Rect selectionBounds;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  static void _absorbTap() {}

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(foregroundColor: Colors.black87);
    return CustomSingleChildLayout(
      delegate: _ToolbarLayoutDelegate(selectionBounds),
      child: GestureDetector(
        onTap: _absorbTap,
        child: Material(
          color: Colors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: style,
                onPressed: onCopy,
                child: const Text('Copy'),
              ),
              TextButton(
                style: style,
                onPressed: onShare,
                child: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarLayoutDelegate extends SingleChildLayoutDelegate {
  const _ToolbarLayoutDelegate(this.selectionBounds);

  static const _gap = 8.0;
  static const _handleClearance = 36.0;

  final Rect selectionBounds;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final above = selectionBounds.top - _gap - childSize.height;
    final below = selectionBounds.bottom + _handleClearance;
    final top = above >= 0 ? above : below;
    final left = selectionBounds.center.dx - childSize.width / 2;
    return Offset(
      left.clamp(0.0, math.max(0.0, size.width - childSize.width)),
      top.clamp(0.0, math.max(0.0, size.height - childSize.height)),
    );
  }

  @override
  bool shouldRelayout(_ToolbarLayoutDelegate oldDelegate) =>
      oldDelegate.selectionBounds != selectionBounds;
}
