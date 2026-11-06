import 'package:flutter/material.dart';

/// A draggable end of the text selection, hanging below [anchor].
///
/// Raises [dragging] from the first touch so the page gallery stops claiming
/// the gesture before it has moved.
class SelectionHandle extends StatelessWidget {
  const SelectionHandle({
    super.key,
    required this.anchor,
    required this.layerSize,
    required this.color,
    required this.dragging,
    required this.onDragStart,
    required this.onDragUpdate,
  });

  static const touchSize = 44.0;
  static const _knobDiameter = 16.0;
  static const _hangAboveAnchor = 8.0;

  final Offset anchor;
  final Size layerSize;
  final Color color;
  final ValueNotifier<bool> dragging;
  final ValueChanged<Offset> onDragStart;
  final ValueChanged<Offset> onDragUpdate;

  static void _absorbTap() {}

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _clamped(anchor.dx - touchSize / 2, layerSize.width),
      top: _clamped(anchor.dy - _hangAboveAnchor, layerSize.height),
      width: touchSize,
      height: touchSize,
      child: Listener(
        onPointerDown: (_) => dragging.value = true,
        onPointerUp: (_) => dragging.value = false,
        onPointerCancel: (_) => dragging.value = false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _absorbTap,
          onPanStart: (details) => onDragStart(details.globalPosition),
          onPanUpdate: (details) => onDragUpdate(details.globalPosition),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: _hangAboveAnchor),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: _knobDiameter),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _clamped(double origin, double extent) =>
      origin.clamp(0.0, (extent - touchSize).clamp(0.0, double.infinity));
}
