import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/home/presentation/page_headers.dart';

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
  testWidgets('shows salutation and stored display name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(
            _FakeSettingsStore(const AppSettings(displayName: 'Ada')),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: GreetingHeader(now: DateTime(2026, 1, 1, 9))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.byTooltip('Change name'), findsWidgets);
  });

  testWidgets('edit icon opens the name dialog and saves', (tester) async {
    final store = _FakeSettingsStore(const AppSettings(displayName: 'Ada'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsServiceProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: GreetingHeader(now: DateTime(2026, 1, 1, 9))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Your name'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Nia');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Nia'), findsOneWidget);
    expect(store.settings.displayName, 'Nia');
  });
}
