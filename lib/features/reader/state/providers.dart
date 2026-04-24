import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/database/database_helper.dart';
import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/services/file_service.dart';
import 'package:pdf_app/core/utils/debounce.dart';
import 'package:pdf_app/features/reader/state/annotation_notifier.dart';
import 'package:pdf_app/features/reader/state/reader_notifier.dart';
import 'package:pdf_app/features/reader/state/reader_state.dart';

// --- Core service providers ---

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final annotationDaoProvider = Provider<AnnotationDao>((ref) {
  return AnnotationDao(dbHelper: ref.watch(databaseHelperProvider));
});

final fileServiceProvider = Provider<FileChecker>((ref) {
  return const FileService();
});

// --- State notifier providers ---

/// Provider for reader state (page, zoom, pdf info).
/// Separate from annotation state to prevent rebuild storms.
final readerNotifierProvider =
    StateNotifierProvider<ReaderNotifier, ReaderState>((ref) {
      return ReaderNotifier();
    });

/// Provider for annotation state.
/// Only loads annotations for currentPage ± 1.
final annotationNotifierProvider =
    StateNotifierProvider<AnnotationNotifier, List<Annotation>>((ref) {
      return AnnotationNotifier(
        dao: ref.watch(annotationDaoProvider),
        debounce: Debounce(),
      );
    });
