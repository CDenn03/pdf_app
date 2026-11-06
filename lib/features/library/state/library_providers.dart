import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:sefer/core/constants.dart';
import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/services/collections_service.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/core/services/pdf_scan_service.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/reader/state/providers.dart';

// ---------------------------------------------------------------------------
// Library notifier — manually curated files
// ---------------------------------------------------------------------------

/// Manages the user's personal library: files they have explicitly added.
///
/// Persisted across restarts via [LibraryPersistence].
///
/// Converted to [AsyncNotifier] so errors from the init load propagate to
/// consumers via [AsyncValue.error] instead of being silently swallowed by
/// an async-void fire-and-forget (#16).
class LibraryNotifier extends AsyncNotifier<List<LibraryEntry>> {
  late final FileChecker _fileChecker;
  late final LibraryPersistence _persistence;

  @override
  Future<List<LibraryEntry>> build() async {
    _fileChecker = ref.read(fileServiceProvider);
    _persistence = ref.read(libraryPersistenceProvider);
    return _load();
  }

  Future<List<LibraryEntry>> _load() async {
    final persisted = await _persistence.loadEntries();

    if (persisted.isEmpty) {
      return _withSample([]);
    }

    return Future.wait(
      persisted.map((e) async {
        final status = await _fileChecker.checkFile(e.path);
        return LibraryEntry(
          id: e.id,
          name: e.name,
          path: e.path,
          status: status,
          lastOpenedAt: e.lastOpenedAt,
          collectionId: e.collectionId,
          isFavorite: e.isFavorite,
        );
      }),
    );
  }

  Future<List<LibraryEntry>> _withSample(List<LibraryEntry> current) async {
    if (current.any((e) => e.path == kSamplePdfPath)) return current;
    final status = await _fileChecker.checkFile(kSamplePdfPath);
    final updated = [
      ...current,
      LibraryEntry(
        id: uuid.v4(),
        name: 'sample.pdf',
        path: kSamplePdfPath,
        status: status,
      ),
    ];
    await _persistence.saveEntries(updated);
    return updated;
  }

  /// Adds a file to the library. No-op if already present.
  Future<void> addFile(String path, {String? collectionId}) async {
    final current = state.value ?? [];
    if (current.any((e) => e.path == path)) {
      await refreshStatuses();
      return;
    }
    final status = await _fileChecker.checkFile(path);
    final updated = [
      ...current,
      LibraryEntry(
        id: uuid.v4(),
        name: p.basename(path),
        path: path,
        status: status,
        collectionId: collectionId,
      ),
    ];
    state = AsyncData(updated);
    await _persist();
  }

  /// Removes a file from the library entirely.
  Future<void> removeFile(String id) async {
    final updated = (state.value ?? []).where((e) => e.id != id).toList();
    state = AsyncData(updated);
    await _persist();
  }

  /// Moves a file to a different collection (or null = root).
  Future<void> moveToCollection(String entryId, String? collectionId) async {
    final updated = (state.value ?? []).map((e) {
      return e.id == entryId ? e.copyWith(collectionId: collectionId) : e;
    }).toList();
    state = AsyncData(updated);
    await _persist();
  }

  /// Sets the favorite flag for every file in [paths].
  ///
  /// Idempotent. Waits for the initial load so an early call is not lost.
  /// Favoriting a path with no library entry creates a root entry for it;
  /// unfavoriting never removes an entry.
  Future<void> setFavoriteForPaths(
    Set<String> paths, {
    required bool favorite,
  }) async {
    if (paths.isEmpty) return;
    final loaded = await future;
    final current = state.value ?? loaded;
    bool needsChange(LibraryEntry e) =>
        paths.contains(e.path) && e.isFavorite != favorite;
    final existing = {for (final e in current) e.path};
    final missing = favorite ? paths.difference(existing) : <String>{};
    if (missing.isEmpty && !current.any(needsChange)) return;
    final created = [for (final path in missing) await _newFavoriteEntry(path)];
    state = AsyncData([
      for (final e in current)
        if (needsChange(e)) e.copyWith(isFavorite: favorite) else e,
      ...created,
    ]);
    await _persist();
  }

  Future<LibraryEntry> _newFavoriteEntry(String path) async {
    return LibraryEntry(
      id: uuid.v4(),
      name: p.basename(path),
      path: path,
      status: await _fileChecker.checkFile(path),
      isFavorite: true,
    );
  }

