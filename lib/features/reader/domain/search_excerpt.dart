import 'package:flutter/foundation.dart';

@immutable
class SearchExcerpt {
  const SearchExcerpt({
    required this.before,
    required this.match,
    required this.after,
    this.hasLeadingEllipsis = false,
    this.hasTrailingEllipsis = false,
  });

  const SearchExcerpt.plain(String text)
    : this(before: '', match: text, after: '');

  final String before;
  final String match;
  final String after;
  final bool hasLeadingEllipsis;
  final bool hasTrailingEllipsis;

  String get fullText =>
      '${hasLeadingEllipsis ? '… ' : ''}$before$match$after'
      '${hasTrailingEllipsis ? ' …' : ''}';

  @override
  bool operator ==(Object other) =>
      other is SearchExcerpt &&
      other.before == before &&
      other.match == match &&
      other.after == after &&
      other.hasLeadingEllipsis == hasLeadingEllipsis &&
      other.hasTrailingEllipsis == hasTrailingEllipsis;

  @override
  int get hashCode => Object.hash(
    before,
    match,
    after,
    hasLeadingEllipsis,
    hasTrailingEllipsis,
  );
}
