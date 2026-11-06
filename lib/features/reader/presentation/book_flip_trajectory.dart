import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/presentation/book_flip_interaction.dart';

/// The path a released finger follows until the turn has settled. The finger
/// leaves along its own velocity on a cubic Hermite curve and comes to rest
/// at [target], so the twist built up by a diagonal drag unwinds on the way.
@immutable
class BookFlipTrajectory {
  const BookFlipTrajectory._({
    required this.release,
    required this.target,
    required this.duration,
    required Offset exitTangent,
  }) : _exitTangent = exitTangent;

  static const _tangentCap = 1.0;

  /// [target] is where the finger ends; [release] carries the velocity.
  factory BookFlipTrajectory.from({
    required BookFlipPose release,
    required BookFlipPose target,
    required Duration duration,
  }) {
    final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final tangent = release.velocity * seconds;
    final reach = (target.current - release.current).distance;
    final limit = reach * _tangentCap;
    return BookFlipTrajectory._(
      release: release,
      target: target,
      duration: duration,
      exitTangent: tangent.distance > limit && tangent.distance > 0
          ? tangent * (limit / tangent.distance)
          : tangent,
    );
  }

  final BookFlipPose release;
  final BookFlipPose target;
  final Duration duration;
  final Offset _exitTangent;

  /// The pose after [fraction] of the settle, from 0 to 1.
  BookFlipPose poseAt(double fraction) {
    final t = fraction.clamp(0.0, 1.0);
    final t2 = t * t;
    final t3 = t2 * t;
    final startWeight = 2 * t3 - 3 * t2 + 1;
    final tangentWeight = t3 - 2 * t2 + t;
    final endWeight = -2 * t3 + 3 * t2;
    final slope = _slopeWeights(t);
    final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final velocity = seconds == 0
        ? Offset.zero
        : (release.current * slope.$1 +
                  _exitTangent * slope.$2 +
                  target.current * slope.$3) /
              seconds;
    return BookFlipPose(
      start: release.start,
      current:
          release.current * startWeight +
          _exitTangent * tangentWeight +
          target.current * endWeight,
      velocity: t >= 1 ? Offset.zero : velocity,
      turnFraction: lerpDouble(
        release.turnFraction,
        target.turnFraction,
        Curves.easeOut.transform(t),
      )!,
    );
  }

  (double, double, double) _slopeWeights(double t) {
    final t2 = t * t;
    return (6 * t2 - 6 * t, 3 * t2 - 4 * t + 1, 6 * t - 6 * t2);
  }
}
