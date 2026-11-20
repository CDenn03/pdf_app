import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/settings/presentation/settings_page.dart';

class _FakeSettingsStore implements AppSettingsStore {
  _FakeSettingsStore(this.settings);

  AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings next) async {
    settings = next;
  }
}

void main() {
  testWidgets('title is Settings and name row opens the editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = _FakeSettingsStore(const AppSettings(displayName: 'Ada'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsServiceProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: SettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Preferences'), findsNothing);
    expect(find.text('Ada'), findsOneWidget);

    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    expect(find.text('Your name'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Nia');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Nia'), findsOneWidget);
    expect(store.settings.displayName, 'Nia');
  });
}
