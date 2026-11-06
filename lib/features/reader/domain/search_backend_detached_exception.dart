class SearchBackendDetachedException implements Exception {
  const SearchBackendDetachedException();

  @override
  String toString() => 'The search backend was detached mid-scan';
}
