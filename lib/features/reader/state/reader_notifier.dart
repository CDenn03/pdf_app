import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/core/utils/debounce.dart';
import 'package:sefer/features/reader/state/reader_state.dart';

/// Manages the PDF reader state: current page, document info, and resume.
///
/// Intentionally separate from [AnnotationNotifier] to prevent rebuild
/// storms — reader and annotation state must never be merged.
class ReaderNotifier extends Notifier<ReaderState> {
  late final ReadingProgressStore _progressStore;
  final Debounce _persistDebounce =
      Debounce(duration: const Duration(milliseconds: 400));

  @override
  ReaderState build() {
    _progressStore = ref.read(readingProgressProvider);
    ref.onDispose(_persistDebounce.dispose);
    return const ReaderState();
  }

  /// Called when a PDF document is loaded.
  ///
  /// Loads the persisted resume page so the viewer can jump to it.
  Future<void> onDocumentLoaded({
    required String pdfId,
    required int totalPages,
  }) async {
    int resumePage = 1;
    try {
      resumePage = await _progressStore.getLastPage(pdfId);
      resumePage = resumePage.clamp(1, totalPages);
    } catch (e, s) {
      developer.log(
        'Failed to load resume page for $pdfId',
        name: 'sefer.reader',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }

    state = state.copyWith(
      pdfId: pdfId,
      totalPages: totalPages,
      currentPage: resumePage,
      resumePage: resumePage,
      isLoaded: true,
    );
  }

  /// Called when the user navigates to a different page.
  ///
  /// Persists the new page so it can be resumed next session. Writes are
  /// refused until a document with a real id is loaded, so pdfrx's initial
  /// `onPageChanged(1)` cannot overwrite stored progress with junk, and are
  /// debounced so rapid page changes collapse into a single write.
  void onPageChanged(int page) {
    if (!state.isLoaded || state.pdfId.isEmpty) return;
    state = state.copyWith(currentPage: page);
    final pdfId = state.pdfId;
    _persistDebounce.run(() => _progressStore.saveLastPage(pdfId, page));
  }
}
