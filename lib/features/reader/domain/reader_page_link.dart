import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
sealed class ReaderLinkTarget {
  const ReaderLinkTarget();
}

final class PageLinkTarget extends ReaderLinkTarget {
  const PageLinkTarget(this.pageNumber);

  final int pageNumber;

  @override
  bool operator ==(Object other) =>
      other is PageLinkTarget && other.pageNumber == pageNumber;

  @override
  int get hashCode => pageNumber.hashCode;
}

final class UriLinkTarget extends ReaderLinkTarget {
  const UriLinkTarget(this.uri);

  final Uri uri;

  @override
  bool operator ==(Object other) => other is UriLinkTarget && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;
}

@immutable
class ReaderPageLink {
  const ReaderPageLink({required this.target, required this.normalizedBounds});

  final ReaderLinkTarget target;

  /// Fractions (0..1) of the upright page's width and height, with the origin
  /// at the page's top-left corner and y growing downwards.
  final List<Rect> normalizedBounds;
}

abstract interface class ReaderPageLinkSource {
  Future<List<ReaderPageLink>> linksOn(int pageNumber);
}
