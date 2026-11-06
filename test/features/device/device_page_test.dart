import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/device/data/file_metadata_reader.dart';
import 'package:sefer/features/device/presentation/device_page.dart';
import 'package:sefer/features/device/state/device_files_providers.dart';
import 'package:sefer/features/library/state/library_providers.dart';

import '../../support/library_fakes.dart';

const _paths = ['/d/alpha.pdf', '/d/beta.pdf', '/d/gamma.pdf'];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  FakeLibraryPersistence? persistence,
  String? targetCollectionId,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      fileServiceProvider.overrideWithValue(FakeFileChecker()),
      pdfScannerProvider.overrideWithValue(FakePdfScanner(_paths)),
      fileMetadataReaderProvider.overrideWithValue(
        FakeMetadataReader({
          for (final path in _paths)
            path: FileMetadata(modifiedAt: DateTime(2024), sizeBytes: 2048),
        }),
      ),
      libraryPersistenceProvider.overrideWithValue(
        persistence ?? FakeLibraryPersistence(),
      ),
      collectionsServiceProvider.overrideWithValue(FakeCollectionsService()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DevicePage(targetCollectionId: targetCollectionId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('long press selects without opening the action sheet', (
    tester,
  ) async {
    await _pump(tester);

    await tester.longPress(find.text('beta.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Mark favorite'), findsOneWidget);
    expect(find.text('Add to collection'), findsOneWidget);
    expect(find.text('Delete file'), findsNothing);
  });

  testWidgets('overflow button still opens the per-file action sheet', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byTooltip('File actions for beta.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete file'), findsOneWidget);
  });

  testWidgets('tap toggles while selecting and cancel clears', (tester) async {
    await _pump(tester);
    await tester.longPress(find.text('alpha.pdf'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('beta.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('selected'), findsNothing);
  });

  testWidgets('select all applies to filtered rows only', (tester) async {
    await _pump(tester);
    await tester.longPress(find.text('alpha.pdf'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('selected'), findsNothing);
  });

  testWidgets('mark favorite creates library entries and clears', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.longPress(find.text('alpha.pdf'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark favorite'));
    await tester.pumpAndSettle();

    expect(container.read(favoritePathsProvider), {'/d/alpha.pdf'});
    expect(find.textContaining('selected'), findsNothing);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('selection is pruned when a selected file is deleted', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.longPress(find.text('alpha.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('beta.pdf'));
    await tester.pumpAndSettle();

    container.read(deviceFilesProvider.notifier).removePath('/d/alpha.pdf');
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('sort menu reorders rows', (tester) async {
    await _pump(tester);

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name: Z-A'));
    await tester.pumpAndSettle();

    final gamma = tester.getTopLeft(find.text('gamma.pdf')).dy;
    final alpha = tester.getTopLeft(find.text('alpha.pdf')).dy;
    expect(gamma, lessThan(alpha));
  });

  testWidgets('add-to-collection mode shows the add bar, not favorites', (
    tester,
  ) async {
    await _pump(tester, targetCollectionId: 'c1');

    await tester.tap(find.text('alpha.pdf'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Add 1 to'), findsOneWidget);
    expect(find.text('Mark favorite'), findsNothing);
  });
}
