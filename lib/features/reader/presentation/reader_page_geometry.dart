import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class ReaderPageGeometry {
  const ReaderPageGeometry({
    required this.pageNumber,
    required this.pageSize,
    required this.renderedRect,
  });

  factory ReaderPageGeometry.fitted({
    required int pageNumber,
    required Size pageSize,
    required Size available,
  }) {
    final scale = math.min(
      available.width / pageSize.width,
      available.height / pageSize.height,
    );
    final fitted = Size(pageSize.width * scale, pageSize.height * scale);
    return ReaderPageGeometry(
      pageNumber: pageNumber,
      pageSize: pageSize,
      renderedRect: Alignment.center.inscribe(fitted, Offset.zero & available),
    );
  }

  final int pageNumber;
  final Size pageSize;
  final Rect renderedRect;

  @override
  bool operator ==(Object other) =>
      other is ReaderPageGeometry &&
      other.pageNumber == pageNumber &&
      other.pageSize == pageSize &&
      other.renderedRect == renderedRect;

  @override
  int get hashCode => Object.hash(pageNumber, pageSize, renderedRect);
}
