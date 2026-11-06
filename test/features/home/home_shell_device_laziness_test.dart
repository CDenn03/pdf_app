import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/services/pdf_scan_service.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/device/state/device_files_providers.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

import '../../support/library_fakes.dart';

class _CountingScanner implements PdfScanner {
  var scanCount = 0;

  @override
  Future<List<String>> scanForPdfs() async {
    scanCount++;
    return const [];
  }

  @override
  Future<bool> checkPermission() async => true;
}

class _FakeSettingsStore implements AppSettingsStore {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

void main() {
  testWidgets('Device scan starts once on first visit and stays mounted', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);
    final scanner = _CountingScanner();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsServiceProvider.overrideWithValue(_FakeSettingsStore()),
          fileServiceProvider.overrideWithValue(FakeFileChecker()),
          libraryPersistenceProvider.overrideWithValue(
            FakeLibraryPersistence(),
          ),
          collectionsServiceProvider.overrideWithValue(
            FakeCollectionsService(),
          ),
          recentsStoreProvider.overrideWithValue(FakeRecentsStore(const [])),
          pdfScannerProvider.overrideWithValue(scanner),
          fileMetadataReaderProvider.overrideWithValue(
            FakeMetadataReader(const {}),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(scanner.scanCount, 0);

    await tester.tap(find.text('Device'));
    await tester.pumpAndSettle();
    expect(scanner.scanCount, 1);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device'));
    await tester.pumpAndSettle();

    expect(scanner.scanCount, 1);
  });
}
