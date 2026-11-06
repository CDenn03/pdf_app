import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/core/utils/debounce.dart';
import 'package:sefer/features/reader/domain/page_range.dart';
import 'package:sefer/features/reader/state/reader_state.dart';

/// Manages the PDF reader state: current page, document info, and resume.
///
/// Intentionally separate from [AnnotationNotifier] to prevent rebuild
/// storms — reader and annotation state must never be merged.
class ReaderNotifier extends Notifier<ReaderState> {
  late final ReadingProgressStore _progressStore;
  final Debounce _persistDebounce = Debounce(
    duration: const Duration(milliseconds: 400),
  );
  Future<void> _lastSave = Future.value();

  @override
  ReaderState build() {
    _progressStore = ref.read(readingProgressProvider);
    ref.onDispose(_persistDebounce.flush);
    return const ReaderState();
  }

  /// Loads the saved page for [pdfId] once; later calls reuse the result.
  /// An explicit [initialPage] wins over the saved one.
  ///
  /// The page is not clamped here because the page count is unknown until
  /// [onDocumentLoaded].
  Future<int> loadResumePage(String pdfId, {int? initialPage}) async {
    if (state.pdfId == pdfId) return state.resumePage;
    final savedPage = initialPage ?? await _readSavedPage(pdfId);
    state = state.copyWith(
      pdfId: pdfId,
      currentPage: savedPage,
      resumePage: savedPage,
    );
    return savedPage;
  }

  Future<void> onDocumentLoaded({
    required String pdfId,
    required int totalPages,
  }) async {
    final savedPage = await loadResumePage(pdfId);
    final range = PageRange(totalPages);
    if (state.isLoaded) {
      state = state.copyWith(
        totalPages: totalPages,
        currentPage: range.clamp(state.currentPage),
      );
      return;
    }
    final resumePage = range.clamp(savedPage);
    state = state.copyWith(
      totalPages: totalPages,
      currentPage: resumePage,
      resumePage: resumePage,
      isLoaded: true,
    );
  }

  /// Writes are debounced and flushed on dispose.
  void onPageChanged(int reportedPage) {
    if (!state.isLoaded || state.pdfId.isEmpty) return;
    final page = PageRange(state.totalPages).clamp(reportedPage);
    state = state.copyWith(currentPage: page);
    final pdfId = state.pdfId;
    _persistDebounce.run(() => _lastSave = _savePage(pdfId, page));
  }

  Future<void> flushProgress() async {
    _persistDebounce.flush();
    await _lastSave;
  }

  Future<int> _readSavedPage(String pdfId) async {
    try {
      return max(1, await _progressStore.getLastPage(pdfId));
    } catch (e, s) {
      developer.log(
        'Failed to load resume page for $pdfId',
        name: 'sefer.reader',
        level: 900,
        error: e,
        stackTrace: s,
      );
      return 1;
    }
  }

  Future<void> _savePage(String pdfId, int page) async {
    try {
      await _progressStore.saveLastPage(pdfId, page);
    } catch (e, s) {
      developer.log(
        'Failed to save page $page for $pdfId',
        name: 'sefer.reader',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }
  }
}
