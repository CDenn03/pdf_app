import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/database/database_helper.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/services/app_settings_service.dart';
import 'package:pdf_app/core/services/file_service.dart';
import 'package:pdf_app/core/services/reading_progress_service.dart';

/// Core infrastructure providers shared across features.

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

final appSettingsServiceProvider = Provider<AppSettingsStore>((ref) {
  return AppSettingsService();
});

// ---------------------------------------------------------------------------
// Simple value providers — defined here (in core) so that AnnotationNotifier
// can reference them without a circular import with the reader state providers.
// ---------------------------------------------------------------------------

/// The currently selected annotation color. Persists within a session.
final activeAnnotationColorProvider =
    NotifierProvider<_ValueNotifier<AnnotationColor>, AnnotationColor>(
      () => _ValueNotifier(AnnotationColor.yellow),
    );

/// Whether there is an annotation that can be undone.
/// Updated by AnnotationNotifier on every add/undo/remove.
final canUndoAnnotationProvider = NotifierProvider<_ValueNotifier<bool>, bool>(
  () => _ValueNotifier(false),
);

// ---------------------------------------------------------------------------
// Internal
// ---------------------------------------------------------------------------

/// A minimal [Notifier] that holds a single mutable value.
class _ValueNotifier<T> extends Notifier<T> {
  _ValueNotifier(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  // ignore: use_setters_to_change_properties
  void setValue(T value) => state = value;
}
