import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/features/home/presentation/splash_screen.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/main.dart';

import 'support/library_fakes.dart';

class _FakeSettingsStore implements AppSettingsStore {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

void main() {
  testWidgets('keeps Home built behind splash until startup is ready', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);
    final readiness = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startupReadinessProvider.overrideWith((ref) => readiness.future),
          appSettingsServiceProvider.overrideWithValue(_FakeSettingsStore()),
          fileServiceProvider.overrideWithValue(FakeFileChecker()),
          libraryPersistenceProvider.overrideWithValue(
            FakeLibraryPersistence(),
          ),
          collectionsServiceProvider.overrideWithValue(
            FakeCollectionsService(),
          ),
          recentsStoreProvider.overrideWithValue(FakeRecentsStore(const [])),
        ],
        child: const SeferApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Library'), findsWidgets);

    readiness.complete();
    await tester.pump(const Duration(milliseconds: 725));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 275));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Library'), findsWidgets);
  });
}
