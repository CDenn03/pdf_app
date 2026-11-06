import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/services/collections_service.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/core/services/recents_service.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/main.dart';

import 'support/library_fakes.dart';

mixin class _GatedLoad {
  final started = Completer<void>();
  final release = Completer<void>();

  Future<void> waitForRelease() async {
    if (!started.isCompleted) started.complete();
    await release.future;
  }
}

class _GatedSettingsStore extends _GatedLoad implements AppSettingsStore {
  @override
  Future<AppSettings> load() async {
    await waitForRelease();
    return const AppSettings();
  }

  @override
  Future<void> save(AppSettings settings) async {}
}

class _GatedLibraryPersistence extends _GatedLoad
    implements LibraryPersistence {
  @override
  Future<List<PersistedEntry>> loadEntries() async {
    await waitForRelease();
    return const [];
  }

  @override
  Future<void> saveEntries(List<LibraryEntry> entries) async {}
}

class _GatedCollectionsService extends CollectionsService with _GatedLoad {
  @override
  Future<List<PdfCollection>> load() async {
    await waitForRelease();
    return const [];
  }

  @override
  Future<void> save(List<PdfCollection> collections) async {}
}

class _GatedRecentsStore extends _GatedLoad implements RecentsStore {
  @override
  Future<List<RecentEntry>> load() async {
    await waitForRelease();
    return const [];
  }

  @override
  Future<void> recordOpened(String path, String name) async {}

  @override
  Future<void> moveEntry({
    required String oldPath,
    required String newPath,
    required String newName,
  }) async {}

  @override
  Future<void> remove(String path) async {}
}

void main() {
  test(
    'startup readiness starts all stores and waits for every load',
    () async {
      final settings = _GatedSettingsStore();
      final library = _GatedLibraryPersistence();
      final collections = _GatedCollectionsService();
      final recents = _GatedRecentsStore();
      final container = ProviderContainer(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(settings),
          fileServiceProvider.overrideWithValue(FakeFileChecker()),
          libraryPersistenceProvider.overrideWithValue(library),
          collectionsServiceProvider.overrideWithValue(collections),
          recentsStoreProvider.overrideWithValue(recents),
        ],
      );
      addTearDown(container.dispose);

      var completed = false;
      final readiness = container.read(startupReadinessProvider.future);
      unawaited(readiness.then((_) => completed = true));

      await Future.wait([
        settings.started.future,
        library.started.future,
        collections.started.future,
        recents.started.future,
      ]);
      expect(completed, isFalse);

      settings.release.complete();
      library.release.complete();
      collections.release.complete();
      expect(completed, isFalse);

      recents.release.complete();
      await readiness;
      expect(completed, isTrue);
    },
  );
}
