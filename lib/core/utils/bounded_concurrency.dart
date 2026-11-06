/// Maps [items] through [transform] with at most [limit] calls in flight.
///
/// Results keep the order of [items].
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  int limit,
  Future<R> Function(T item) transform,
) async {
  final results = List<R?>.filled(items.length, null);
  var next = 0;

  Future<void> worker() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await transform(items[index]);
    }
  }

  final workerCount = limit < items.length ? limit : items.length;
  await Future.wait([for (var i = 0; i < workerCount; i++) worker()]);
  return results.cast<R>();
}