  /// Renames a library entry (display name only; does not rename the file).
  ///
  /// Use [applyRename] after an on-disk rename instead: this leaves [path]
  /// pointing at the old filename, so the entry's label and the file itself
  /// disagree.
  Future<void> renameFile(String id, String newName) async {
    final updated = (state.value ?? []).map((e) {
      return e.id == id ? e.copyWith(name: newName) : e;
    }).toList();
    state = AsyncData(updated);
    await _persist();
  }

  /// Repoints the entry at [oldPath] to [newPath] after the file itself has
  /// been renamed on disk.
  ///
  /// Matches on path rather than entry id so it works for a file that has no
  /// library entry (a no-op) as well as one that does, and so the caller does
  /// not have to resolve an id first. Collection membership, favorite flag
  /// and last-opened timestamp are preserved.
  Future<void> applyRename({
    required String oldPath,
    required String newPath,
    required String newName,
  }) async {
    final current = state.value ?? [];
    if (!current.any((e) => e.path == oldPath)) return;
    final updated = current.map((e) {
      return e.path == oldPath ? e.copyWith(path: newPath, name: newName) : e;
    }).toList();
    state = AsyncData(updated);
    await _persist();
  }

  /// Drops the entry for [path], if there is one. Leaves the file alone.
  Future<void> removeByPath(String path) async {
    final current = state.value ?? [];
    if (!current.any((e) => e.path == path)) return;
    final updated = current.where((e) => e.path != path).toList();
    state = AsyncData(updated);
    await _persist();
  }

  /// Re-adds a previously removed [entry] verbatim, for undo.
  ///
  /// Keeps the original id, collection and favorite flag, so undoing a
  /// "remove from library" restores the entry rather than creating a fresh
  /// one at the end of the list.
  Future<void> restoreEntry(LibraryEntry entry) async {
    final current = state.value ?? [];
    if (current.any((e) => e.path == entry.path)) return;
    state = AsyncData([...current, entry]);
    await _persist();
  }

  /// Records that the PDF at [path] was opened right now.
  Future<void> recordOpened(String path) async {
    final now = DateTime.now();
    final updated = (state.value ?? []).map((e) {
      return e.path == path ? e.copyWith(lastOpenedAt: now) : e;
    }).toList();
    state = AsyncData(updated);
    await _persist();
  }

  /// Re-checks file status for all entries.
  Future<void> refreshStatuses() async {
    final updated = await Future.wait(
      (state.value ?? []).map((e) async {
        final status = await _fileChecker.checkFile(e.path);
        return e.copyWith(status: status);
      }),
    );
    state = AsyncData(updated);
    await _persist();
  }

  Future<void> _persist() => _persistence.saveEntries(state.value ?? []);
}

// ---------------------------------------------------------------------------
// Collections notifier
// ---------------------------------------------------------------------------

class CollectionsNotifier extends AsyncNotifier<List<PdfCollection>> {
  late final CollectionsService _service;

  @override
  Future<List<PdfCollection>> build() async {
    _service = ref.read(collectionsServiceProvider);
    return _service.load();
  }

  Future<void> addCollection(String name) async {
    final updated = <PdfCollection>[
      ...(state.value ?? []),
      PdfCollection(id: uuid.v4(), name: name),
    ];
    state = AsyncData(updated);
    await _service.save(updated);
  }

  Future<void> renameCollection(String id, String newName) async {
    final updated = (state.value ?? []).map((c) {
      return c.id == id ? c.copyWith(name: newName) : c;
    }).toList();
    state = AsyncData(updated);
    await _service.save(updated);
  }

  Future<void> deleteCollection(String id) async {
    final updated = (state.value ?? []).where((c) => c.id != id).toList();
    state = AsyncData(updated);
    await _service.save(updated);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final libraryPersistenceProvider = Provider<LibraryPersistence>((ref) {
  return LibraryPersistenceService();
});

final collectionsServiceProvider = Provider<CollectionsService>((ref) {
  return CollectionsService();
});

final pdfScannerProvider = Provider<PdfScanner>((ref) {
  return const PdfScanService();
});

final libraryEntriesProvider =
    AsyncNotifierProvider<LibraryNotifier, List<LibraryEntry>>(
      LibraryNotifier.new,
    );

final favoritePathsProvider = Provider<Set<String>>((ref) {
  final entries = ref.watch(libraryEntriesProvider).value ?? const [];
  return {
    for (final entry in entries)
      if (entry.isFavorite) entry.path,
  };
});

final collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<PdfCollection>>(
      CollectionsNotifier.new,
    );
