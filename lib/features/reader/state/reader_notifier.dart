import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/features/reader/state/reader_state.dart';

/// Manages the PDF reader state: current page, zoom, document info.
///
/// This is intentionally separate from [AnnotationNotifier] to prevent
/// rebuild storms — per architecture spec, reader and annotation state
/// must never be merged.
class ReaderNotifier extends StateNotifier<ReaderState> {
  ReaderNotifier() : super(const ReaderState());

  /// Called when a PDF document is loaded.
  void onDocumentLoaded({required String pdfId, required int totalPages}) {
    state = state.copyWith(
      pdfId: pdfId,
      totalPages: totalPages,
      currentPage: 1,
      isLoaded: true,
    );
  }

  /// Called when the user navigates to a different page.
  void onPageChanged(int page) {
    state = state.copyWith(currentPage: page);
  }
}
