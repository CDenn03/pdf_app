import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum BookCurlEdge { left, right }

@immutable
class BookCurlStyle {
  const BookCurlStyle({
    this.rows = 20,
    this.columns = 32,
    this.radiusFraction = 0.16,
    this.perspective = 0.0006,
    this.touchBiasStrength = 0.45,
    this.spineBand = 0.04,
    this.backBase = 0.62,
    this.backHighlight = 0.28,
    this.shadowOpacity = 0.35,
    this.maxShadowBlur = 24,
  }) : assert(rows >= 1 && columns >= 1 && (rows + 1) * (columns + 1) < 65536);

  final int rows;
  final int columns;

  /// Largest curl radius as a fraction of the page width.
  final double radiusFraction;

  /// Shrink per unit of lift around the touch point, which sells depth.
  final double perspective;

  /// How strongly a touch above or below the middle tilts the fold.
  final double touchBiasStrength;

  /// Fraction of the page width beside the spine that stays pinned.
  final double spineBand;
  final double backBase;
  final double backHighlight;
  final double shadowOpacity;
  final double maxShadowBlur;

  @override
  bool operator ==(Object other) =>
      other is BookCurlStyle &&
      other.rows == rows &&
      other.columns == columns &&
      other.radiusFraction == radiusFraction &&
      other.perspective == perspective &&
      other.touchBiasStrength == touchBiasStrength &&
      other.spineBand == spineBand &&
      other.backBase == backBase &&
      other.backHighlight == backHighlight &&
      other.shadowOpacity == shadowOpacity &&
      other.maxShadowBlur == maxShadowBlur;

  @override
  int get hashCode => Object.hash(
    rows,
    columns,
    radiusFraction,
    perspective,
    touchBiasStrength,
    spineBand,
    backBase,
    backHighlight,
    shadowOpacity,
    maxShadowBlur,
  );
}

@immutable
class BookCurlNormal {
  const BookCurlNormal(this.x, this.y, this.z);

  static const flat = BookCurlNormal(0, 0, 1);

  final double x;
  final double y;
  final double z;

  BookCurlNormal get reversed => BookCurlNormal(-x, -y, -z);
}

/// One mesh point. [position] is where it lands on screen, [texturePosition]
/// where it sits on the flat page, both in page pixels. [depth] is its lift.
@immutable
class BookCurlVertex {
  const BookCurlVertex({
    required this.position,
    required this.texturePosition,
    required this.depth,
    required this.normal,
  });

  final Offset position;
  final Offset texturePosition;
  final double depth;
  final BookCurlNormal normal;
}

@immutable
class BookCurlShadow {
  const BookCurlShadow({
    required this.footprint,
    required this.foldPoint,
    required this.castPoint,
    required this.opacity,
    required this.blurSigma,
  });

  static const none = BookCurlShadow(
    footprint: [],
    foldPoint: Offset.zero,
    castPoint: Offset.zero,
    opacity: 0,
    blurSigma: 0,
  );

  /// Convex outline of the area the lifted sheet darkens.
  final List<Offset> footprint;
  final Offset foldPoint;
  final Offset castPoint;
  final double opacity;
  final double blurSigma;

  BookCurlShadow mirroredIn(double width) {
    Offset mirror(Offset point) => Offset(width - point.dx, point.dy);
    return BookCurlShadow(
      footprint: footprint.map(mirror).toList(),
      foldPoint: mirror(foldPoint),
      castPoint: mirror(castPoint),
      opacity: opacity,
      blurSigma: blurSigma,
    );
  }
}

/// A curled page as triangles over [vertices]. Indices come in threes;
/// [backIndices] are ordered from furthest to nearest.
@immutable
class BookCurlFrame {
  const BookCurlFrame({
    required this.vertices,
    required this.frontIndices,
    required this.backIndices,
    required this.shadow,
  });

  final List<BookCurlVertex> vertices;
  final Uint16List frontIndices;
  final Uint16List backIndices;
  final BookCurlShadow shadow;
}
