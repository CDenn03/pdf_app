import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/domain/search_excerpt.dart';

@immutable
class ReaderPageMatch {
  const ReaderPageMatch({
    required this.pageNumber,
    required this.excerpt,
    required this.normalizedBounds,
  });

  final int pageNumber;
  final SearchExcerpt excerpt;

  /// Fractions (0..1) of the upright page's width and height, with the origin
  /// at the page's top-left corner and y growing downwards.
  final List<Rect> normalizedBounds;

  @override
  bool operator ==(Object other) =>
      other is ReaderPageMatch &&
      other.pageNumber == pageNumber &&
      other.excerpt == excerpt &&
      listEquals(other.normalizedBounds, normalizedBounds);

  @override
  int get hashCode =>
      Object.hash(pageNumber, excerpt, Object.hashAll(normalizedBounds));
}
