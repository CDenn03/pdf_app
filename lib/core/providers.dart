import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/database/database_helper.dart';
import 'package:pdf_app/core/services/file_service.dart';
import 'package:pdf_app/core/services/reading_progress_service.dart';

/// Core infrastructure providers shared across features.
///
/// Kept in `core/` so notifier files can import them without
/// creating circular dependencies with `features/reader/state/providers.dart`.

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final annotationDaoProvider = Provider<AnnotationDao>((ref) {
  return AnnotationDao(dbHelper: ref.watch(databaseHelperProvider));
});

final fileServiceProvider = Provider<FileChecker>((ref) {
  return const FileService();
});

final readingProgressProvider = Provider<ReadingProgressStore>((ref) {
  return ReadingProgressService();
});
