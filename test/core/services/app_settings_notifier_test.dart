import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pdf_app/core/providers.dart';
import 'package:pdf_app/core/services/app_settings_service.dart';
import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/core/theme/scroll_direction.dart';

class _MockStore extends Mock implements AppSettingsStore {}

void main() {
  late _MockStore store;

  setUpAll(() => registerFallbackValue(const AppSettings()));

  setUp(() {
    store = _MockStore();
    when(() => store.load()).thenAnswer((_) async => const AppSettings());
    when(() => store.save(any())).thenAnswer((_) async {});
  });

  ProviderContainer container0() => ProviderContainer(
    overrides: [appSettingsServiceProvider.overrideWithValue(store)],
  );

  test('loads defaults on first build', () async {
    final container = container0();
    addTearDown(container.dispose);
    await container.read(appSettingsProvider.notifier).ready;

    expect(container.read(appSettingsProvider).themeMode, ThemeMode.system);
  });

  test('setReadingMode updates state and persists', () async {
    final container = container0();
    addTearDown(container.dispose);
    await container.read(appSettingsProvider.notifier).ready;

    await container
        .read(appSettingsProvider.notifier)
        .setReadingMode(ReadingMode.dark);

    expect(
      container.read(appSettingsProvider).readingMode,
      ReadingMode.dark,
    );
    verify(() => store.save(any())).called(1);
  });

  test('setThemeMode round-trips through save/load', () async {
    const saved = AppSettings(themeMode: ThemeMode.dark);
    when(() => store.load()).thenAnswer((_) async => saved);

    final container = container0();
    addTearDown(container.dispose);
    await container.read(appSettingsProvider.notifier).ready;

    expect(container.read(appSettingsProvider).themeMode, ThemeMode.dark);
  });

  test('setScrollDirection persists', () async {
    final container = container0();
    addTearDown(container.dispose);

    await container
        .read(appSettingsProvider.notifier)
        .setScrollDirection(ScrollDirection.continuous);

    verify(() => store.save(any())).called(1);
  });
}
