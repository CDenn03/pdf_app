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

  /// Toggles the favorite status of an entry.
  Future<void> toggleFavorite(String id) async {
    final updated = (state.value ?? []).map((e) {
      return e.id == id ? e.copyWith(isFavorite: !e.isFavorite) : e;
    }).toList();
    state = AsyncData(updated);
    await _persist();
  }

  /// Renames a library entry (display name only; does not rename the file).
  Future<void> renameFile(String id, String newName) async {
    final updated = (state.value ?? []).map((e) {
      return e.id == id ? e.copyWith(name: newName) : e;
    }).toList();
    state = AsyncData(updated);
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
// Device files notifier — all PDFs found on device
// ---------------------------------------------------------------------------

/// Manages the list of all PDF files found on the device via storage scan.
///
/// Not persisted — re-scanned on each app start.
class DeviceFilesNotifier extends AsyncNotifier<List<LibraryEntry>> {
  late final FileChecker _fileChecker;
  late final PdfScanner _scanner;

  /// True when the last scan was blocked by a denied storage permission.
  bool permissionDenied = false;

  @override
  Future<List<LibraryEntry>> build() async {
    _fileChecker = ref.read(fileServiceProvider);
    _scanner = ref.read(pdfScannerProvider);
    return scan();
  }

  Future<List<LibraryEntry>> scan() async {
    state = const AsyncLoading();
    final paths = await _scanner.scanForPdfs();
    permissionDenied =
        paths.isEmpty && !await _scanner.checkPermission();
    final entries = await Future.wait(
      paths.map((path) async {
        final status = await _fileChecker.checkFile(path);
        return LibraryEntry(
          id: path,
          name: p.basename(path),
          path: path,
          status: status,
        );
      }),
    );
    state = AsyncData(entries);
    return entries;
  }
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
    final updated = <PdfCollection>[...(state.value ?? []), PdfCollection(id: uuid.v4(), name: name)];
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

final deviceFilesProvider =
    AsyncNotifierProvider<DeviceFilesNotifier, List<LibraryEntry>>(
      DeviceFilesNotifier.new,
    );

final collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<PdfCollection>>(
      CollectionsNotifier.new,
    );
