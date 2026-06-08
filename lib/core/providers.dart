import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/database/database_helper.dart';
import 'package:pdf_app/core/database/note_entry_dao.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/services/app_settings_service.dart';
import 'package:pdf_app/core/services/file_service.dart';
import 'package:pdf_app/core/services/reading_progress_service.dart';
import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/core/theme/scroll_direction.dart';

/// Core infrastructure providers shared across features.

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  final helper = DatabaseHelper();
  // Close the database when the provider is disposed (e.g. in tests or on
  // hot-restart) so the next ProviderScope gets a fresh connection (#1).
  ref.onDispose(() async {
    final db = await helper.database;
    await db.close();
  });
  return helper;
});

final annotationDaoProvider = Provider<AnnotationDao>((ref) {
  return AnnotationDao(dbHelper: ref.watch(databaseHelperProvider));
});

final noteEntryDaoProvider = Provider<NoteEntryDao>((ref) {
  return NoteEntryDao(dbHelper: ref.watch(databaseHelperProvider));
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

/// Exposes and persists global app settings (reading mode, scroll direction).
///
/// Starts with the hardcoded fallback and loads persisted values
/// asynchronously on first build.
final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

/// Notifier for [AppSettings].
///
/// Loads from [AppSettingsStore] on build and persists on every mutation.
class AppSettingsNotifier extends Notifier<AppSettings> {
  late final Future<void> ready;

  @override
  AppSettings build() {
    ready = _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final settings = await ref.read(appSettingsServiceProvider).load();
    state = settings;
  }

  /// Updates the global reading mode and persists it.
  Future<void> setReadingMode(ReadingMode mode) async {
    state = state.copyWith(readingMode: mode);
    await ref.read(appSettingsServiceProvider).save(state);
  }

  /// Updates the global scroll direction and persists it.
  Future<void> setScrollDirection(ScrollDirection direction) async {
    state = state.copyWith(scrollDirection: direction);
    await ref.read(appSettingsServiceProvider).save(state);
  }

  /// Updates the app theme mode and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(appSettingsServiceProvider).save(state);
  }
}

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
