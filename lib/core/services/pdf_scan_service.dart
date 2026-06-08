import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Scans the device storage for PDF files.
abstract class PdfScanner {
  /// Returns absolute paths of all `.pdf` files found on the device.
  Future<List<String>> scanForPdfs();

  /// Returns true if storage permission is currently granted.
  Future<bool> checkPermission();
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

  @override
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    return Permission.photos.isGranted;
  }

  /// Requests storage permission. Returns true if access was granted,
  /// false if denied (caller should show a prompt).
  ///
  /// Uses MANAGE_EXTERNAL_STORAGE (API 30+) for full file access, falling
  /// back to READ_EXTERNAL_STORAGE / READ_MEDIA_IMAGES on older versions.
  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

    // MANAGE_EXTERNAL_STORAGE is in the manifest for API 30+ and gives the
    // broadest access. permission_handler opens the "Allow all files" screen.
    final manageStatus = await Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) return true;
    if (!manageStatus.isPermanentlyDenied) {
      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) return true;
    }

    // Fallback: READ_EXTERNAL_STORAGE (API ≤ 29) or READ_MEDIA_IMAGES (API 33+).
    final storageResult = await Permission.storage.request();
    if (storageResult.isGranted) return true;

    final photosResult = await Permission.photos.request();
    if (photosResult.isGranted) return true;

    // Permanently denied — send user to Settings.
    await openAppSettings();
    return false;
  }

  Future<List<Directory>> _storageRoots() async {
    final dirs = <Directory>[];

    try {
      final external = await getExternalStorageDirectories();
      if (external != null) {
        for (final dir in external) {
          // Walk up to the root of the storage volume.
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

    // Always include the primary shared storage root.
    dirs.add(Directory('/storage/emulated/0'));

    // Add well-known subdirectories explicitly so they're always scanned
    // even if the recursive walk is blocked by permissions.
    const knownPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Books',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
    ];
    for (final path in knownPaths) {
      final d = Directory(path);
      if (await d.exists()) dirs.add(d);
    }

    // Deduplicate by path.
    final seen = <String>{};
    return dirs.where((d) => seen.add(d.path)).toList();
  }

  /// Public entry-point for tests — bypasses permission checks.
  @visibleForTesting
  Future<List<String>> walkDirectory(Directory root) async {
    final results = <String>[];
    await _walk(root, results);
    return results;
  }

  Future<void> _walk(
    Directory dir,
    List<String> results, {
    int depth = 0,
  }) async {
    // Guard against infinite recursion on deeply nested or circular filesystems
    // and cap results to avoid runaway scans on large storage (#9).
    if (depth > 8 || results.length > 5000) return;
    const skipDirs = {'proc', 'sys', 'dev', 'acct', 'cache', 'data'};
    const knownAppDirs = {
      'WhatsApp',
      'WhatsApp Documents',
      'Telegram',
      'Telegram Documents',
    };

    try {
      await for (final entity in dir.list(recursive: false)) {
        if (results.length > 5000) return;
        if (entity is File) {
          if (entity.path.toLowerCase().endsWith('.pdf')) {
            results.add(entity.path);
          }
        } else if (entity is Directory) {
          final name = entity.path.split('/').last;
          final isHidden = name.startsWith('.');
          final isSkipped = skipDirs.contains(name);
          final isKnownApp = knownAppDirs.contains(name);
          if (!isSkipped && (!isHidden || isKnownApp)) {
            await _walk(entity, results, depth: depth + 1);
          }
        }
      }
    } catch (_) {
      // Permission denied or other I/O error — skip this directory silently.
    }
  }
}
