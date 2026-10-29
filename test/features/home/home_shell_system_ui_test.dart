import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/services/collections_service.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/core/services/pdf_scan_service.dart';
import 'package:sefer/core/services/recents_service.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/core/theme/system_ui.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

class _FakeFileChecker implements FileChecker {
  @override
  Future<FileStatus> checkFile(String path) async => FileStatus.ok;
}

class _EmptyPersistence implements LibraryPersistence {
  @override
  Future<List<PersistedEntry>> loadEntries() async => const [];

  @override
  Future<void> saveEntries(List<LibraryEntry> entries) async {}
}

class _EmptyCollections extends CollectionsService {
  @override
  Future<List<PdfCollection>> load() async => const [];

  @override
  Future<void> save(List<PdfCollection> collections) async {}
}

class _EmptyScanner implements PdfScanner {
  @override
  Future<List<String>> scanForPdfs() async => const [];

  @override
  Future<bool> checkPermission() async => true;
}

class _EmptyRecents implements RecentsStore {
  @override
  Future<List<RecentEntry>> load() async => const [];

  @override
  Future<void> recordOpened(String path, String name) async {}
}

class _FakeSettings implements AppSettingsStore {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

const double _statusInset = 48;
const double _navInset = 24;

Widget _shellHost({required Brightness brightness}) {
  return ProviderScope(
    overrides: [
      fileServiceProvider.overrideWithValue(_FakeFileChecker()),
      libraryPersistenceProvider.overrideWithValue(_EmptyPersistence()),
      collectionsServiceProvider.overrideWithValue(_EmptyCollections()),
      pdfScannerProvider.overrideWithValue(_EmptyScanner()),
      recentsStoreProvider.overrideWithValue(_EmptyRecents()),
      appSettingsServiceProvider.overrideWithValue(_FakeSettings()),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: const HomeShell(),
    ),
  );
}

void _usePhoneViewWithInsets(WidgetTester tester) {
  const dpr = 3.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = const Size(360 * dpr, 780 * dpr);
  tester.view.padding = const FakeViewPadding(
    top: _statusInset * dpr,
    bottom: _navInset * dpr,
  );
  addTearDown(tester.view.reset);
}

SystemUiOverlayStyle _resolvedOverlayStyle(WidgetTester tester) {
  final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
    find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
  );
  return region.value;
}

void main() {
  group('HomeShell status bar overlay style', () {
    testWidgets('dark theme asks for light status bar icons', (tester) async {
      _usePhoneViewWithInsets(tester);
      await tester.pumpWidget(_shellHost(brightness: Brightness.dark));
      await tester.pump();

      expect(_resolvedOverlayStyle(tester), AppSystemUi.lightIcons);
    });

    testWidgets('light theme asks for dark status bar icons', (tester) async {
      _usePhoneViewWithInsets(tester);
      await tester.pumpWidget(_shellHost(brightness: Brightness.light));
      await tester.pump();

      expect(_resolvedOverlayStyle(tester), AppSystemUi.darkIcons);
    });
  });

  group('HomeShell safe area', () {
    testWidgets('shell content is inset below the status bar', (tester) async {
      _usePhoneViewWithInsets(tester);
      await tester.pumpWidget(_shellHost(brightness: Brightness.dark));
      await tester.pump();

      final contentTop = tester.getRect(find.byType(IndexedStack)).top;
      expect(contentTop, greaterThanOrEqualTo(_statusInset));
    });

    testWidgets('floating nav bar clears the bottom inset', (tester) async {
      _usePhoneViewWithInsets(tester);
      await tester.pumpWidget(_shellHost(brightness: Brightness.dark));
      await tester.pump();

      final screenHeight = tester.getSize(find.byType(HomeShell)).height;
      final navBottom = tester
          .getRect(
            find
                .descendant(
                  of: find.byType(HomeShell),
                  matching: find.byType(Row),
                )
                .first,
          )
          .bottom;
      expect(screenHeight - navBottom, greaterThanOrEqualTo(_navInset));
    });
  });
}
