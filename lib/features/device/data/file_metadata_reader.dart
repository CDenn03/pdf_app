import 'dart:io';

import 'package:flutter/foundation.dart';

@immutable
class FileMetadata {
  const FileMetadata({required this.modifiedAt, required this.sizeBytes});

  final DateTime modifiedAt;
  final int sizeBytes;
}

abstract class FileMetadataReader {
  /// Returns null when the file cannot be inspected.
  Future<FileMetadata?> read(String path);
}

class IoFileMetadataReader implements FileMetadataReader {
  const IoFileMetadataReader();

  @override
  Future<FileMetadata?> read(String path) async {
    try {
      final stat = await File(path).stat();
      if (stat.type == FileSystemEntityType.notFound) return null;
      return FileMetadata(modifiedAt: stat.modified, sizeBytes: stat.size);
    } on FileSystemException {
      return null;
    }
  }
}
