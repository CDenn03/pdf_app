import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/services/collections_service.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/core/services/pdf_scan_service.dart';
import 'package:sefer/core/services/recents_service.dart';
import 'package:sefer/features/device/data/file_metadata_reader.dart';
import 'package:sefer/features/library/state/library_entry.dart';

class FakeFileChecker implements FileChecker {
  @override
  Future<FileStatus> checkFile(String path) async => FileStatus.ok;
}

class FakeLibraryPersistence implements LibraryPersistence {
  FakeLibraryPersistence({
    List<PersistedEntry> initial = const [],
    this.loadGate,
  }) : _initial = initial;

  final List<PersistedEntry> _initial;
  final Future<void>? loadGate;
  final saves = <List<LibraryEntry>>[];

  @override
  Future<List<PersistedEntry>> loadEntries() async {
    await loadGate;
    return _initial;
  }

  @override
  Future<void> saveEntries(List<LibraryEntry> entries) async {
    saves.add(entries);
  }
}

class FakeCollectionsService extends CollectionsService {
  @override
  Future<List<PdfCollection>> load() async => const [];

  @override
  Future<void> save(List<PdfCollection> collections) async {}
}

class FakePdfScanner implements PdfScanner {
  FakePdfScanner(this.paths);

  final List<String> paths;

  @override
  Future<List<String>> scanForPdfs() async => paths;

  @override
  Future<bool> checkPermission() async => true;
}

class FakeMetadataReader implements FileMetadataReader {
  FakeMetadataReader(this.results);

  final Map<String, FileMetadata?> results;
  var inFlight = 0;
  var maxInFlight = 0;
  final reads = <String>[];

  @override
  Future<FileMetadata?> read(String path) async {
    reads.add(path);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    await Future<void>.delayed(Duration.zero);
    inFlight--;
    return results[path];
  }
}

class FakeRecentsStore implements RecentsStore {
  FakeRecentsStore(List<RecentEntry> entries) : _entries = [...entries];

  final List<RecentEntry> _entries;

  @override
  Future<List<RecentEntry>> load() async => List.unmodifiable(_entries);

  @override
  Future<void> recordOpened(String path, String name) async {}

  @override
  Future<void> moveEntry({
    required String oldPath,
    required String newPath,
    required String newName,
  }) async {}

  @override
  Future<void> remove(String path) async {
    _entries.removeWhere((e) => e.path == path);
  }
}
