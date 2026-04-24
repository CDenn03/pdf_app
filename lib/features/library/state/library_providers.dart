import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/services/file_service.dart';
import 'package:pdf_app/features/library/state/library_entry.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

/// Notifier that manages the list of library entries.
/// Checks file status on load — never removes annotation records on missing files.
class LibraryNotifier extends StateNotifier<List<LibraryEntry>> {
  final FileChecker _fileChecker;

  LibraryNotifier(this._fileChecker) : super([]);

  /// Adds the bundled sample PDF as a library entry and checks its status.
  Future<void> addSample() async {
    final status = await _fileChecker.checkFile(kSamplePdfPath);
    final entry = LibraryEntry(
      id: uuid.v4(),
      name: 'sample.pdf',
      path: kSamplePdfPath,
      status: status,
    );
    state = [...state, entry];
  }

  /// Re-checks file status for all entries (e.g. on app resume).
  Future<void> refreshStatuses() async {
    final updated = await Future.wait(
      state.map((e) async {
        final status = await _fileChecker.checkFile(e.path);
        return e.copyWith(status: status);
      }),
    );
    state = updated;
  }
}

final libraryEntriesProvider =
    StateNotifierProvider<LibraryNotifier, List<LibraryEntry>>((ref) {
      return LibraryNotifier(ref.watch(fileServiceProvider));
    });
