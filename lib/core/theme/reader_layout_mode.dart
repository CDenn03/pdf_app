enum ReaderLayoutMode {
  continuous,
  paged,
  bookFlip;

  static const ReaderLayoutMode defaultMode = ReaderLayoutMode.paged;

  String get label => switch (this) {
    ReaderLayoutMode.continuous => 'Continuous',
    ReaderLayoutMode.paged => 'Swipe Pages',
    ReaderLayoutMode.bookFlip => 'Book Flip',
  };

  bool get isPaginated => this != ReaderLayoutMode.continuous;

  int get annotationPreloadWindow => isPaginated ? 1 : 3;
}

String encodeReaderLayoutMode(ReaderLayoutMode mode) => switch (mode) {
  ReaderLayoutMode.continuous => 'continuous',
  ReaderLayoutMode.paged => 'paged',
  ReaderLayoutMode.bookFlip => 'bookFlip',
};

ReaderLayoutMode decodeReaderLayoutMode(String? token) => switch (token) {
  'continuous' => ReaderLayoutMode.continuous,
  'paged' || 'sideBySide' => ReaderLayoutMode.paged,
  'bookFlip' => ReaderLayoutMode.bookFlip,
  _ => ReaderLayoutMode.defaultMode,
};
