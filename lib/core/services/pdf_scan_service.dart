import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Scans the device storage for PDF files.
abstract class PdfScanner {
  /// Returns absolute paths of all `.pdf` files found on the device.
  Future<List<String>> scanForPdfs();
}

/// Concrete implementation that walks common storage directories.
class PdfScanService implements PdfScanner {
  const PdfScanService();

  @override
  Future<List<String>> scanForPdfs() async {
    if (!await _requestPermission()) return [];

    final roots = await _storageRoots();
    final results = <String>[];

    for (final root in roots) {
      try {
        await _walk(root, results);
      } catch (e, s) {
        developer.log(
          'Error scanning $root',
          name: 'pdf_app.scan',
          level: 900,
          error: e,
          stackTrace: s,
        );
      }
    }

    return results;
  }

  /// Requests the appropriate storage permission for the current Android
  /// version. Returns true if granted.
  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ uses READ_MEDIA_IMAGES; below that READ_EXTERNAL_STORAGE.
    final sdkInt = await _androidSdkInt();
    final permission = sdkInt >= 33
        ? Permission.manageExternalStorage
        : Permission.storage;

    final status = await permission.request();
    return status.isGranted || status.isLimited;
  }

  Future<int> _androidSdkInt() async {
    try {
      // device_info_plus is not a dependency, so we read the build prop.
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Directory>> _storageRoots() async {
    final dirs = <Directory>[];

    try {
      final external = await getExternalStorageDirectories();
      if (external != null) {
        for (final dir in external) {
          // Walk up to the root of the storage volume (e.g. /storage/emulated/0).
          var current = dir;
          for (var i = 0; i < 4; i++) {
            final parent = current.parent;
            if (parent.path == current.path) break;
            current = parent;
          }
          dirs.add(current);
        }
      }
    } catch (e, s) {
      developer.log(
        'Could not get external storage',
        name: 'pdf_app.scan',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }

    // Always include internal storage root as fallback.
    dirs.add(Directory('/storage/emulated/0'));

    // Deduplicate by path.
    final seen = <String>{};
    return dirs.where((d) => seen.add(d.path)).toList();
  }

  Future<void> _walk(Directory dir, List<String> results) async {
    // Skip system/hidden directories that are unlikely to contain user PDFs.
    const skipDirs = {'Android', 'proc', 'sys', 'dev', 'acct', 'cache', 'data'};

    await for (final entity in dir.list(recursive: false)) {
      if (entity is File) {
        if (entity.path.toLowerCase().endsWith('.pdf')) {
          results.add(entity.path);
        }
      } else if (entity is Directory) {
        final name = entity.path.split('/').last;
        if (!name.startsWith('.') && !skipDirs.contains(name)) {
          await _walk(entity, results);
        }
      }
    }
  }
}
