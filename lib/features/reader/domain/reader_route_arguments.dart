class ReaderRouteArguments {
  const ReaderRouteArguments({
    required this.path,
    this.initialPage,
    this.recordOpened = true,
  });

  final String path;
  final int? initialPage;
  final bool recordOpened;
}
