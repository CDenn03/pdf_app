import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:sefer/features/reader/presentation/book_curl_frame.dart';
import 'package:sefer/features/reader/presentation/book_curl_math.dart';

/// Projects the lifted part of a page onto the page beneath, from a fixed
/// light. Inputs are in canonical coordinates, with the spine at x = 0.
abstract final class BookCurlShadows {
  static const _lightXY = Offset(-0.7, -0.25);
  static const _lightZ = 1.0;
  static const _liftedAbove = 1e-4;
  static const _foldBandFraction = 0.25;
  static const _blurPerLift = 0.4;
  static const _fadeSpan = 0.15;

  static BookCurlShadow cast({
    required List<Offset> screen,
    required Float64List depths,
    required double turnFraction,
    required BookCurlStyle style,
  }) {
    var maxLift = 0.0;
    for (final depth in depths) {
      maxLift = math.max(maxLift, depth);
    }
    if (maxLift <= _liftedAbove) return BookCurlShadow.none;
    final outline = <Offset>[];
    final cast = <Offset>[];
    final fold = <Offset>[];
    for (var i = 0; i < screen.length; i++) {
      final lift = depths[i];
      if (lift <= _liftedAbove) continue;
      final shadow = screen[i] - _lightXY * (lift / _lightZ);
      outline
        ..add(screen[i])
        ..add(shadow);
      cast.add(shadow);
      if (lift <= maxLift * _foldBandFraction) fold.add(screen[i]);
    }
    final fade =
        smoothstep(0, _fadeSpan, turnFraction) *
        smoothstep(0, _fadeSpan, 1 - turnFraction);
    return BookCurlShadow(
      footprint: convexHull(outline),
      foldPoint: _centroid(fold.isEmpty ? cast : fold),
      castPoint: _centroid(cast),
      opacity: style.shadowOpacity * fade,
      blurSigma: math.min(maxLift * _blurPerLift, style.maxShadowBlur),
    );
  }

  static Offset _centroid(List<Offset> points) {
    var sum = Offset.zero;
    for (final point in points) {
      sum += point;
    }
    return sum / points.length.toDouble();
  }
}
