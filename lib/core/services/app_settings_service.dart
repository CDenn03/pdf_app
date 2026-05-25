import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/core/theme/scroll_direction.dart';

class AppSettings {
  final ReadingMode readingMode;
  final ScrollDirection scrollDirection;

  const AppSettings({
    this.readingMode = ReadingMode.light,
    this.scrollDirection = ScrollDirection.paginated,
  });

  AppSettings copyWith({ReadingMode? readingMode, ScrollDirection? scrollDirection}) {
    return AppSettings(
      readingMode: readingMode ?? this.readingMode,
      scrollDirection: scrollDirection ?? this.scrollDirection,
    );
  }
}

abstract class AppSettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class AppSettingsService implements AppSettingsStore {
  static const _keyReadingMode = 'app_reading_mode';
  static const _keyScrollDirection = 'app_scroll_direction';

  @override
  Future<AppSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeName = prefs.getString(_keyReadingMode);
      final dirName = prefs.getString(_keyScrollDirection);
      return AppSettings(
        readingMode: ReadingMode.values.firstWhere(
          (m) => m.name == modeName,
          orElse: () => ReadingMode.light,
        ),
        scrollDirection: ScrollDirection.values.firstWhere(
          (d) => d.name == dirName,
          orElse: () => ScrollDirection.paginated,
        ),
      );
    } catch (e, s) {
      developer.log(
        'Failed to load app settings',
        name: 'pdf_app.settings',
        level: 900,
        error: e,
        stackTrace: s,
      );
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyReadingMode, settings.readingMode.name);
      await prefs.setString(_keyScrollDirection, settings.scrollDirection.name);
    } catch (e, s) {
      developer.log(
        'Failed to save app settings',
        name: 'pdf_app.settings',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }
  }
}
