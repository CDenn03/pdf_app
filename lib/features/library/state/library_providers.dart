import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/models/collection.dart';
import 'package:pdf_app/core/services/collections_service.dart';
import 'package:pdf_app/core/services/file_service.dart';
import 'package:pdf_app/core/services/library_persistence_service.dart';
import 'package:pdf_app/core/services/pdf_scan_service.dart';
import 'package:pdf_app/features/library/state/library_entry.dart';
import 'package:pdf_app/features/reader/state/providers.dart';

// ---------------------------------------------------------------------------
// Library notifier — manually curated files
// ---------------------------------------------------------------------------

/// Manages the user's personal library: files they have explicitly added.
///
/// Persisted across restarts via [LibraryPersistence].
class LibraryNotifier extends Notifier<List<LibraryEntry>> {
  late final FileChecker _fileChecker;
  late final LibraryPersistence _persistence;

  @override
  List<LibraryEntry> build() {
    _fileChecker = ref.read(fileServiceProvider);
    _persistence = ref.read(libraryPersistenceProvider);
    _init();
    return [];
  }

  Future<void> _init() async {
    final persisted = await _persistence.loadEntries();

    if (persisted.isEmpty) {
      await _addSample();
      return;
    }

    final restored = await Future.wait(
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
    state = restored;
  }

  Future<void> _addSample() async {
    if (state.any((e) => e.path == kSamplePdfPath)) return;
    final status = await _fileChecker.checkFile(kSamplePdfPath);
    state = [
      ...state,
      LibraryEntry(
        id: uuid.v4(),
        name: 'sample.pdf',
        path: kSamplePdfPath,
        status: status,
      ),
    ];
    await _persist();
  }

  /// Adds a file to the library. No-op if already present.
  Future<void> addFile(String path, {String? collectionId}) async {
    if (state.any((e) => e.path == path)) {
      await refreshStatuses();
      return;
    }
    final status = await _fileChecker.checkFile(path);
    state = [
      ...state,
      LibraryEntry(
        id: uuid.v4(),
        name: p.basename(path),
        path: path,
        status: status,
        collectionId: collectionId,
      ),
    ];
    await _persist();
  }

  /// Removes a file from the library entirely.
  Future<void> removeFile(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _persist();
  }

  /// Moves a file to a different collection (or null = root).
  Future<void> moveToCollection(String entryId, String? collectionId) async {
    state = state.map((e) {
      return e.id == entryId ? e.copyWith(collectionId: collectionId) : e;
    }).toList();
    await _persist();
  }

  /// Toggles the favorite status of an entry.
  Future<void> toggleFavorite(String id) async {
    state = state.map((e) {
      return e.id == id ? e.copyWith(isFavorite: !e.isFavorite) : e;
    }).toList();
    await _persist();
  }

  /// Renames a library entry (display name only; does not rename the file).
  Future<void> renameFile(String id, String newName) async {
    state = state.map((e) {
      return e.id == id ? e.copyWith(name: newName) : e;
    }).toList();
    await _persist();
  }

  /// Records that the PDF at [path] was opened right now.
  Future<void> recordOpened(String path) async {
    final now = DateTime.now();
    state = state.map((e) {
      return e.path == path ? e.copyWith(lastOpenedAt: now) : e;
    }).toList();
    await _persist();
  }

  /// Re-checks file status for all entries.
  Future<void> refreshStatuses() async {
    final updated = await Future.wait(
      state.map((e) async {
        final status = await _fileChecker.checkFile(e.path);
        return e.copyWith(status: status);
      }),
    );
    state = updated;
    await _persist();
  }

  Future<void> _persist() => _persistence.saveEntries(state);
}

// ---------------------------------------------------------------------------
// Device files notifier — all PDFs found on device
// ---------------------------------------------------------------------------

/// Manages the list of all PDF files found on the device via storage scan.
///
/// Not persisted — re-scanned on each app start.
class DeviceFilesNotifier extends Notifier<List<LibraryEntry>> {
  late final FileChecker _fileChecker;
  late final PdfScanner _scanner;

  @override
  List<LibraryEntry> build() {
    _fileChecker = ref.read(fileServiceProvider);
    _scanner = ref.read(pdfScannerProvider);
    scan();
    return [];
  }

  Future<void> scan() async {
    try {
      final paths = await _scanner.scanForPdfs();
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
      state = entries;
    } catch (e, s) {
      developer.log(
        'device scan failed',
        name: 'pdf_app.device_files',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Collections notifier
// ---------------------------------------------------------------------------

class CollectionsNotifier extends Notifier<List<PdfCollection>> {
  late final CollectionsService _service;

  @override
  List<PdfCollection> build() {
    _service = ref.read(collectionsServiceProvider);
    _load();
    return [];
  }

  Future<void> _load() async {
    state = await _service.load();
  }

  Future<void> addCollection(String name) async {
    state = [...state, PdfCollection(id: uuid.v4(), name: name)];
    await _service.save(state);
  }

  Future<void> renameCollection(String id, String newName) async {
    state = state.map((c) {
      return c.id == id ? c.copyWith(name: newName) : c;
    }).toList();
    await _service.save(state);
  }

  Future<void> deleteCollection(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _service.save(state);
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
    NotifierProvider<LibraryNotifier, List<LibraryEntry>>(LibraryNotifier.new);

final deviceFilesProvider =
    NotifierProvider<DeviceFilesNotifier, List<LibraryEntry>>(
      DeviceFilesNotifier.new,
    );

final collectionsProvider =
    NotifierProvider<CollectionsNotifier, List<PdfCollection>>(
      CollectionsNotifier.new,
    );
