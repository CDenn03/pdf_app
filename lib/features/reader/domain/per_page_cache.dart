import 'dart:async';

/// Loads each page's value once, sharing a load that is still running and
/// retrying after one that failed.
class PerPageCache<T> {
  PerPageCache({required Future<T> Function(int pageNumber) load})
    : _load = load;

  final Future<T> Function(int pageNumber) _load;
  final Map<int, Future<T>> _byPage = {};

  Future<T> of(int pageNumber) {
    final cached = _byPage[pageNumber];
    if (cached != null) return cached;
    final loading = _load(pageNumber);
    _byPage[pageNumber] = loading;
    unawaited(_forgetIfFailed(pageNumber, loading));
    return loading;
  }

  Future<void> _forgetIfFailed(int pageNumber, Future<T> loading) async {
    try {
      await loading;
    } catch (_) {
      unawaited(_byPage.remove(pageNumber));
    }
  }
}
