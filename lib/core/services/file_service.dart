import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/file_status.dart';

/// Abstract interface for checking file availability.
///
/// Allows the concrete [FileService] to be replaced with a fake in tests.
abstract class FileChecker {
  Future<FileStatus> checkFile(String path);
}

/// Checks the availability of PDF files.
///
/// Handles both bundled asset paths (e.g. `assets/sample.pdf`) and
/// absolute filesystem paths. Asset paths are verified via [rootBundle];
/// filesystem paths are verified via [File].
class FileService implements FileChecker {
  const FileService();

  /// Returns the [FileStatus] for the file at [path].
  ///
  /// Returns [FileStatus.missing] if the file does not exist,
  /// [FileStatus.corrupt] if it cannot be read, and [FileStatus.ok]
  /// otherwise. Never throws.
  @override
  Future<FileStatus> checkFile(String path) async {
    if (_isAssetPath(path)) {
      return _checkAsset(path);
    }
    return _checkFile(path);
  }

  /// Asset paths are relative (no leading `/`) and not absolute URIs.
  bool _isAssetPath(String path) =>
      !path.startsWith('/') && !path.contains('://');

  Future<FileStatus> _checkAsset(String path) async {
    try {
      await rootBundle.load(path);
      return FileStatus.ok;
    } catch (e, s) {
      developer.log(
        'checkAsset failed for "$path"',
        name: 'sefer.file_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      return FileStatus.missing;
    }
  }

  Future<FileStatus> _checkFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return FileStatus.missing;
      final raf = await file.open(mode: FileMode.read);
      await raf.close();
      return FileStatus.ok;
    } catch (e, s) {
      developer.log(
        'checkFile failed for "$path"',
        name: 'sefer.file_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      return FileStatus.corrupt;
    }
  }
}
