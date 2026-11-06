import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../models/file_status.dart';

/// Abstract interface for checking file availability.
///
/// Allows the concrete [FileService] to be replaced with a fake in tests.
abstract class FileChecker {
  Future<FileStatus> checkFile(String path);
}

/// Abstract interface for mutating files on disk.
///
/// Allows the concrete [FileService] to be replaced with a fake in tests.
abstract class FileMutator {
  /// Renames the file at [path] to [newName], in its own directory.
  /// Returns the resulting absolute path. Throws [FileOperationException].
  Future<String> rename(String path, String newName);

  /// Permanently deletes the file at [path]. Throws [FileOperationException].
  Future<void> delete(String path);
}

enum FileOperationReason {
  notFound,
  permissionDenied,
  nameTaken,
  invalidName,
  unsupportedPath,
  unknown,
}

class FileOperationException implements Exception {
  const FileOperationException(this.reason, this.message);

  final FileOperationReason reason;
  final String message;

  @override
  String toString() => 'FileOperationException($reason): $message';
}

/// Checks and mutates PDF files.
///
/// Handles both bundled asset paths (e.g. `assets/sample.pdf`) and
/// absolute filesystem paths. Asset paths are verified via [rootBundle];
/// filesystem paths are verified via [File]. Bundled assets are read-only
/// and cannot be renamed or deleted.
class FileService implements FileChecker, FileMutator {
  const FileService();

  static const String _pdfExtension = '.pdf';

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

  @override
  Future<String> rename(String path, String newName) async {
    if (_isAssetPath(path)) {
      throw const FileOperationException(
        FileOperationReason.unsupportedPath,
        'Bundled assets cannot be renamed.',
      );
    }
    final targetName = _validatedTargetName(newName);
    final source = File(path);
    if (!await source.exists()) {
      throw FileOperationException(
        FileOperationReason.notFound,
        'No file to rename at "$path".',
      );
    }
    final targetPath = p.join(p.dirname(path), targetName);
    if (await _pathExists(targetPath)) {
      throw FileOperationException(
        FileOperationReason.nameTaken,
        'A file named "$targetName" already exists.',
      );
    }
    try {
      final renamed = await source.rename(targetPath);
      return renamed.absolute.path;
    } on FileSystemException catch (e, s) {
      throw _mapFileSystemException('rename', path, e, s);
    }
  }

  @override
  Future<void> delete(String path) async {
    if (_isAssetPath(path)) {
      throw const FileOperationException(
        FileOperationReason.unsupportedPath,
        'Bundled assets cannot be deleted.',
      );
    }
    final file = File(path);
    if (!await file.exists()) {
      throw FileOperationException(
        FileOperationReason.notFound,
        'No file to delete at "$path".',
      );
    }
    try {
      await file.delete();
    } on FileSystemException catch (e, s) {
      throw _mapFileSystemException('delete', path, e, s);
    }
  }

  String _validatedTargetName(String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw const FileOperationException(
        FileOperationReason.invalidName,
        'A name is required.',
      );
    }
    if (trimmed.contains('/') || trimmed.contains(r'\')) {
      throw const FileOperationException(
        FileOperationReason.invalidName,
        'A name cannot contain path separators.',
      );
    }
    final stem = _stripPdfExtension(trimmed);
    if (stem.replaceAll('.', '').trim().isEmpty) {
      throw const FileOperationException(
        FileOperationReason.invalidName,
        'A name cannot be empty, only dots, or only an extension.',
      );
    }
    return _ensurePdfExtension(trimmed);
  }

  String _stripPdfExtension(String name) {
    if (name.toLowerCase().endsWith(_pdfExtension)) {
      return name.substring(0, name.length - _pdfExtension.length);
    }
    return name;
  }

  String _ensurePdfExtension(String name) {
    if (name.toLowerCase().endsWith(_pdfExtension)) return name;
    return '$name$_pdfExtension';
  }

  Future<bool> _pathExists(String path) async =>
      await File(path).exists() || await Directory(path).exists();

  FileOperationException _mapFileSystemException(
    String operation,
    String path,
    FileSystemException e,
    StackTrace s,
  ) {
    developer.log(
      '$operation failed for "$path"',
      name: 'sefer.file_service',
      level: 1000,
      error: e,
      stackTrace: s,
    );
    final reason = switch (e.osError?.errorCode) {
      1 || 13 => FileOperationReason.permissionDenied,
      2 => FileOperationReason.notFound,
      _ => FileOperationReason.unknown,
    };
    return FileOperationException(reason, e.message);
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
