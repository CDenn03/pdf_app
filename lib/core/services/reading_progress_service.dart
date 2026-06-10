import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Persists and retrieves per-document reading progress.
///
/// Stores the last-read page number keyed by PDF path so users resume
/// exactly where they left off across app restarts.
abstract class ReadingProgressStore {
  Future<int> getLastPage(String pdfId);
  Future<void> saveLastPage(String pdfId, int page);
}

/// [SharedPreferences]-backed implementation.
class ReadingProgressService implements ReadingProgressStore {
  static const _prefix = 'reading_progress_page_';

  @override
  Future<int> getLastPage(String pdfId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key(pdfId)) ?? 1;
    } catch (e, s) {
      developer.log(
        'getLastPage failed for $pdfId',
        name: 'sefer.progress',
        level: 900,
        error: e,
        stackTrace: s,
      );
      return 1;
    }
  }

  @override
  Future<void> saveLastPage(String pdfId, int page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(pdfId), page);
    } catch (e, s) {
      developer.log(
        'saveLastPage failed for $pdfId',
        name: 'sefer.progress',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }
  }

  // Use the sanitised path directly instead of hashCode. hashCode is not
  // stable across Dart versions and can collide, silently overwriting one
  // document's progress with another's (#2).
  String _key(String pdfId) {
    final safe = pdfId.replaceAll(RegExp(r'[^\w\-.]'), '_');
    return '$_prefix$safe';
  }
}
