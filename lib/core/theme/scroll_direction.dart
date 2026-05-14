/// The scroll layout mode for the PDF viewer.
enum ScrollDirection {
  /// One page at a time, swiped left/right (default).
  paginated,

  /// All pages in a continuous vertical scroll.
  continuous,
}

extension ScrollDirectionX on ScrollDirection {
  String get label => switch (this) {
    ScrollDirection.paginated => 'Paginated',
    ScrollDirection.continuous => 'Continuous',
  };
}
