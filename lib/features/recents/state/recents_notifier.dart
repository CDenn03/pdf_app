import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:pdf_app/core/services/recents_service.dart';

export 'package:pdf_app/core/services/recents_service.dart' show RecentEntry;

/// Provider typed to the abstract interface so tests can swap in a fake (#18).
final recentsStoreProvider = Provider<RecentsStore>((ref) => RecentsService());

/// Notifier that tracks all recently opened PDFs, including files not
/// in the library. Persisted across restarts via [RecentsStore].
class RecentsNotifier extends Notifier<List<RecentEntry>> {
  late final RecentsStore _service;

  @override
  List<RecentEntry> build() {
    _service = ref.read(recentsStoreProvider);
    _load();
    return [];
  }

  Future<void> _load() async {
    state = await _service.load();
  }

  /// Records that the file at [path] was opened right now.
  Future<void> recordOpened(String path) async {
    await _service.recordOpened(path, p.basename(path));
    state = await _service.load();
  }
}

final recentsProvider =
    NotifierProvider<RecentsNotifier, List<RecentEntry>>(RecentsNotifier.new);
