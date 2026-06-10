import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/core/theme/scroll_direction.dart';

class AppSettings {
  final ReadingMode readingMode;
  final ScrollDirection scrollDirection;
  final ThemeMode themeMode;

  const AppSettings({
    this.readingMode = ReadingMode.light,
    this.scrollDirection = ScrollDirection.sideBySide,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    ReadingMode? readingMode,
    ScrollDirection? scrollDirection,
    ThemeMode? themeMode,
  }) => AppSettings(
    readingMode: readingMode ?? this.readingMode,
    scrollDirection: scrollDirection ?? this.scrollDirection,
    themeMode: themeMode ?? this.themeMode,
  );

  // == and hashCode are required so that Riverpod can detect when a copyWith
  // produces an identical value and skip downstream rebuilds (#5).
  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.readingMode == readingMode &&
      other.scrollDirection == scrollDirection &&
      other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(readingMode, scrollDirection, themeMode);
}

abstract class AppSettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class AppSettingsService implements AppSettingsStore {
  static const _keyReadingMode = 'app_reading_mode';
  static const _keyScrollDirection = 'app_scroll_direction';
  static const _keyThemeMode = 'app_theme_mode';

  @override
  Future<AppSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeName = prefs.getString(_keyReadingMode);
      final dirName = prefs.getString(_keyScrollDirection);
      final themeName = prefs.getString(_keyThemeMode);
      return AppSettings(
        readingMode: ReadingMode.values.firstWhere(
          (m) => m.name == modeName,
          orElse: () => ReadingMode.light,
        ),
        scrollDirection: ScrollDirection.values.firstWhere(
          (d) => d.name == dirName,
          orElse: () => ScrollDirection.sideBySide,
        ),
        themeMode: ThemeMode.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => ThemeMode.system,
        ),
      );
    } catch (e, s) {
      developer.log(
        'Failed to load app settings',
        name: 'sefer.settings',
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
      await prefs.setString(_keyThemeMode, settings.themeMode.name);
    } catch (e, s) {
      developer.log(
        'Failed to save app settings',
        name: 'sefer.settings',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }
  }
}
