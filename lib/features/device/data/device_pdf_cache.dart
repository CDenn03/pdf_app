import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/features/device/domain/device_pdf_entry.dart';

abstract class DevicePdfCache {
  Future<List<DevicePdfEntry>?> load();
  Future<void> save(List<DevicePdfEntry> entries);
}

class SharedPreferencesDevicePdfCache implements DevicePdfCache {
  static const _key = 'device_pdf_index_v1';

  @override
  Future<List<DevicePdfEntry>?> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_key);
      if (encoded == null) return null;
      final values = jsonDecode(encoded) as List<dynamic>;
      return values
          .map((value) => _entryFromJson(value as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Could not load the device PDF index',
        name: 'sefer.device_cache',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> save(List<DevicePdfEntry> entries) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = jsonEncode(entries.map(_entryToJson).toList());
      await preferences.setString(_key, encoded);
    } catch (error, stackTrace) {
      developer.log(
        'Could not save the device PDF index',
        name: 'sefer.device_cache',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  DevicePdfEntry _entryFromJson(Map<String, dynamic> json) {
    final modifiedAt = json['modifiedAt'] as String?;
    return DevicePdfEntry(
      path: json['path'] as String,
      name: json['name'] as String,
      status: FileStatus.values.byName(json['status'] as String),
      modifiedAt: modifiedAt == null ? null : DateTime.tryParse(modifiedAt),
      sizeBytes: json['sizeBytes'] as int?,
    );
  }

  Map<String, dynamic> _entryToJson(DevicePdfEntry entry) => {
    'path': entry.path,
    'name': entry.name,
    'status': entry.status.name,
    if (entry.modifiedAt != null)
      'modifiedAt': entry.modifiedAt!.toIso8601String(),
    if (entry.sizeBytes != null) 'sizeBytes': entry.sizeBytes,
  };
}
