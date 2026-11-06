import 'package:flutter/foundation.dart';

@immutable
class PageRange {
  const PageRange(this.totalPages) : assert(totalPages >= 1);

  final int totalPages;

  int clamp(int pageNumber) => pageNumber.clamp(1, totalPages);

  int indexOf(int pageNumber) => clamp(pageNumber) - 1;

  int pageNumberAt(int index) => clamp(index + 1);

  @override
  bool operator ==(Object other) =>
      other is PageRange && other.totalPages == totalPages;

  @override
  int get hashCode => totalPages.hashCode;
}
