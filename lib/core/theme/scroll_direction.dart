/// The scroll layout mode for the PDF viewer.
enum ScrollDirection {
  /// Two pages shown side-by-side (default).
  sideBySide,

  /// All pages in a continuous vertical scroll.
  continuous,

  /// Book-style page flip animation.
  bookFlip,
}

extension ScrollDirectionX on ScrollDirection {
  String get label => switch (this) {
    ScrollDirection.sideBySide => 'Side by Side',
    ScrollDirection.continuous => 'Continuous',
    ScrollDirection.bookFlip => 'Book Flip',
  };
}
