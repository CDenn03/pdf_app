import 'package:flutter/foundation.dart';

import 'package:sefer/core/models/file_status.dart';

@immutable
class DevicePdfEntry {
  const DevicePdfEntry({
    required this.path,
    required this.name,
    required this.status,
    this.modifiedAt,
    this.sizeBytes,
  });

  final String path;
  final String name;
  final FileStatus status;
  final DateTime? modifiedAt;
  final int? sizeBytes;

  DevicePdfEntry renamedTo({required String path, required String name}) {
    return DevicePdfEntry(
      path: path,
      name: name,
      status: status,
      modifiedAt: modifiedAt,
      sizeBytes: sizeBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DevicePdfEntry &&
      other.path == path &&
      other.name == name &&
      other.status == status &&
      other.modifiedAt == modifiedAt &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(path, name, status, modifiedAt, sizeBytes);
}
