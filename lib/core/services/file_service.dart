import 'dart:developer' as developer;
import 'dart:io';

import '../models/file_status.dart';

/// Abstract interface for checking file availability.
///
/// Allows the concrete [FileService] to be replaced with a fake in tests.
abstract class FileChecker {
  Future<FileStatus> checkFile(String path);
}

/// Checks the on-disk availability of PDF files.
class FileService implements FileChecker {
  const FileService();

  /// Returns the [FileStatus] for the file at [path].
  ///
  /// Returns [FileStatus.missing] if the file does not exist,
  /// [FileStatus.corrupt] if it cannot be opened, and [FileStatus.ok]
  /// otherwise. Never throws.
  @override
  Future<FileStatus> checkFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return FileStatus.missing;
      final raf = await file.open(mode: FileMode.read);
      await raf.close();
      return FileStatus.ok;
    } catch (e, s) {
      developer.log(
        'checkFile failed for "$path"',
        name: 'pdf_app.file_service',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      return FileStatus.corrupt;
    }
  }
}
