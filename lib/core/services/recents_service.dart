import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight record of a recently opened PDF.
class RecentEntry {
  final String path;
  final String name;
  final DateTime openedAt;

  const RecentEntry({
    required this.path,
    required this.name,
    required this.openedAt,
  });

  factory RecentEntry.fromJson(Map<String, dynamic> json) => RecentEntry(
    path: json['path'] as String,
    name: json['name'] as String,
    openedAt: DateTime.parse(json['openedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'openedAt': openedAt.toIso8601String(),
  };
}

/// Persists the list of recently opened PDFs (any file, library or not).
///
/// Abstract so the notifier depends on the interface rather than the
/// concrete class, making fakes trivial to inject in tests (#18).
abstract class RecentsStore {
  Future<List<RecentEntry>> load();
  Future<void> recordOpened(String path, String name);
}

/// [SharedPreferences]-backed implementation of [RecentsStore].
class RecentsService implements RecentsStore {
  static const _key = 'recents_all_v1';
  static const _maxEntries = 50;

  @override
  Future<List<RecentEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RecentEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'recents load failed',
        name: 'sefer.recents',
        level: 900,
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  @override
  Future<void> recordOpened(String path, String name) async {
    try {
      final entries = await load();
      // Remove any existing entry for this path, then prepend.
      final updated = [
        RecentEntry(path: path, name: name, openedAt: DateTime.now()),
        ...entries.where((e) => e.path != path),
      ].take(_maxEntries).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(updated.map((e) => e.toJson()).toList()),
      );
    } catch (e, s) {
      developer.log(
        'recents save failed',
        name: 'sefer.recents',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }
  }
}
