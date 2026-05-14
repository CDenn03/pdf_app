import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdf_app/core/models/collection.dart';

/// Persists user-defined collections.
class CollectionsService {
  static const _key = 'pdf_collections_v1';

  Future<List<PdfCollection>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PdfCollection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      developer.log(
        'collections load failed',
        name: 'pdf_app.collections',
        level: 900,
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  Future<void> save(List<PdfCollection> collections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(collections.map((c) => c.toJson()).toList()),
      );
    } catch (e, s) {
      developer.log(
        'collections save failed',
        name: 'pdf_app.collections',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }
  }
}
