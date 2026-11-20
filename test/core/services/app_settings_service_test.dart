import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/theme/reader_layout_mode.dart';

const _layoutKey = 'app_scroll_direction';

Future<AppSettings> _loadWith(Map<String, Object> stored) {
  SharedPreferences.setMockInitialValues(stored);
  return AppSettingsService().load();
}

void main() {
  test('defaults to paged when nothing is stored', () async {
    final settings = await _loadWith({});
    expect(settings.layoutMode, ReaderLayoutMode.paged);
  });

  test('migrates a stored sideBySide value to paged', () async {
    final settings = await _loadWith({_layoutKey: 'sideBySide'});
    expect(settings.layoutMode, ReaderLayoutMode.paged);
  });

  test('keeps a stored continuous value', () async {
    final settings = await _loadWith({_layoutKey: 'continuous'});
    expect(settings.layoutMode, ReaderLayoutMode.continuous);
  });

  test('falls back to paged for an unknown stored value', () async {
    final settings = await _loadWith({_layoutKey: 'garbage'});
    expect(settings.layoutMode, ReaderLayoutMode.paged);
  });

  test('saved layout mode is stored as its token and reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AppSettingsService();
    await service.save(
      const AppSettings(layoutMode: ReaderLayoutMode.bookFlip),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_layoutKey), 'bookFlip');
    expect((await service.load()).layoutMode, ReaderLayoutMode.bookFlip);
  });

  test('defaults display name to Reader when nothing is stored', () async {
    final settings = await _loadWith({});
    expect(settings.displayName, AppSettings.defaultDisplayName);
  });

  test('falls back to Reader for a blank stored name', () async {
    final settings = await _loadWith({'app_display_name': '   '});
    expect(settings.displayName, AppSettings.defaultDisplayName);
  });

  test('saved display name reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AppSettingsService();
    await service.save(const AppSettings(displayName: 'Ada'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_display_name'), 'Ada');
    expect((await service.load()).displayName, 'Ada');
  });
}
