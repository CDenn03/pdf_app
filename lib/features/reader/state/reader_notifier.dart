import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/features/reader/state/reader_state.dart';

/// Manages the PDF reader state: current page, document info, and resume.
///
/// Intentionally separate from [AnnotationNotifier] to prevent rebuild
/// storms — reader and annotation state must never be merged.
class ReaderNotifier extends Notifier<ReaderState> {
  late final ReadingProgressStore _progressStore;

  @override
  ReaderState build() {
    _progressStore = ref.read(readingProgressProvider);
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
  /// Persists the new page so it can be resumed next session.
  void onPageChanged(int page) {
    state = state.copyWith(currentPage: page);
    _progressStore.saveLastPage(state.pdfId, page);
  }
}
