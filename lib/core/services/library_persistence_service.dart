import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:sefer/features/library/state/library_entry.dart';

/// Persists the library entry list across app restarts.
///
/// Stores entries as a JSON array in SharedPreferences. Only persists
/// fields that cannot be re-derived from the filesystem (id, name, path,
/// lastOpenedAt, collectionId). File status is always re-checked on load.
abstract class LibraryPersistence {
  Future<List<PersistedEntry>> loadEntries();
  Future<void> saveEntries(List<LibraryEntry> entries);
}

/// A lightweight DTO for what we persist — just the stable identity fields.
class PersistedEntry {
  final String id;
  final String name;
  final String path;
  final DateTime? lastOpenedAt;
  final String? collectionId;
  final bool isFavorite;

  const PersistedEntry({
    required this.id,
    required this.name,
    required this.path,
    this.lastOpenedAt,
    this.collectionId,
    this.isFavorite = false,
  });

  factory PersistedEntry.fromJson(Map<String, dynamic> json) => PersistedEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    path: json['path'] as String,
    lastOpenedAt: json['lastOpenedAt'] != null
        ? DateTime.tryParse(json['lastOpenedAt'] as String)
        : null,
    collectionId: json['collectionId'] as String?,
    isFavorite: json['isFavorite'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    if (lastOpenedAt != null) 'lastOpenedAt': lastOpenedAt!.toIso8601String(),
    if (collectionId != null) 'collectionId': collectionId,
    if (isFavorite) 'isFavorite': isFavorite,
  };
}

class LibraryPersistenceService implements LibraryPersistence {
  static const _entriesKey = 'library_entries_v1';
  // Rapid successive mutations (e.g. bulk add) are batched into one write (#19).
  static const _debounceDuration = Duration(milliseconds: 500);
  Timer? _debounce;

  @override
  Future<List<PersistedEntry>> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_entriesKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PersistedEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'loadEntries failed',
        name: 'sefer.library_persistence',
        level: 900,
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  @override
  Future<void> saveEntries(List<LibraryEntry> entries) async {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _write(entries));
  }

  Future<void> _write(List<LibraryEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = entries
          .map(
            (e) => PersistedEntry(
              id: e.id,
              name: e.name,
              path: e.path,
              lastOpenedAt: e.lastOpenedAt,
              collectionId: e.collectionId,
              isFavorite: e.isFavorite,
            ).toJson(),
          )
          .toList();
      await prefs.setString(_entriesKey, jsonEncode(list));
    } catch (e, s) {
      developer.log(
        'saveEntries failed',
        name: 'sefer.library_persistence',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }
  }
}
