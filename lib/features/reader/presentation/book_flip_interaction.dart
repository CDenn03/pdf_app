import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/domain/book_flip_machine.dart';

/// Whether the page's free edge is its right edge while turning in
/// [direction]; the spine is on the opposite side.
bool bookFlipFreeEdgeIsRight(
  BookFlipDirection direction,
  TextDirection textDirection,
) =>
    (direction == BookFlipDirection.forward) ==
    (textDirection == TextDirection.ltr);

/// Where a turn is grabbed and where the finger is now, in page-normalized
/// coordinates: (0, 0) is the page's top-left and (1, 1) its bottom-right.
/// [current] may leave the page while a turn settles. [velocity] is in page
/// sizes per second.
@immutable
class BookFlipPose {
  BookFlipPose({
    required this.start,
    required this.current,
    required this.velocity,
    required this.turnFraction,
  }) : assert(_isFinite(start) && _isFinite(current) && _isFinite(velocity)),
       assert(turnFraction >= 0 && turnFraction <= 1);

  final Offset start;
  final Offset current;
  final Offset velocity;
  final double turnFraction;

  static bool _isFinite(Offset value) => value.isFinite;

  static BookFlipPose lerp(BookFlipPose a, BookFlipPose b, double t) =>
      BookFlipPose(
        start: Offset.lerp(a.start, b.start, t)!,
        current: Offset.lerp(a.current, b.current, t)!,
        velocity: Offset.lerp(a.velocity, b.velocity, t)!,
        turnFraction: lerpDouble(a.turnFraction, b.turnFraction, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is BookFlipPose &&
      other.start == start &&
      other.current == current &&
      other.velocity == velocity &&
      other.turnFraction == turnFraction;

  @override
  int get hashCode => Object.hash(start, current, velocity, turnFraction);
}
