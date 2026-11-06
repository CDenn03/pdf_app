import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/core/services/pdf_scan_service.dart';
import 'package:sefer/core/utils/bounded_concurrency.dart';
import 'package:sefer/features/device/data/file_metadata_reader.dart';
import 'package:sefer/features/device/domain/device_pdf_entry.dart';
import 'package:sefer/features/device/domain/device_sort.dart';
import 'package:sefer/features/library/state/library_providers.dart';

const _scanConcurrency = 8;

/// Manages the list of all PDF files found on the device via storage scan.
///
/// Not persisted; re-scanned on each app start.
class DeviceFilesNotifier extends AsyncNotifier<List<DevicePdfEntry>> {
  late final FileChecker _fileChecker;
  late final PdfScanner _scanner;
  late final FileMetadataReader _metadataReader;

  /// True when the last scan was blocked by a denied storage permission.
  bool permissionDenied = false;

  @override
  Future<List<DevicePdfEntry>> build() async {
    _fileChecker = ref.read(fileServiceProvider);
    _scanner = ref.read(pdfScannerProvider);
    _metadataReader = ref.read(fileMetadataReaderProvider);
    return scan();
  }

  Future<List<DevicePdfEntry>> scan() async {
    state = const AsyncLoading();
    final scanned = await _scanner.scanForPdfs();
    permissionDenied = scanned.isEmpty && !await _scanner.checkPermission();
    final paths = {for (final path in scanned) p.normalize(path)}.toList();
    final entries = await mapWithConcurrency(
      paths,
      _scanConcurrency,
      _describe,
    );
    state = AsyncData(entries);
    return entries;
  }

  Future<DevicePdfEntry> _describe(String path) async {
    final status = await _fileChecker.checkFile(path);
    final metadata = await _metadataReader.read(path);
    return DevicePdfEntry(
      path: path,
      name: p.basename(path),
      status: status,
      modifiedAt: metadata?.modifiedAt,
      sizeBytes: metadata?.sizeBytes,
    );
  }

  /// Repoints the scanned entry at [oldPath] to [newPath] in place.
  ///
  /// A full [scan] would also be correct, but the walk is capped at 5000
  /// files and is the slowest thing on this tab.
  void applyRename({required String oldPath, required String newPath}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final e in current)
        if (e.path == oldPath)
          e.renamedTo(path: newPath, name: p.basename(newPath))
        else
          e,
    ]);
  }

  void removePath(String path) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((e) => e.path != path).toList());
  }
}

class DeviceSortNotifier extends Notifier<DeviceSort> {
  @override
  DeviceSort build() => DeviceSort.defaultSort;

  void select(DeviceSort sort) => state = sort;
}

final fileMetadataReaderProvider = Provider<FileMetadataReader>(
  (ref) => const IoFileMetadataReader(),
);

final deviceFilesProvider =
    AsyncNotifierProvider<DeviceFilesNotifier, List<DevicePdfEntry>>(
      DeviceFilesNotifier.new,
    );

final deviceSortProvider =
    NotifierProvider.autoDispose<DeviceSortNotifier, DeviceSort>(
      DeviceSortNotifier.new,
    );
