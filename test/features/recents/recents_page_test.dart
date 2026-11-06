import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/presentation/recents_page.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

import '../../support/library_fakes.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String? initialSelectedPath,
}) async {
  final now = DateTime.now();
  final container = ProviderContainer(
    overrides: [
      fileServiceProvider.overrideWithValue(FakeFileChecker()),
      libraryPersistenceProvider.overrideWithValue(FakeLibraryPersistence()),
      recentsStoreProvider.overrideWithValue(
        FakeRecentsStore([
          RecentEntry(path: '/r/one.pdf', name: 'one.pdf', openedAt: now),
          RecentEntry(path: '/r/two.pdf', name: 'two.pdf', openedAt: now),
        ]),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: RecentsPage(initialSelectedPath: initialSelectedPath),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('long press enters selection and tap toggles', (tester) async {
    await _pump(tester);

    await tester.longPress(find.text('one'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('initialSelectedPath opens with that item selected', (
    tester,
  ) async {
    await _pump(tester, initialSelectedPath: '/r/two.pdf');

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Mark favorite'), findsOneWidget);
  });

  testWidgets('select all then mark favorite favorites every recent', (
    tester,
  ) async {
    final container = await _pump(tester, initialSelectedPath: '/r/one.pdf');

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark favorite'));
    await tester.pumpAndSettle();

    expect(container.read(favoritePathsProvider), {'/r/one.pdf', '/r/two.pdf'});
    expect(find.textContaining('selected'), findsNothing);
  });

  testWidgets('normal overflow still offers Open, Share and Rename', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byTooltip('File actions for one.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Rename'), findsOneWidget);
  });

  testWidgets('cancel leaves selection mode', (tester) async {
    await _pump(tester, initialSelectedPath: '/r/one.pdf');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Recently opened'), findsOneWidget);
  });
}
