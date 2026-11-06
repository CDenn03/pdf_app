abstract interface class ReaderPageNavigation {
  int get currentPage;

  Future<void> goToPage(int pageNumber);
}
