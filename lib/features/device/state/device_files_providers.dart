import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/core/services/pdf_scan_service.dart';
import 'package:sefer/core/utils/bounded_concurrency.dart';
import 'package:sefer/features/device/data/device_pdf_cache.dart';
import 'package:sefer/features/device/data/file_metadata_reader.dart';
import 'package:sefer/features/device/domain/device_pdf_entry.dart';
import 'package:sefer/features/device/domain/device_sort.dart';
import 'package:sefer/features/library/state/library_providers.dart';

const _scanConcurrency = 8;

class DeviceScanStatus {
  const DeviceScanStatus({this.isRefreshing = false});

  final bool isRefreshing;
}

class DeviceScanStatusNotifier extends Notifier<DeviceScanStatus> {
  @override
  DeviceScanStatus build() => const DeviceScanStatus();

  void setRefreshing(bool value) {
    state = DeviceScanStatus(isRefreshing: value);
  }
}

class DeviceFilesNotifier extends AsyncNotifier<List<DevicePdfEntry>> {
  late final DevicePdfCache _cache;
  late final FileChecker _fileChecker;
  late final PdfScanner _scanner;
  late final FileMetadataReader _metadataReader;
  Future<int>? _activeRefresh;
  bool _loadedFromCache = false;

  bool permissionDenied = false;

  @override
  Future<List<DevicePdfEntry>> build() async {
    _cache = ref.read(devicePdfCacheProvider);
    _fileChecker = ref.read(fileServiceProvider);
    _scanner = ref.read(pdfScannerProvider);
    _metadataReader = ref.read(fileMetadataReaderProvider);

    final cached = await _cache.load();
    if (cached != null) {
      _loadedFromCache = true;
      return cached;
    }
    return _initialScan();
  }

  Future<List<DevicePdfEntry>> _initialScan() async {
    final entries = await _discover();
    if (!permissionDenied) await _cache.save(entries);
    return entries;
  }

  Future<int> refreshCachedIndex() async {
    await future;
    if (!_loadedFromCache) return 0;
    return refresh();
  }

  Future<int> refresh() {
    final active = _activeRefresh;
    if (active != null) return active;
    final refresh = _refresh();
    _activeRefresh = refresh;
    return refresh.whenComplete(() => _activeRefresh = null);
  }

  Future<int> _refresh() async {
    var previous = state.value;
    if (previous == null) {
      await future;
      if (!_loadedFromCache) return 0;
      previous = state.value;
      if (previous == null) return 0;
    }

    ref.read(deviceScanStatusProvider.notifier).setRefreshing(true);
    try {
      final entries = await _discover();
      if (permissionDenied) return 0;
      final previousPaths = previous.map((entry) => entry.path).toSet();
      final addedCount = entries
          .where((entry) => !previousPaths.contains(entry.path))
          .length;
      state = AsyncData(entries);
      await _cache.save(entries);
      return addedCount;
    } catch (error, stackTrace) {
      developer.log(
        'Could not refresh device PDFs',
        name: 'sefer.scan',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
      return 0;
    } finally {
      ref.read(deviceScanStatusProvider.notifier).setRefreshing(false);
    }
  }

  Future<List<DevicePdfEntry>> _discover() async {
    final scanned = await _scanner.scanForPdfs();
    permissionDenied = scanned.isEmpty && !await _scanner.checkPermission();
    if (permissionDenied) return const [];
    final paths = {for (final path in scanned) p.normalize(path)}.toList();
    return mapWithConcurrency(paths, _scanConcurrency, _describe);
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

  void applyRename({required String oldPath, required String newPath}) {
    final current = state.value;
    if (current == null) return;
    final updated = [
      for (final entry in current)
        if (entry.path == oldPath)
          entry.renamedTo(path: newPath, name: p.basename(newPath))
        else
          entry,
    ];
    state = AsyncData(updated);
    unawaited(_cache.save(updated));
  }

  void removePath(String path) {
    final current = state.value;
    if (current == null) return;
    final updated = current.where((entry) => entry.path != path).toList();
    state = AsyncData(updated);
    unawaited(_cache.save(updated));
  }
}

class DeviceSortNotifier extends Notifier<DeviceSort> {
  @override
  DeviceSort build() => DeviceSort.defaultSort;

  void select(DeviceSort sort) => state = sort;
}

final devicePdfCacheProvider = Provider<DevicePdfCache>(
  (ref) => SharedPreferencesDevicePdfCache(),
);

final fileMetadataReaderProvider = Provider<FileMetadataReader>(
  (ref) => const IoFileMetadataReader(),
);

final deviceFilesProvider =
    AsyncNotifierProvider<DeviceFilesNotifier, List<DevicePdfEntry>>(
      DeviceFilesNotifier.new,
    );

final deviceScanStatusProvider =
    NotifierProvider<DeviceScanStatusNotifier, DeviceScanStatus>(
      DeviceScanStatusNotifier.new,
    );

final deviceSortProvider =
    NotifierProvider.autoDispose<DeviceSortNotifier, DeviceSort>(
      DeviceSortNotifier.new,
    );
