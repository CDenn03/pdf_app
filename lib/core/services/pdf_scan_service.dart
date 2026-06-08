import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
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

  /// Requests storage permission. Returns true if we have enough access to
  /// proceed.
  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

    // MANAGE_EXTERNAL_STORAGE is a restricted permission that triggers Play
    // Store policy violations. Use READ_EXTERNAL_STORAGE (API < 33) or the
    // granular READ_MEDIA_* permissions (API 33+) instead (#15).
    //
    // We check the Android version via the presence of READ_MEDIA_IMAGES
    // permission: if requesting it returns a non-denied status the device is
    // running API 33+.
    final mediaStatus = await Permission.photos.status;
    if (mediaStatus.isDenied) {
      // API 33+ — request granular media permissions.
      await Permission.photos.request();
    }

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isDenied) {
      // API < 33 fallback.
      await Permission.storage.request();
    }

    // Proceed regardless — the walk skips unreadable dirs.
    return true;
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
