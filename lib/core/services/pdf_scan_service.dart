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

  /// Requests storage permission. Returns true if we have enough access to
  /// proceed (granted, limited, or restricted — we still attempt the scan).
  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

    // REQUEST_EXTERNAL_STORAGE works on all Android versions; on 13+ it may
    // be auto-granted for read-only access to shared storage.
    final status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) return true;

    // On Android 11+ (API 30+) the storage permission may be permanently
    // denied but the external storage is still readable for common dirs.
    // Proceed anyway — the walk will simply skip unreadable dirs.
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

  Future<void> _walk(Directory dir, List<String> results) async {
    const skipDirs = {'proc', 'sys', 'dev', 'acct', 'cache', 'data'};
    const knownAppDirs = {
      'WhatsApp',
      'WhatsApp Documents',
      'Telegram',
      'Telegram Documents',
    };

    try {
      await for (final entity in dir.list(recursive: false)) {
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
            await _walk(entity, results);
          }
        }
      }
    } catch (_) {
      // Permission denied or other I/O error — skip this directory silently.
    }
  }
}
