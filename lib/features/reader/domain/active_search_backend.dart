import 'dart:async';

import 'package:sefer/features/reader/domain/active_viewport_slot.dart';
import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/reader_search_backend.dart';
import 'package:sefer/features/reader/domain/search_backend_detached_exception.dart';

class ActiveSearchBackend implements ReaderSearchBackend {
  final ActiveViewportSlot<ReaderSearchBackend> _slot = ActiveViewportSlot();
  final Set<_RunningSearch> _running = {};

  void attach(Object owner, ReaderSearchBackend target) =>
      _slot.attach(owner, target);

  void detach(Object owner) {
    if (!_slot.detach(owner)) return;
    for (final search in _running.toList()) {
      search.abort();
    }
    _running.clear();
  }

  @override
  Stream<List<ReaderPageMatch>> search(String query) {
    final target = _slot.active;
    if (target == null) return const Stream.empty();
    final running = _RunningSearch(target.search(query));
    _running.add(running);
    running.onFinished = () => _running.remove(running);
    return running.stream;
  }

  @override
  Future<bool> reveal(ReaderPageMatch match, {required double margin}) async =>
      await _slot.active?.reveal(match, margin: margin) ?? false;
}

/// Forwards one scan and, when aborted, reports the scan as detached instead
/// of finished, so consumers never mistake a cut-off scan for a complete one.
class _RunningSearch {
  _RunningSearch(Stream<List<ReaderPageMatch>> scan) {
    _output = StreamController<List<ReaderPageMatch>>(
      onCancel: () {
        onFinished?.call();
        return _input.cancel();
      },
    );
    _input = scan.listen(
      _output.add,
      onError: _output.addError,
      onDone: () {
        onFinished?.call();
        unawaited(_output.close());
      },
    );
  }

  late final StreamController<List<ReaderPageMatch>> _output;
  late final StreamSubscription<List<ReaderPageMatch>> _input;
  void Function()? onFinished;

  Stream<List<ReaderPageMatch>> get stream => _output.stream;

  void abort() {
    unawaited(_input.cancel());
    _output.addError(const SearchBackendDetachedException());
  }
}
