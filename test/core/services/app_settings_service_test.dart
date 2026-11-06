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
}
